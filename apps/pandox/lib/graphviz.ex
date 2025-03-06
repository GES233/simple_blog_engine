defmodule Graphviz do
  def get_dot(), do: "dot"

  # AIO
  # dot -Tsvg "d:/Blog/source/src/Hypothalamus-pipuitory-axis.dot" > "saved.svg"
  def execute(dot_path) do
    System.shell("#{get_dot()} -Tsvg \"#{dot_path}\"")
    |> handle_result()
  end

  def handle_result({res, 0}), do: res
  def handle_result({err, _code}), do: raise err
end
