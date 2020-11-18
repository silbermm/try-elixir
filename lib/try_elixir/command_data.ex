defmodule TryElixir.CommandData do
  @moduledoc false

  defstruct [:commands, :size, :position]

  def new() do
    %__MODULE__{
      commands: [],
      size: 0,
      position: 0,
    }
  end

  def add(command_data, command) do
    %{command_data | size: command_data.size + 1, commands: [command | command_data.commands], position: 0}
  end

  def last_command(command_data) do
    if command_data.size > command_data.position do
      data = %{command_data | position: command_data.position + 1}
      {Enum.at(command_data.commands, command_data.position), data}
    else
      if command_data.size > 0 do
        {Enum.at(command_data.commands, -1), command_data}
      else
        {"", command_data}
      end
    end
  end

  def previous_command(command_data) do
    if command_data.position > 1 do
      data = %{command_data | position: command_data.position - 1}
      {Enum.at(command_data.commands, command_data.position - 2), data}
    else
      {"", command_data}
    end
  end

  def reset_position(command_data) do
    %{command_data | position: 0}
  end
end
