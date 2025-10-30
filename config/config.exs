import Config

config :logger, :console,
  level: :info,
  format: "$date $time [$level] $metadata$message\n"

config :ges233,
  blog_root: "D:/Blog/source/_posts",
  page_entry: "D:/Blog/source",
  bibliography_entry: "D:/Blog/source/_bibs",
  saved_path: "priv/generated"

config :ges233, :Media,
  pic_path: "D:/Blog/source/img",
  pdf_path: "D:/Blog/source/pdf",
  dot_path: "D:/Blog/source/src"

config :ges233, :Blog,
  page_pagination: 12,
  name: "自留地",
  description: "记录学习生活的大小事"

config :ges233, :Git,
  repo: "https://github.com/GES233/GES233.github.io",
  branch: "site"

config :pandox,
  execute_path: "pandoc",
  render_args: [],
  toc_template: "apps/pandox/priv/template/with_toc.html",
  crossref_yaml: "apps/pandox/priv/pandoc_cressref.yaml",
  csl:
    "apps/pandox/priv/csl/*.csl"
    |> Path.wildcard()
    |> Enum.map(fn p ->
      {p |> Path.basename() |> String.split(".") |> Enum.at(0), p}
    end)
    |> Enum.into(%{})

config :elixir, :time_zone_database, Tz.TimeZoneDatabase

# 
