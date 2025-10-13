defmodule GES233 do
  @moduledoc """
  Documentation for `GES233`.
  """

  def exe() do
    GES233.Blog.Builder.build_from_root()

    :ok
  end

  def deploy() do
    GES233.Deploy.exec(true)
  end

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
