defmodule TryElixir.Runners do
  use DynamicSupervisor

  alias TryElixir.Terminal

  def start_link(init_arg),
    do: DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

  @impl true
  @doc false
  def init(init_arg),
    do: DynamicSupervisor.init(strategy: :one_for_one)

  def start_terminal(id) do
    spec = {Terminal, id}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def find_terminal(id) do
    TryElixir.TerminalRegistry
    |> Registry.select([{{:"$1", :_, :_}, [], [:"$1"]}])
    |> Enum.sort()
  end

  @doc """
  Stop the current running 'terminal' based on the passed in ID
  """
  @spec stop(binary()) :: :ok
  def stop(id) do
    GenServer.stop(id, :normal)
  end
end
