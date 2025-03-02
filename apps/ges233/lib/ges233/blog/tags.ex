defmodule GES233.Blog.Tags do
  # 标签
  alias GES233.Blog.Post

  def get_tags_frq_from_posts(posts) do
    posts
    |> Enum.reduce([], &[&1.tags | &2])
    |> List.flatten()
    |> Enum.frequencies()
  end

  def fetch_all_tags_from_posts([%{tags: _} | _] = posts) do
    posts
    |> get_tags_frq_from_posts()
    |> Map.keys()
  end

  def get_all_posts_from_tags([%Post{} | _] = posts, tag) do
    cond do
      tag not in fetch_all_tags_from_posts(posts) -> []
      true -> Enum.filter(posts, fn post -> tag in post.tags end)
    end
  end

  def get_tags_posts_mapper(posts) do
    tags = fetch_all_tags_from_posts(posts)

    for tag <- tags do
      {tag, posts |> get_all_posts_from_tags(tag) |> Enum.map(&(&1.id))}
    end
    |> Enum.into(%{})
  end
end
