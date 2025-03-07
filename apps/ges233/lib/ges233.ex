defmodule GES233 do
  @moduledoc """
  Documentation for `GES233`.
  """

  defdelegate exe, to: GES233.Blog.Builder, as: :build_from_root

  @doc """
  Hello world.

  ## Examples

      iex> GES233.hello()
      :world

  """
  def hello do
    :world
  end
end
