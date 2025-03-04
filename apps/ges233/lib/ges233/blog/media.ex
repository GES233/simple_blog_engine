defmodule Ges233.Blog.Media do
  @type t :: %__MODULE__{
    id: String.t(),
    type: :pic | :pdf | :dot,
    path: String.t()
  }
  defstruct [:id, :type, :path]

  # Simply copy
  def get_media_under(path, :pic) do
    Path.wildcard(path <> "**/*.{jpg,jpeg,png,webp}")
    |> Enum.map(&Task.async(fn -> parse_media(&1, :pic) end))
    |> Enum.map(&Task.await/1)
  end

  # Use pdf.js
  def get_media_under(path, :pdf) do
    Path.wildcard(path <> "**/*.pdf")
    |> Enum.map(&Task.async(fn -> parse_media(&1, :pdf) end))
    |> Enum.map(&Task.await/1)
  end

  # It need render
  def get_media_under(path, :dot) do
    Path.wildcard(path <> "**/*.dot")
    |> Enum.map(&Task.async(fn -> parse_media(&1, :dot) end))
    |> Enum.map(&Task.await/1)
  end

  def parse_media(picture_path, type) do
    id = Path.basename(picture_path) |> String.split(".") |> hd()

    %__MODULE__{id: id, type: type, path: picture_path}
  end
end
