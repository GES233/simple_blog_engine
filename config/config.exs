# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

config :ges233,
  blog_root: "D:/Blog/source/_posts",
  bibliography_entry: "D:/Blog/source/_bibs"

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
