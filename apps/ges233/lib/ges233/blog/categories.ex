defmodule GES233.Blog.CategoryItem do
  @type t :: %__MODULE__{
          name: atom(),
          relative_depth: non_neg_integer(),
          child: t(),
          posts: [atom()]
        }
  defstruct [:name, :relative_depth, :child, :posts]
  # 因为属别与帖子是多对多的关系，所以这里的帖子只保留 id

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
  # alias GES233.Blog.CategoryItem, as: Node

  # 类属
  def get_all_categories_from_posts(posts) do
    posts
    |> Enum.reduce([], &(&1.categories ++ &2))
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
        |> Enum.map(& &1.id)
    end
  end

  # 将 categories 整合为树形结构
  def integrate_categories(posts) do
    GES233.Blog.CategoryItem.init_node()
    |> build_tree(get_all_categories_from_posts(posts))
  end

  def build_tree(root, categories) do
    Enum.reduce(
      categories,
      root,
      fn _current, tree ->
        tree
      end
    )
  end

  # def add_posts
end
