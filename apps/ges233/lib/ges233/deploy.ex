defmodule GES233.Deploy do
  @git_path [
    ~S"D:\Blog\.deploy_git",
    ~S"D:\Blog\site_repo"
  ]
  @new_git_path "site_repo"

  def get_git_path do
    maybe_path =
      @git_path
      |> Enum.filter(&valid_repo/1)

    if length(maybe_path) > 0 do
      hd(maybe_path)
    else
      Git.clone!([Application.get_env(:ges233, :Git)[:repo], @new_git_path])
      # Switch to `site` branch.
      |> Git.checkout(["site"])

      @new_git_path
    end
  end

  defp valid_repo(path) do
    File.exists?(path) and File.exists?("#{path}/.git")
  end

  def copy_files_to_git(target_path \\ get_git_path()) do
    GES233.Blog.Writer.SinglePage.copy_all_files_except_git(target_path)
  end

  def commit_git(target_path \\ get_git_path(), message) do
    repo = if valid_repo(target_path), do: %Git.Repository{path: target_path} |> IO.inspect()

    Git.add(repo, ["."]) |> IO.inspect(label: :add)

    Git.commit(repo, ["-m", message])
    |> IO.inspect(label: :commit)
    |> case do
      {:ok, _} -> Git.push(repo) |> IO.inspect(label: :push)
      _ -> nil
    end
  end

  def exec(upload? \\ false, message \\ "Commit on #{DateTime.utc_now()}+0000") when is_binary(message)  do
    path = get_git_path()

    :ok = copy_files_to_git(path)

    if upload?, do: do_commit(path, message)
  end

  defp do_commit(path, maybe_message), do: commit_git(path, maybe_message)
end
