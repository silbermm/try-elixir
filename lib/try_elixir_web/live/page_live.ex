defmodule TryElixirWeb.PageLive do
  use TryElixirWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    with {:ok, pid} <- TryElixir.Runners.start_terminal(socket.id) do
      {:ok, socket |> assign(history: [], terminal: pid)}
    else
      {:error, {:already_started, pid}} -> {:ok, socket |> assign(history: [], terminal: pid)}
    end
  end

  def handle_event("iex", %{"command" => "clear"}, socket) do
    history = [] 
    {:noreply, socket |> assign(:history, history)}
  end
  
  def handle_event("iex", %{"command" => data}, socket) do
    result = case TryElixir.Terminal.execute(socket.assigns.terminal, data) do
      {:ok, result} -> {:success, inspect(result)}
      {:error, kind, error, stack} -> 
        {:error, Exception.format(kind, error, stack)}
    end
    history = socket.assigns.history ++ [{:command, "iex> #{data}"}, result]
    {:noreply, socket |> assign(:history, history)}
  end

  def render(assigns) do
    ~L"""
     <h4> Erlang/OTP 23 [erts-11.0] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [hipe] </h4> 
     <%= for {class, text} <- @history do %>
       <div class="history <%= class %>"> 
        <%= format_text(text) %> 
       </div>
     <% end %>
     <form phx-submit="iex" >
       iex&gt; <input class="terminal" type="text" name="command" autofocus />
     </form>
    """
  end

  defp format_text(text) do
    text
    |> String.split("\n")
    |> Enum.with_index
    |> Enum.map(fn {t, c} -> 
      if c == 0 do
        ~E"""
        <p style="line-height: 0em"> <%= t %> </p> 
        """
      else
        ~E"""
        <p style="line-height: 0em; margin-left: 2em;"> <%= t %> </p> 
        """
      end
    end)
  end
end
