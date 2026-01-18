-- filters/structure.lua
local utils = require 'pandoc.utils'

local function render_html(blocks)
  return pandoc.write(pandoc.Pandoc(blocks), 'html')
end

-- Define a custom utf8.sub function
function utf8.sub(s, i, j)
    -- Get the byte offset for the starting character index
    local start_byte = utf8.offset(s, i)
    if not start_byte then return nil end -- Handle invalid start index

    -- Get the byte offset for the character *after* the ending character index
    -- If j is nil, default to the end of the string (use -1 or length)
    local end_byte
    if j then
        -- We want the byte position of the character *after* j
        end_byte = utf8.offset(s, j + 1)
        -- If end_byte is nil, it means the end of the string was reached or index was invalid
        -- We adjust to get the correct end byte position for string.sub
        if not end_byte then
            end_byte = #s + 1 -- Point just past the end of the string
        end
        -- string.sub expects the last *included* byte index, so we subtract 1
        end_byte = end_byte - 1
    else
        -- If no 'j' is provided, it means until the end of the string.
        -- string.sub with just 'i' and no 'j' (or -1 for 'j') will do this.
        -- We don't need to adjust end_byte here.
    end

    -- Use the standard string.sub with byte offsets
    return string.sub(s, start_byte, end_byte)
end

function Pandoc(doc)
  local meta = doc.meta
  
  -- 容器
  local body_blocks = {}    -- 最终的正文
  local bib_blocks = {}     -- 参考文献
  local summary_blocks = {} -- 摘要
  
  -- 状态标记
  local found_more = false
  local has_bib = false

  -- =================================================
  -- 1. 单次循环处理：正文分离、参考文献提取、摘要提取
  -- =================================================
  for _, block in ipairs(doc.blocks) do
    
    -- A. 检查是不是 <!--more--> 分隔符
    if block.t == "RawBlock" and block.format == "html" and block.text:match("<!%-%-more%-%->") then
      found_more = true
      -- 注意：分隔符本身既不加入 body，也不加入 summary
    
    -- B. 检查是不是参考文献 Div (citeproc 生成的)
    elseif block.t == "Div" and (block.identifier == "refs" or block.classes:includes("references")) then
      block.classes:insert("csl-bib-body")
      table.insert(bib_blocks, block)
      has_bib = true
      
    -- C. 普通内容块
    else
      -- 1. 总是加入正文
      table.insert(body_blocks, block)

      -- 2. 处理摘要
      if not found_more then
        -- 如果还没遇到分隔符，先暂时认为是摘要的一部分
        -- 过滤掉标题 (Header)，避免卡片里出现巨大的 H1/H2
        if block.t ~= "Header" then 
          table.insert(summary_blocks, block)
        end
      end
    end
  end

  -- =================================================
  -- 2. 摘要兜底逻辑 (关键修复！)
  -- =================================================
  -- 如果循环结束了，found_more 还是 false，说明用户没写 <!--more-->
  -- 此时 summary_blocks 里装的是整篇文章（除去参考文献）
  -- 我们需要手动截断它，比如只保留第1个段落，或者前3个块
  
  if not found_more then
    if #summary_blocks > 0 then
      -- 策略 A: 只取第一个非空块 (推荐)
      local first_block = summary_blocks[1]
      summary_blocks = { first_block }
      
      -- 策略 B: 如果你想完全不显示摘要，解开下面这行
      -- summary_blocks = {}
    end
  end

  -- =================================================
  -- 3. 处理脚注 (Footnotes) - 针对 body_blocks
  -- =================================================
  local notes = {}
  
  -- 使用 walk_block 处理刚才分离出来的 body_blocks
  local new_body_div = pandoc.walk_block(pandoc.Div(body_blocks), {
    Note = function(el)
      local num = #notes + 1
      local ref_id = "fnref" .. num
      local note_id = "fn" .. num
      
      local back_link = pandoc.Link({pandoc.Str("↩")}, "#" .. ref_id, "", {
        class="footnote-back", 
        role="doc-backlink",
        ["aria-label"] = "Back to content"
      })
      
      local note_content = el.content
      if #note_content > 0 then
        local last_block = note_content[#note_content]
        if last_block.t == "Para" or last_block.t == "Plain" then
          table.insert(last_block.content, pandoc.Space())
          table.insert(last_block.content, back_link)
        end
      end
      
      table.insert(notes, {id = note_id, content = note_content})
      
      return pandoc.Superscript({
        pandoc.Link({pandoc.Str(tostring(num))}, "#" .. note_id, "", {
          id = ref_id, 
          class="footnote-ref", 
          role="doc-noteref"
        })
      })
    end
  })

  -- =================================================
  -- 4. 写入元数据 (注入 HTML)
  -- =================================================

  -- 注入摘要
  if #summary_blocks > 0 then
    -- 如果是截取的第一段，可能不想让 meta description 太长，这里主要用于页面显示
    meta['summary'] = pandoc.RawInline('html', render_html(summary_blocks))
    
    -- 如果还没有 description (用于 SEO meta tag)，可以用纯文本填充
    if not meta['description'] then
      -- 简单的取巧办法：用 pandoc.write 转成 plain text
      local plain_summary = pandoc.write(pandoc.Pandoc(summary_blocks), 'plain')
      -- 限制长度，防止 SEO 爆炸
      meta['description'] = utf8.sub(plain_summary, 1, 120) .. "..."
    end
  else
    meta['summary'] = nil
  end

  -- 注入参考文献
  if has_bib then
    meta['bib_content'] = pandoc.RawInline('html', render_html(bib_blocks))
  else
    meta['bib_content'] = nil
  end

  -- 注入脚注
  if #notes > 0 then
    local list_items = {}
    for _, note in ipairs(notes) do
      local wrapper = pandoc.Div(note.content, pandoc.Attr(note.id))
      table.insert(list_items, {wrapper})
    end
    local ol = pandoc.OrderedList(list_items)
    local notes_div = pandoc.Div({ol}, pandoc.Attr("", {"footnotes", "prose-sm"}))
    meta['notes_content'] = pandoc.RawInline('html', render_html({notes_div}))
  else
    meta['notes_content'] = nil
  end

  return pandoc.Pandoc(new_body_div.content, meta)
end