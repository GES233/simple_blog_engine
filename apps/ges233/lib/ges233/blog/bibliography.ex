defmodule GES233.Blog.Bibliography do
  alias GES233.Blog.Post
  require Logger
  @entry Application.compile_env(:ges233, :bibliography_entry, "/priv/_bibs")

  # Invoked by pandoc-crossref
  def maybe_validate_bibliography_exist({%Post{extra: extra} = post, bib_context}) do
    if Map.get(extra, "pandoc") do
      %{"pandoc" => pandox_options} = extra
      with {:ok, bib_path_realtive} <- Map.fetch(pandox_options, "bibliography"),
           bib_path = Path.join([@entry, bib_path_realtive]),
           :ok <- File.touch(bib_path) do
        {post, Map.put(bib_context, "bibliography", bib_path)}
      else
        {:error, _} ->
          Logger.warning(
            "File #{inspect(Path.join([@entry, pandox_options["bibliography"]]))} doesn't exist."
          )

          {post, Map.put(bib_context, "bibliography", nil)}

        :error ->
          {post, Map.put(bib_context, "bibliography", nil)}
      end
    else
      {post, Map.put(bib_context, "bibliography", nil)}
    end
  end

  def ensure_bib_format({post, %{"bibliography" => nil} = context}) do
    {post, context}
  end

  def ensure_bib_format({post, %{"bibliography" => _path} = context}) do
    # 依据 categories 或显式声明确定参考文献的格式 bla bla

    {post, context}
  end

  def postlude({_post, meta}),
    do: if(Map.get(meta, "bibliography"), do: meta, else: %{})
end
