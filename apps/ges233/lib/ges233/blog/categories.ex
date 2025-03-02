defmodule GES233.Blog.CategoryItem do
  alias GES233.Blog.Post
  defstruct [:name, :relative_depth, :child, :posts]
  # 因为属别与帖子是多对多的关系，所以这里的帖子只保留 id

  def add_post(%__MODULE__{} = category, %Post{} = post) do
    %{category | posts: [post.id | category[:posts]]}
  end

  def add_posts(%__MODULE__{} = category, [%Post{} | _] = posts) do
    %{category | posts: (category[:posts] ++ posts) |> Enum.map(& &1.id)}
  end

  def add_child(%__MODULE__{} = category, %__MODULE__{} = child_categoty) do
    %{
      category
      | child: [
          %{child_categoty | relative_depth: child_categoty[:relative_path] + 1}
          | category[:child]
        ]
    }
  end

  # [TODO) Add find_child/2

  @init_node_name "未归类"
  def init_node(),
    do: %__MODULE__{
      name: @init_node_name,
      relative_depth: 0,
      child: [],
      posts: []
    }
end

defmodule GES233.Blog.Categories do
  # 类属
  def get_all_categories_from_posts(posts) do
    posts
    |> Enum.reduce([], &[&1.categories | &2])
    |> Enum.uniq()
  end

  def get_all_posts_from_specific_category(posts, category_name) do
    # 最好用未归类的
    categories = get_all_categories_from_posts(posts)

    cond do
      category_name not in categories ->
        []

      true ->
        posts
        |> Enum.filter(&(category_name in &1.categories))
    end
  end

  # 将 categories 整合
  # [TODO) 递归警告
  def integrate_categories(_posts), do: nil
end
