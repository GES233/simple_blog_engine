defmodule GES233.Blog do
  alias GES233.Blog.{Post, Parser}

  @default_rootpath File.cwd!() |> Path.join("priv/_posts")

  defmodule Parser do
    def parse(_path, contents) do
      with %{} = meta <- Post.get_post_meta(contents),
           content <- Post.get_post_content(contents) do
        {:ok, meta, content}
      else
        err -> {:error, err}
      end
    end
  end

  use NimblePublisher,
    build: Post,
    from: @default_rootpath <> "/**/*.md",
    as: :posts,
    highlighters: [:makeup_elixir],
    parser_module: Parser

  # html_converter: GES233.Blog.Renderer
end
