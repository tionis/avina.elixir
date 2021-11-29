defmodule Glyph.Discord.Commands do
  @doc """
    Simply returns a list of command data structures
    to send discord for the smart command functionality
  """
  def get_commands do
    [
      %{
        name: "roll",
        description: "roll some dice",
        options: [
          %{type: 3, name: "dice-amount", description: "Number of dice to roll", required: true},
          %{
            type: 3,
            name: "dice-modifiers",
            description: "Modifiers to apply to roll",
            required: false
          }
        ]
      },
      %{
        name: "rollinit",
        description: "roll many inits",
        options: [
          %{type: 4, name: "amount", description: "Amount of inits to roll", required: true},
          %{
            type: 4,
            name: "init-mods",
            description: "Init Modifiers to apply to the rolls",
            required: true
          }
        ]
      },
      %{
        name: "shadowroll",
        description: "roll shadowrun dice",
        options: [
          %{type: 4, name: "amount", description: "Amount of dice to throw", required: true},
          %{
            type: 5,
            name: "is_edge",
            description: "Is an edge throw?",
            required: false
          }
        ]
      },
      %{
        name: "edge",
        description: "apply edge to your last dice throw and reroll it"
      }
    ]
  end

  @spec init :: :ok
  def init do
    apply_command_global(get_commands())
  end

  def init_guild(guild_id) do
    apply_command_guild(guild_id, get_commands())
  end

  def clear_guild_commands(guild_id) do
    {:ok, commands} = Nostrum.Api.get_guild_application_commands(guild_id)

    Enum.map(commands, fn x ->
      {:ok} = Nostrum.Api.delete_guild_application_command(
        Map.get(x, :application_id),
        Map.get(x, :guild_id),
        Map.get(x, :id)
      )
    end)
  end

  def clear_commands() do
    {:ok, commands} = Nostrum.Api.get_global_application_commands()

    Enum.map(commands, fn x ->
      {:ok} = Nostrum.Api.delete_global_application_command(
        Map.get(x, :application_id),
        Map.get(x, :id)
      )
    end)
  end

  defp apply_command_global(command_list) do
    {:ok, _} = Nostrum.Api.create_global_application_command(hd(command_list))

    if !Enum.empty?(tl(command_list)) do
      apply_command_global(tl(command_list))
    end

    :ok
  end

  defp apply_command_guild(guild_id, command_list) do
    {:ok, _} = Nostrum.Api.create_guild_application_command(guild_id, hd(command_list))

    if !Enum.empty?(tl(command_list)) do
      apply_command_global(tl(command_list))
    end

    :ok
  end
end
