defmodule Lilypond do
  # 1. 确定版本
  # 2. 渲染

  def get_ly, do: "lilypond"

  def get_version() do
    System.shell("#{get_ly()} #{args(:version, nil) |> Enum.join(" ")}")
    |> case do
      {intro_with_version, 0} -> intro_with_version
      {err, _code} -> raise err
    end
  end

  defp args(:version, _), do: "-v"
  # defp args(:snippet, {source, target}), do: ~w()

  # defp handle_result({res, 0}), do: {:ok, res}
  # defp handle_result({err, code}), do: {:error, {code, err}}
end
