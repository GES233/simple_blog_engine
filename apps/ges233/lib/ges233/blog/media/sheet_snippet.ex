defmodule GES233.Blog.Media.SheetSnippet do
  # 用于配合 `Lilypond` 模块。
  defstruct [
    :snippet_folder,
    :snippet_name,
    :lilypond_version,
  ]

  # def get_lilypond_version(), do: Lilypond.execute()

  # defmodule LilypondSigil do
  #   defmacro sigil_L(), do: nil
  #   defmacro sigil_l(), do: nil
  # end

  # defmacro __using__(_opts) do
  #   quote do
  #     import LilypondSigil
  #   end
  # end
end
