defmodule TryElixir.Terminal do
  use GenServer, restart: :transient

  @init_restricted_non_local [
    {File, [:all]}
    {File.Stream, [:all]}
    {System, [:all]},
    {Node, [:all]},
    {:os, [:all]},
    {:rpc, [:all]},
    {:elixir, [:all]}
  ]

  @restricted_non_local Enum.into(@init_allowed_non_local, Map.new())

  # with 0 arity
  @restricted_local [:binding, :make_ref, :node, :self]

  @doc false
  def start_link(id) do
    GenServer.start_link(__MODULE__, :ok, name: name(id))
  end

  def init(:ok) do
    env = :elixir.env_for_eval(file: "iex")
    {:ok, %{bindings: [], env: env, cache: ""}}
  end

  def execute(terminal, code, line) do
    GenServer.call(terminal, {:execute, code, line})
  end

  def current_line(terminal) do
    GenServer.call(terminal, :current_line)
  end

  def handle_call({:execute, code, line}, _from, state) do
    try do
      _execute(code, line, state)
    catch
      kind, error -> {:reply, {:error, kind, error, __STACKTRACE__}, state}
    end
  end

  def handle_call(:current_line, _from, %{env: env} = state) do
    {:reply, env.line, state}
  end

  defp _execute(code, line, %{cache: cache} = state) do
    code = "#{cache}#{code}\n"

    case Code.string_to_quoted(code, line: line) do
      {:ok, ast} ->
        #unless is_safe?(ast, [], state) do
          #raise "restricted"
        #end

        {result, bindings, env} = :elixir.eval_forms(ast, state.bindings, state.env)
        {:reply, {:ok, result}, %{bindings: bindings, env: env, cache: ""}}

      {:error, {line, error, ""}} ->
        {:reply, :continue, %{state | cache: code}}
    end
  end

  defp name(id) do
    {:via, Registry, {TryElixir.TerminalRegistry, id}}
  end

end
