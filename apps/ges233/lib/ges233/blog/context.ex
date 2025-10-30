defmodule GES233.Blog.Context do
  # 保存上下文

  alias GES233.Blog.{Post, Media}

  @type meta_registry :: %{atom() => Post.t() | Media.t()}
  @type index_registry :: %{
          binary() => term()
        }
  @type t :: {meta_registry, index_registry}

  # use Agent
end
