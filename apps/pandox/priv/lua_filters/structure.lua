-- filters/structure.lua
local utils = require 'pandoc.utils'

-- 辅助：渲染 Block 列表为 HTML
local function render_html(blocks)
  return pandoc.write(pandoc.Pandoc(blocks), 'html')
end

function Pandoc(doc)
  local meta = doc.meta
  local body_blocks = {}
  local bib_blocks = {}
  local meta = doc.meta
  local summary_blocks = {}
  local found_more = false
  
  -- =================================================
  -- 1. 提取参考文献 (Bibliography)
  -- =================================================
  -- --citeproc 运行后，通常会生成一个 id="refs" 的 Div
  -- 或者 class="references" 的 Div
  
  for _, block in ipairs(doc.blocks) do
    if block.t == "Div" and (block.identifier == "refs" or block.classes:includes("references")) then
      -- 找到了参考文献块
      -- 我们可以给它加一些 Tailwind 类
      block.classes:insert("csl-bib-body")
      table.insert(bib_blocks, block)
    else
      -- 其他内容保留在正文
      table.insert(body_blocks, block)
    end
  end

  -- =================================================
  -- 2. 提取脚注 (Footnotes)
  -- =================================================
  local notes = {}
  
  -- 使用 walk_block 遍历 body_blocks（不包含参考文献了）
  -- 必须把 Note 替换成 Superscript，否则 Pandoc HTML Writer 还是会在底部生成脚注
  local new_body = pandoc.walk_block(pandoc.Div(body_blocks), {
    Note = function(el)
      local num = #notes + 1
      local ref_id = "fnref" .. num
      local note_id = "fn" .. num
      
      -- 构建“返回”链接 (↩)
      local back_link = pandoc.Link({pandoc.Str("↩")}, "#" .. ref_id, "", {
        class="footnote-back", 
        role="doc-backlink",
        ["aria-label"] = "Back to content"
      })
      
      -- 复制脚注内容，并在最后一个 block 末尾追加返回链接
      local note_content = el.content
      if #note_content > 0 then
        local last_block = note_content[#note_content]
        -- 只有段落或纯文本块适合追加 Inline 元素
        if last_block.t == "Para" or last_block.t == "Plain" then
          table.insert(last_block.content, pandoc.Space())
          table.insert(last_block.content, back_link)
        end
      end
      
      table.insert(notes, {id = note_id, content = note_content})
      
      -- 在正文中替换为： <sup><a href="#fn1" id="fnref1">[1]</a></sup>
      return pandoc.Superscript({
        pandoc.Link({pandoc.Str(tostring(num))}, "#" .. note_id, "", {
          id = ref_id, 
          class="footnote-ref", 
          role="doc-noteref"
        })
      })
    end
  })

  -- 我们在遍历 blocks 处理 refs 的同时，顺便处理摘要
  -- 为了代码清晰，这里写成单独的逻辑，你整合时可以合并循环
  
  for _, block in ipairs(doc.blocks) do
    -- 1. 检查是否是 <!--more-->
    -- Pandoc 把 HTML 注释解析为 RawBlock('html', '<!--more-->')
    if block.t == "RawBlock" and block.format == "html" and block.text:match("<!%-%-more%-%->") then
      found_more = true
      -- 不把 <!--more--> 加入正文，直接跳过
    else
      -- 2. 如果还没遇到 more，且不是参考文献，则加入摘要
      if not found_more and block.t ~= "Div" then -- 简单过滤一下，这里可以更精细
         table.insert(summary_blocks, block)
      end
      
      -- 3. 正常的正文处理逻辑 (refs 提取等)
      -- 这里是你之前的逻辑，决定是否加入 body_blocks
      -- (略: 你的 refs 提取逻辑)
    end
  end

  -- 生成摘要 HTML 并注入 Metadata
  if #summary_blocks > 0 then
    -- 如果原本 Metadata 里没有 description，就用我们提取的 summary 填充
    if not meta['description'] then
      meta['description'] = pandoc.RawInline('html', render_html(summary_blocks))
    end
    -- 或者专门存一个 summary 变量
    meta['summary'] = pandoc.RawInline('html', render_html(summary_blocks))
  end

  -- =================================================
  -- 3. 生成 HTML 并注入 Metadata
  -- =================================================

  -- 处理参考文献 HTML
  if #bib_blocks > 0 then
    -- 使用新变量名 bib_content，避免和 metadata['bibliography'] 路径冲突
    meta['bib_content'] = pandoc.RawInline('html', render_html(bib_blocks))
  else
    meta['bib_content'] = nil
  end

  -- 处理脚注 HTML
  if #notes > 0 then
    -- 构建有序列表
    local list_items = {}
    for _, note in ipairs(notes) do
      -- 这里为了样式方便，我们给每个 li 里的内容包一个 div
      -- 并手动赋予 id，以便锚点跳转
      local item_content = note.content
      -- 我们需要把 id="fn1" 放在 li 上，或者 li 内部的第一个元素上
      -- Pandoc AST 的 OrderedList 不支持给 li 加 id，所以我们在内容外包一个 Div
      local wrapper = pandoc.Div(item_content, pandoc.Attr(note.id))
      table.insert(list_items, {wrapper})
    end
    
    local ol = pandoc.OrderedList(list_items)
    local notes_div = pandoc.Div({ol}, pandoc.Attr("", {"footnotes", "prose-sm"}))
    
    meta['notes_content'] = pandoc.RawInline('html', render_html({notes_div}))
  else
    meta['notes_content'] = nil
  end

  -- 返回新的文档：
  -- 1. body 已经是去除 Refs 且替换了 Note 的纯净版
  -- 2. meta 里包含了 bib_content 和 notes_content
  return pandoc.Pandoc(new_body.content, meta)
end
