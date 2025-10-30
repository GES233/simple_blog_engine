defmodule GES233.Blog.Bibliography do
  require Logger

  @entry Application.compile_env(:ges233, :bibliography_entry, "/priv/_bibs")

  def get_bibliography_entry, do: @entry

  # Invoked by pandoc-crossref
  def maybe_validate_bibliography_exist({%{extra: extra} = page_has_extra, bib_context}) do
    if Map.get(extra, "pandoc") do
      %{"pandoc" => pandox_options} = extra

      # 最开始选用 File.touch/1 使为了确保文件存在
      # 但是这会触发 FileSystem 的事件
      # 后续可能会做出修改
      with {:ok, bib_path_realtive} <- Map.fetch(pandox_options, "bibliography"),
           bib_path = Path.join([@entry, bib_path_realtive]),
           true <- File.exists?(bib_path) do
        {page_has_extra, Map.put(bib_context, "bibliography", bib_path)}
      else
        false ->
          Logger.warning(
            "File #{inspect(Path.join([@entry, pandox_options["bibliography"]]))} doesn't exist."
          )

          {page_has_extra, Map.put(bib_context, "bibliography", nil)}

        :error ->
          {page_has_extra, Map.put(bib_context, "bibliography", nil)}
      end
    else
      {page_has_extra, Map.put(bib_context, "bibliography", nil)}
    end
  end

  def ensure_bib_format({page_has_extra, %{"bibliography" => nil} = context}) do
    {page_has_extra, context}
  end

  def ensure_bib_format({page_has_extra, %{"bibliography" => _path} = context}) do
    # 依据 categories 或显式声明确定参考文献的格式 bla bla

    {page_has_extra, context}
  end

  def add_title_to_meta({page_has_extra, meta}) do
    {page_has_extra, Map.put(meta, :title, page_has_extra.title)}
  end

  def postlude({_post, meta}),
    do: if(Map.get(meta, "bibliography"), do: meta, else: %{})
end
