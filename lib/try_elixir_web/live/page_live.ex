defmodule TryElixirWeb.PageLive do
  use TryElixirWeb, :live_view

  alias TryElixir.CommandData

  @impl true
  def mount(_params, _session, socket) do
    build_info = System.build_info()

    pid =
      with {:ok, pid} <- TryElixir.Runners.start_terminal(socket.id) do
        pid
      else
        {:error, {:already_started, pid}} -> pid
      end

    {:ok,
     socket
     |> assign(
       build_info: build_info,
       history: [],
       command_data: CommandData.new(),
       command: "",
       terminal: pid,
       iex_count: 1,
       multiline: false
     )}
  end

  def handle_event("iex", %{"command" => "clear"}, socket) do
    {:noreply, socket |> assign(history: [])}
  end

  def handle_event("iex", %{"command" => command}, socket) do
    command_data = CommandData.add(socket.assigns.command_data, command)

    case TryElixir.Terminal.execute(socket.assigns.terminal, command, socket.assigns.iex_count) do
      {:ok, result} ->
        result = {:success, inspect(result)}

        history =
          socket.assigns.history ++
            [{:command, "iex(#{socket.assigns.iex_count})> #{command}"}, result]

        {:noreply,
         socket
         |> assign(
           history: history,
           command_data: command_data,
           command: "",
           iex_count: socket.assigns.iex_count + 1,
           multiline: false
         )}

      :continue ->
        history =
          socket.assigns.history ++
            [{:command, "iex(#{socket.assigns.iex_count})> #{command}"}, ""]

        {:noreply,
         socket
         |> assign(history: history, command_data: command_data, command: "", multiline: true)}

      {:error, kind, error, stack} ->
        result = {:error, Exception.format(kind, error, stack)}

        history =
          socket.assigns.history ++
            [{:command, "iex(#{socket.assigns.iex_count})> #{command}"}, result]

        {:noreply,
         socket
         |> assign(history: history, command_data: command_data, command: "", multiline: false)}
    end
  end

  def handle_event("keyup", %{"key" => "ArrowUp"}, socket) do
    {last_command, command_data} = CommandData.last_command(socket.assigns.command_data)

    {:noreply,
     push_event(socket |> assign(command_data: command_data), "cmd", %{command: last_command})}

    # {:noreply, socket |> assign(command_data: command_data, command: last_command)}
  end

  def handle_event("keyup", %{"key" => "ArrowDown"}, socket) do
    {previous_command, command_data} = CommandData.previous_command(socket.assigns.command_data)

    {:noreply,
     push_event(socket |> assign(command_data: command_data), "cmd", %{command: previous_command})}
  end

  def handle_event("keyup", _, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~L"""
    <div phx-window-keyup="keyup">
    <h4> Elixir <%= @build_info.build %> </h4> 
    <%= for {class, text} <- @history do %>
       <div class="history <%= class %>"> 
        <%= format_text(text) %> 
       </div>
    <% end %>
    <form phx-submit="iex" >
      <label for="command"> <%= if @multiline do %>...<% else %>iex<% end %>(<%= @iex_count %>)&gt; </label>
      <input autocomplete="off" id="<%= @command_data.size %>" class="terminal" type="text" name="command" autofocus="" value="<%= @command %>" phx-hook="Focus" />
    </form>
    </div>
    """
  end

  defp format_text(text) do
    text
    |> String.split("\n")
    |> Enum.with_index()
    |> Enum.map(fn {t, c} ->
      if c == 0 do
        ~E"""
        <p class="terminal-error"> <%= t %> </p> 
        """
      else
        ~E"""
        <p class="terminal-error" style="margin-left: 2em;"> <%= t %> </p> 
        """
      end
    end)
  end
end
