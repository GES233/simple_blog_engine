defmodule GES233.Blog.Series do
  # 类属
  def fetch_all_series_from_posts(posts) do
    posts
    |> Enum.reduce([], &[&1.series | &2])
    |> Enum.reject(&(&1 == nil))
    |> Enum.uniq()
  end

  def get_all_posts_with_series(posts, series) do
    cond do
      series not in fetch_all_series_from_posts(posts) ->
        []

      true ->
        posts
        |> Enum.filter(&(&1.series == series))
        |> Enum.sort_by(& &1.create_at, {:desc, Date})
    end
  end

  def get_all_series(posts) do
    series = fetch_all_series_from_posts(posts)

    for series_item <- series do
      {series_item, get_all_posts_with_series(posts, series_item)}
    end
    |> Enum.into(%{})
  end
end
