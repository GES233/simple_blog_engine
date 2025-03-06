import Config

config :logger, :console,
  level: :info,
  format: "$date $time [$level] $metadata$message\n"

config :ges233,
  blog_root: "D:/Blog/source/_posts",
  bibliography_entry: "D:/Blog/source/_bibs",
  saved_path: "priv/generated"

config :ges233, :Media,
  pic_path: "D:/Blog/source/img",
  pdf_path: "D:/Blog/source/pdf",
  dot_path: "D:/Blog/source/src"

config :ges233, :Blog,
  page_pagination: 12

config :pandox,
  execute_path: "pandoc",
  render_args: [],
  crossref_yaml: Path.absname("apps/pandox/priv/pandoc_cressref.yaml"),
  csl:
    (Path.absname("apps/pandox/priv/csl") <> "/*.csl")
    |> Path.wildcard()
    |> Enum.map(
      fn p ->
        {p |> Path.basename() |> String.split(".") |> Enum.at(0), p}
      end)
    |> Enum.into(%{})
