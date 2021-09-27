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
      }
    ]
  end

  @spec init :: :ok
  def init do
    apply_command_global(get_commands())
  end

  @spec init_guild(binary) :: none
  def init_guild(guild_id) do
    apply_command_guild(guild_id, get_commands())
  end

  defp apply_command_global(command_list) do
    Nostrum.Api.create_global_application_command(hd(command_list))

    if !Enum.empty?(tl(command_list)) do
      apply_command_global(tl(command_list))
    end

    :ok
  end

  defp apply_command_guild(guild_id, command_list) do
    Nostrum.Api.create_guild_application_command(guild_id, command_list)

    if !Enum.empty?(tl(command_list)) do
      apply_command_global(tl(command_list))
    end

    :ok
  end
end
