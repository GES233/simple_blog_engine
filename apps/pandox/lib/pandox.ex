defmodule Pandox do
  @moduledoc """
  Documentation for `Pandox`.
  """

  # 默认的 pandoc 可执行文件的地址
  # （我假定你是通过 Scoop/apt/Homebrew 等方式安装的）
  @pandoc_executable_name "pandoc"

  def get_pandoc() do
    # 还要考虑从配置中读取可执行文件的地址的情况
    @pandoc_executable_name
  end

  def get_args_from_meta(%{pandox: args}) do
    # 这个部分是打算和 NimblePublisher 耦合的
    # 如果 MetaData 里有个 %{pandox: []} 字段，
    # 把它丢过来
    args
  end

  def get_args_from_meta(_), do: []

  @doc """
  ...
  """
  def render(_data, _opts \\ []) do
    # pandoc -<input-markdown> -o -<output-html> --<other-options>
    pandoc = get_pandoc()

    # [TODO) 从配置中添加额外的指令
    # Application.get_env(:pandox, :render_args)

    args = (["-h"] ++ get_args_from_meta(%{})) |> Enum.join(" ")

    {stdout, status} = System.cmd(pandoc, [args], stderr_to_stdout: true)

    case status do
      0 -> stdout |> IO.inspect(label: :ok)
      _ -> IO.inspect(stdout, label: status)
    end
  end

  @doc """
  Hello world.

  ## Examples

      iex> Pandox.hello()
      :world

  """
  def hello do
    :world
  end
end
