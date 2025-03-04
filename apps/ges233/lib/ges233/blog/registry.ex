defmodule GES233.Blog.Post.RegistryBuilder do
  def build_registry(_posts) do

    Module.create(GES233.Blog.Post.Registry, quote do end, __ENV__)
  end
end
