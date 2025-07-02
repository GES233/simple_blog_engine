defmodule Graphviz do
  def get_dot(), do: "dot"

  # AIO
  # dot -Tsvg "d:/Blog/source/src/Hypothalamus-pipuitory-axis.dot" > "saved.svg"
  def execute(dot_path) do
    System.shell("#{get_dot()} -Tsvg \"#{dot_path}\"")
    |> handle_result()
  end

  defp handle_result({res, 0}), do: {:ok, res}
  defp handle_result({err, code}), do: {:error, {code, err}}
end
