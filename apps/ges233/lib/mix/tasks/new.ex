defmodule Mix.Tasks.G.New do
  use Mix.Task

  def run(new_args) do
    path = new_args |> hd()

    File.write("#{Application.get_env(:ges233, :blog_root)}/#{path}.md", """
    ---
    title: #{path}
    date: #{NaiveDateTime.local_now() |> NaiveDateTime.to_string()}
    tags: []
    categories:
    - []
    ---
    """)
  end
end
