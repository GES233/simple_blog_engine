defmodule PandoxTest do
  use ExUnit.Case
  doctest Pandox

  test "greets the world" do
    assert Pandox.hello() == :world
  end
end
