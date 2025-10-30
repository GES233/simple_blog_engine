defmodule GES233.Deploy do
  @git_path [
    ~S"D:\Blog\.deploy_git",
    ~S"D:\Blog\site_repo"
  ]
  @new_git_path "site_repo"

  def get_git_path do
    maybe_path = @git_path
    |> Enum.filter(&valid_repo/1)

    if length(maybe_path) > 0 do
      hd(maybe_path)
    else
      Git.clone!([Application.get_env(:ges233, :Git)[:repo], @new_git_path])

      # TODO: Switch to `site` branch.

      @new_git_path
    end
  end

  defp valid_repo(path) do
    File.exists?(path) and File.exists?("#{path}/.git")
  end

  def copy_files_to_git(target_path \\ get_git_path()) do
    deploy_file_list = Application.get_env(:ges233, :saved_path)
    |> FlatFiles.list_all

    for file <- deploy_file_list do
      target_f = String.replace(file, "#{Application.get_env(:ges233, :saved_path)}", target_path)

      target_f |> Path.split() |> :lists.droplast() |> Path.join() |> File.mkdir_p() |> case do
        {:error, reason} -> IO.inspect(reason)
        _ -> nil
      end

      File.copy(file, target_f)
    end

    :ok
  end

  def commit_git(target_path \\ get_git_path()) do
    repo = if valid_repo(target_path), do: %Git.Repository{path: target_path} |> IO.inspect()

    Git.add(repo, ["."]) |> IO.inspect(label: :add)

    Git.commit(repo, ["-m", "Commit on #{DateTime.utc_now()}+0000"])
    |> IO.inspect(label: :commit)
    |> case do
      {:ok, _} -> Git.push(repo) |> IO.inspect(label: :push)
      _ -> nil
    end
  end

  def exec(commit \\ false) do
    path = get_git_path()

    :ok = copy_files_to_git(path)

    if commit, do: commit_git(path)
  end
end
