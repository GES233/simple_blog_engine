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
  alias GES233.Blog.CategoryItem, as: Node

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
  @doc """
  从所有文章中提取分类并构建树形结构。

  参数: posts - [%Blog.Posts{categories: [list(binary)]}]
  返回: %Node{} 的树形结构
  """
  def build_category_tree(posts) do
    # 获取所有分类并附加文章ID
    all_categories_with_posts = Enum.flat_map(posts, fn post ->
      Enum.map(post.categories, &{&1, post.id})
    end)

    # 初始化根节点
    root = Node.init_node()

    # 递归构建树
    Enum.reduce(all_categories_with_posts, root, fn {category_path, post_id}, acc ->
      insert_category(acc, List.wrap(category_path), post_id, 0)
    end)
  end

  # 递归插入分类路径到树中
  defp insert_category(node, [current | rest], post_id, depth) do
    # 将字符串转为 atom
    current_atom = String.to_atom(current)
    
    # 查找或创建当前层级的子节点
    {matched_child, other_children} =
      Enum.split_with(node.child, fn %Node{name: name} -> name == current_atom end)

    child_node =
      case matched_child do
        [] ->
          # 创建新节点
          %Node{
            name: current_atom,
            relative_depth: depth,
            child: [],
            posts: [post_id]
          }
        [existing | _] ->
          # 更新已有节点的 posts
          %Node{existing | posts: [post_id | existing.posts]}
      end

    # 如果还有剩余路径，继续递归
    updated_child =
      if rest != [] do
        insert_category(child_node, rest, post_id, depth + 1)
      else
        child_node
      end

    # 更新当前节点的子节点列表
    %Node{node | child: [updated_child | other_children]}
  end

  defp insert_category(node, [], post_id, _depth) do
    # 没有分类路径时，将文章放入当前节点
    %Node{node | posts: [post_id | node.posts]}
  end

  # def add_posts
end
