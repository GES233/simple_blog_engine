
defmodule GES233.Helpers.PathUtils do
  @moduledoc """
  Provides utility functions for handling file paths.
  """

  @doc """
  Converts a file path into a canonical, normalized format.
  - Makes the path absolute.
  - Converts all separators to forward slashes (`/`).
  - Downcases the drive letter on Windows.
  """
  def normalize(path) do
    normalized = path |> Path.expand()

    if :os.type() == {:win32, :nt} do
      Regex.replace(~r/^[A-Z]:/, String.replace(normalized, "\\", "/"), &String.downcase/1)
    else
      normalized
    end
  end
end
