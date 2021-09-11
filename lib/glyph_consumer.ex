defmodule GlyphConsumer do
  @moduledoc """
  A module that implements all logic that consumes discord events,
  at least for the moment
  """
  use Nostrum.Consumer

  alias Nostrum.Api

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link do
    Consumer.start_link(__MODULE__)
  end

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

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    words = String.split(msg.content, " ")

    case hd(words) do
      "/roll" ->
        Api.create_message(msg.channel_id, handle_roll(tl(words)))

      "/r" ->
        Api.create_message(msg.channel_id, handle_roll(tl(words)))

      "/ping" ->
        Api.create_message(msg.channel_id, "pong!")

      "/help" ->
        Api.create_message(msg.channel_id, "Not implemented yet!")

      "/init" ->
        Api.create_message(msg.channel_id, handle_initiative(tl(words), get_id_from_discord_msg(msg)))

      # TODO Roll multiple inits at the same time and stuff
      "/rollinit" ->
        Api.create_message(msg.channel_id, "Not implemented yet!")

      # TODO get, of the day, add
      "/quote" ->
        Api.create_message(msg.channel_id, "Not implemented yet!")

      "/remindme" ->
        Api.create_message(msg.channel_id, "Not implemented yet!")

      _ ->
        :ignore
    end
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    case Map.get(interaction, :data) |> Map.get(:name) do
      "roll" -> handle_roll_interaction(interaction)
      _ -> :ignore
    end
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(_event) do
    :noop
  end

  defp handle_initiative(words, user_id) do
    case hd(words) do
    "roll" -> handle_roll_init_mod(tl(words), user_id)
    "save" -> handle_save_init_mod(tl(words), user_id)
    _ -> :ignore
    end
  end

  defp handle_roll_init_mod(words, user_id) do
    one_based_index = Integer.parse(hd(words))
    {:ok, init_list} = get_init_list(user_id)
    if init_list do
      Enum.at(init_list, one_based_index-1)
    else
      "No init modifier saved!"
    end
  end

  defp get_init_list(user_id) do
    # TODO
    init_list = :ets.lookup(:glyph_init_mod, user_id)
    {:ok, init_list}
  end

  defp set_init_list(user_id, init_list) do
    # TODO
    :ets.insert(:glyph_init_mod, {user_id, init_list})
    {:ok}
  end

  defp handle_save_init_mod(words, user_id) do
    init_list = Enum.map(words, fn x -> {new_value, _} = Integer.to_string(x); new_value end)
    {:ok} = set_init_list(user_id, init_list)
    "Saved your init values:\n" <> List.to_string(init_list)
  end

  def get_id_from_discord_msg(msg) do
    "dc:" <> Integer.to_string((Map.get(msg, :author) |> Map.get(:id)))
  end

  defp handle_roll_interaction(interaction) do
    message = get_answer_for_roll_interaction(interaction)

    response = %{
      type: 4,
      data: %{
        content: message
      }
    }

    Api.create_interaction_response(interaction, response)
  end

  defp get_answer_for_roll_interaction(interaction) do
    options = Map.get(interaction, :data) |> Map.get(:options)

    if Enum.empty?(Enum.filter(options, fn x -> Map.get(x, :name) == "dice-modifiers" end)) do
      handle_roll([
        Enum.filter(
          options,
          fn x -> Map.get(x, :name) == "dice-amount" end
        )
        |> hd
        |> Map.get(:value)
        |> Integer.to_string()
      ])
    else
      dice_amount =
        Enum.filter(options, fn x -> Map.get(x, :name) == "dice-amount" end)
        |> hd
        |> Map.get(:value)
        |> Integer.to_string()

      dice_modifiers =
        Enum.filter(options, fn x -> Map.get(x, :name) == "dice-modifiers" end)
        |> hd
        |> Map.get(:value)

      handle_roll([dice_amount, dice_modifiers])
    end
  end

  @spec handle_roll(nonempty_maybe_improper_list) :: binary
  def handle_roll(words) do
    cond do
      Regex.match?(~r/\dd\d/, hd(words)) ->
        parse_dice_notation(hd(words)) |> roll_x_y_sided_dice() |> normal_dice_result_to_string()

      Regex.match?(~r/\d/, hd(words)) ->
        handle_construct_roll(words)

      Regex.match?(~r/chance/, hd(words)) ->
        handle_chance_die()
    end
  end

  defp handle_chance_die() do
    number = Enum.random(1..10)
    text = "You rolled a **" <> Integer.to_string(number) <> "**!"

    case number do
      10 -> text <> "\nWell, that's a **success**!"
      1 -> text <> "\nWell, that's a **critical failure**!"
      _ -> text
    end
  end

  def handle_construct_roll(words) do
    {dice_amount, dice_modifiers} = parse_roll_options(words)
    result = roll_construct_dice({dice_amount, dice_modifiers})

    result_to_string_2d(result) <>
      get_success_message(
        count_successes_2d(result),
        count_ones_first_rolls(result),
        dice_amount
      )
  end

  def parse_dice_notation(text) do
    result = String.split(text, "d")
    {amount, _} = result |> hd() |> Integer.parse()
    {sides, _} = result |> tl() |> hd() |> Integer.parse()
    {amount, sides}
  end

  def roll_x_y_sided_dice({amount, sides}) do
    if amount == 0 do
      []
    else
      [Enum.random(1..sides) | roll_x_y_sided_dice({amount - 1, sides})]
    end
  end

  defp normal_dice_result_to_string(result) do
    if Enum.count(result) == 1 do
      Integer.to_string(hd(result))
    else
      Integer.to_string(hd(result)) <> " | " <> normal_dice_result_to_string(tl(result))
    end
  end

  defp get_success_message(successes, ones, dice_amount) do
    crit_fail = ones >= Float.round(dice_amount / 2)

    part_one =
      cond do
        successes == 0 -> "\nYou had **no** Successes!"
        successes == 1 -> "\nYou had **1** Success!"
        true -> "\nYou had **" <> Integer.to_string(successes) <> "** Successes!"
      end

    part_two =
      cond do
        crit_fail -> "\nWell that's a **critical** failure!"
        successes >= 5 -> "\nWell that's an **exceptional** success!"
        true -> ""
      end

    part_one <> part_two
  end

  defp result_to_string_2d(result) do
    cond do
      Enum.empty?(result) -> ""
      Enum.count(result) == 1 -> "[" <> result_to_string_1d(hd(result)) <> "]"
      true -> "[" <> result_to_string_1d(hd(result)) <> "] " <> result_to_string_2d(tl(result))
    end
  end

  defp result_to_string_1d(result) do
    if Enum.count(result) == 1 do
      Integer.to_string(hd(result))
    else
      Integer.to_string(hd(result)) <> ">" <> result_to_string_1d(tl(result))
    end
  end

  defp count_ones_first_rolls(result) do
    if Enum.empty?(result) do
      0
    else
      if hd(hd(result)) == 1 do
        1 + count_ones_first_rolls(tl(result))
      else
        count_ones_first_rolls(tl(result))
      end
    end
  end

  defp count_successes_2d(result) do
    if Enum.empty?(result) do
      0
    else
      count_successes_1d(hd(result)) + count_successes_2d(tl(result))
    end
  end

  defp count_successes_1d(result) do
    Enum.count(result, fn x -> x >= 8 end)
  end

  def roll_construct_dice({dice_amount, dice_modifiers}) do
    if dice_amount > 0 do
      [
        roll_construct_die(dice_modifiers)
        | roll_construct_dice({dice_amount - 1, dice_modifiers})
      ]
    else
      []
    end
  end

  def roll_construct_die(dice_modifiers) do
    number = Enum.random(1..10)
    {reroll?, new_modifiers} = should_reroll_number(number, dice_modifiers)

    if reroll? do
      [number | roll_construct_die(new_modifiers ++ dice_modifiers)]
    else
      [number]
    end
  end

  defp should_reroll_number(number, dice_modifiers) do
    cond do
      :no_reroll in dice_modifiers ->
        {false, []}

      number == 10 ->
        {true, []}

      :nine_again in dice_modifiers && number >= 9 ->
        {true, []}

      :eight_again in dice_modifiers && number >= 8 ->
        {true, []}

      :rote_quality in dice_modifiers && :rote_quality_used not in dice_modifiers ->
        {true, [:rote_quality_used]}

      true ->
        {false, []}
    end
  end

  @spec parse_roll_options(nonempty_maybe_improper_list) :: {integer, list}
  defp parse_roll_options(words) do
    {dice_amount, ""} = Integer.parse(hd(words))

    if Enum.count(words) < 2 do
      {dice_amount, []}
    else
      dice_modifier_string = hd(tl(words))

      dice_modifiers =
        []
        |> check_nine_again(dice_modifier_string)
        |> check_eight_again(dice_modifier_string)
        |> check_rote_quality(dice_modifier_string)
        |> check_no_reroll(dice_modifier_string)

      {dice_amount, dice_modifiers}
    end
  end

  defp check_nine_again(dice_modifiers, dice_modifier_string) do
    if dice_modifier_string =~ "9" do
      [:nine_again | dice_modifiers]
    else
      dice_modifiers
    end
  end

  defp check_eight_again(dice_modifiers, dice_modifier_string) do
    if dice_modifier_string =~ "8" do
      [:eight_again | List.delete(dice_modifiers, :nine_again)]
    else
      dice_modifiers
    end
  end

  defp check_rote_quality(dice_modifiers, dice_modifier_string) do
    if dice_modifier_string =~ "r" do
      [:rote_quality | dice_modifiers]
    else
      dice_modifiers
    end
  end

  defp check_no_reroll(dice_modifiers, dice_modifier_string) do
    if dice_modifier_string =~ "n" do
      [:no_reroll]
    else
      dice_modifiers
    end
  end
end
