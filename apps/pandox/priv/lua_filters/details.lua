-- filters/details.lua

function Div(el)
  -- 检查 Div 是否包含 'details' 类
  if el.classes:includes('details') then
    
    -- 提取第一个区块作为 summary
    local summary_content = {}
    local details_content = {}

    if #el.content > 0 then
      -- 取出第一个元素
      local first_block = table.remove(el.content, 1)
      
      -- 如果第一个元素是标题(Header)，取出其内部的 Inline 内容
      if first_block.t == "Header" then
        summary_content = first_block.content
      -- 如果是段落(Para)，也直接取内容
      elseif first_block.t == "Para" then
        summary_content = first_block.content
      else
        -- 其他情况，直接放入 summary
        table.insert(summary_content, first_block)
      end
      
      -- 剩下的就是 details 的主体内容
      details_content = el.content
    else
      -- 如果是空的，给个默认标题
      table.insert(summary_content, pandoc.Str("Details"))
    end

    -- 构造 HTML 结构
    -- 我们需要创建一个包裹内容的 div，以便应用 padding 样式
    local content_wrapper = pandoc.Div(details_content, pandoc.Attr("", {"details-content"}))

    -- 构造 Summary 元素
    local summary = pandoc.RawBlock("html", "<summary>")
    local summary_end = pandoc.RawBlock("html", "</summary>")
    
    -- 构造 Details 元素
    local details_start = pandoc.RawBlock("html", "<details>")
    local details_end = pandoc.RawBlock("html", "</details>")

    -- 这里的逻辑是将 AST 节点组合起来
    -- Pandoc Lua 处理 HTML 标签包裹比较麻烦，通常最简单的方法是直接返回 RawBlock 包裹
    -- 但为了保留内部 Markdown 解析，我们构建一个新的 Div 结构，但欺骗 Pandoc 渲染成 details
    
    -- 方法 B: 直接用 pandoc.walk_block 或者简单的表拼接
    -- 更稳健的方法是直接输出 RawHTML 包裹内容
    
    local blocks = {
      details_start,
      summary
    }
    
    -- 将 summary 的 inline 内容加入 blocks
    -- 注意：summary 标签内不能放块级元素(h1-h6/p)，只能放 inline。
    -- 所以我们把上面提取的 Header/Para 的内容(Inlines) 放进去。
    blocks[#blocks + 1] = pandoc.Plain(summary_content)
    
    blocks[#blocks + 1] = summary_end
    blocks[#blocks + 1] = content_wrapper
    blocks[#blocks + 1] = details_end

    return blocks
  end
end