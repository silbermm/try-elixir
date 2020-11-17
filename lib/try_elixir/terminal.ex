defmodule TryElixir.Terminal do
  use GenServer, restart: :transient

  @doc false
  def start_link(id) do
    GenServer.start_link(__MODULE__, :ok, name: name(id))
  end

  def init(:ok) do
    {:ok, %{bindings: [], env: init_env()}}
  end

  def execute(terminal, code) do
    GenServer.call(terminal, {:execute, code})
  end

  def handle_call({:execute, code}, _from, state) do
    try do
      {:ok, ast} = Code.string_to_quoted(code)
      {result, bindings, env} = :elixir.eval_forms(ast, state.bindings, state.env)
      {:reply, {:ok, result}, %{state | bindings: bindings, env: env}}
    catch
      kind, error -> {:reply, {:error, kind, error, __STACKTRACE__}, state}
    end
  end

  defp name(id) do
    {:via, Registry, {TryElixir.TerminalRegistry, id}}
  end

  defp init_env do
    :elixir.env_for_eval(file: "iex")
  end
end
