defmodule GES233.Deploy do
  @git_path [
    ~S"D:\Blog\.deploy_git"
  ]

  def get_git_path do
    @git_path |> Enum.filter(&valid_repo/1) |> hd()
  end

  defp valid_repo(path) do
    File.exists?(path) and File.exists?("#{path}/.git")
  end

  def copy_files_to_git(target_path \\ get_git_path()) do
    deploy_file_list = Application.get_env(:ges233, :saved_path)
    |> GES233.Blog.Static.FlatFiles.list_all

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

    Git.add(repo) |> IO.inspect(label: :add)

    Git.commit(repo, ["-m", "Commit on #{DateTime.utc_now()}+0000"]) |> IO.inspect(label: :commit)

    Git.push(repo) |> IO.inspect(label: :push)
  end

  def exec() do
    path = get_git_path()

    copy_files_to_git(path)

    commit_git(path)
  end
end
