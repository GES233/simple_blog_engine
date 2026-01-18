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
    |> Path.absname()
    |> Path.wildcard()
    |> Enum.map(fn p ->
      {p |> Path.basename() |> String.split(".") |> Enum.at(0), p}
    end)
    |> Enum.into(%{}),
  lua_filters:
    "apps/pandox/priv/lua_filters/*.lua"
    |> Path.absname()
    |> Path.wildcard()
    |> Enum.map(fn p ->
      {p |> Path.basename() |> String.split(".") |> Enum.at(0), p}
    end)
    |> Enum.into(%{})

config :elixir, :time_zone_database, Tz.TimeZoneDatabase

# 配置 esbuild （需要版本号）
config :esbuild,
  version: "0.25.4",
  ges233: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/generated/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../apps/ges233/assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# 配置 tailwind （需要版本号）
config :tailwind,
  version: "4.1.7",
  ges233: [
    args: ~w(
      --input=apps/ges233/assets/css/app.css
      --output=priv/generated/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]
