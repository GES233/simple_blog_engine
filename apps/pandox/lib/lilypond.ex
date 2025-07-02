defmodule Lilypond do
  def get_ly, do: "lilypond"

  def execute(_path) do
    # System.shell("#{get_ly}")
    # |> handle_result()

    raise "Not implemented yet"
  end

  # defp args(:version, _), do: "-v"
  # defp args(:snippet, {source, target}), do: ~w()

  # defp handle_result({res, 0}), do: {:ok, res}
  # defp handle_result({err, code}), do: {:error, {code, err}}
end
