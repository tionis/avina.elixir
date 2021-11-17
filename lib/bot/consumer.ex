defmodule Glyph.Bot.Consumer do
  @moduledoc """
  A module that implements all logic that consumes discord events,
  at least for the moment
  """
  use Nostrum.Consumer

  alias Nostrum.Api
  alias Glyph.Dice
  alias Glyph.Data.User
  # alias Glyph.Bot.Commands

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:PRESENCE_UPDATE, {_guild_id, old_presence, new_presence}, _ws_state}) do
    new_status = Map.get(new_presence, :client_status)
    old_status = Map.get(old_presence, :client_status)

    if new_status != old_status do
      case Map.get(Map.get(new_presence, :user), :id) do
        224471834601455626 ->
          cond do
            Map.get(new_status, :desktop, :offline) == :online -> send_admin_message("Joe is online!")
            Map.get(new_status, :mobile, :offline) == :online -> send_admin_message("Joe is online on phone!")
            true -> :noop
          end
          #259076782408335360 ->
          #  cond do
          #    Map.get(new_status, :desktop, :offline) == :online -> send_admin_message("Tionis is online!")
          #    Map.get(new_status, :mobile, :offline) == :online -> send_admin_message("Tionis is online on phone!")
          #    true -> :noop
          #  end
      end
    else
      :noop
    end
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    # This logic of this function could be replaced by
    # multiple "command" functions using pattern matching
    words = String.split(msg.content, " ")

    author_mention = Map.get(msg, :author) |> Nostrum.Struct.User.mention()
    msg_preamble = author_mention <> "\n"

    case hd(words) do
      "/roll" ->
        Api.create_message(
          msg.channel_id,
          msg_preamble <> handle_roll(tl(words))
        )

      "/r" ->
        Api.create_message(
          msg.channel_id,
          msg_preamble <> handle_roll(tl(words))
        )

      "/ping" ->
        Api.create_message(msg.channel_id, msg_preamble <> "pong!")

      "/channel_id" ->
        Api.create_message!(msg.channel_id, "#{msg.channel_id}")

      "/help" ->
        Api.create_message(msg.channel_id, msg_preamble <> get_help())

      "/init" ->
        Api.create_message(
          msg.channel_id,
          msg_preamble <> handle_initiative(tl(words), User.get_id_from_discord_msg(msg))
        )

      "/rollinit" ->
        Api.create_message(msg.channel_id, msg_preamble <> handle_mass_roll(tl(words)))

      "/remindme" ->
        Api.create_message(msg.channel_id, msg_preamble <> "Not implemented yet!")

      _ ->
        :ignore
    end
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    case Map.get(interaction, :data) |> Map.get(:name) do
      "roll" -> handle_roll_interaction(interaction)
      "rollinit" -> handle_mass_roll_interaction(interaction)
      _ -> :ignore
    end
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(event) do
    :noop
  end

  defp send_admin_message(message) do
    Api.create_message!(515128077416923152, message)
  end

  def get_help() do
    # " - /quote - quotator commands" <>
    # " - /remindme $ISO_Date $Text-  sends a reminder with text at ISO Date"
    "Available Commands:\n" <>
      " - /roll - roll construct dice or x y-sided die with the xdy notation\n" <>
      " - /r - shortcut for /roll\n" <>
      " - /init - main command to roll your init\n" <>
      " - /rollinit - roll multiple inits\n" <>
      " - /ping - returns pong"
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
    {:ok, init_list} = User.get_init_list(user_id)

    if init_list do
      Enum.at(init_list, one_based_index - 1)
    else
      "No init modifier saved!"
    end
  end

  defp handle_save_init_mod(words, user_id) do
    init_list =
      Enum.map(words, fn x ->
        {new_value, _} = Integer.to_string(x)
        new_value
      end)

    {:ok} = User.set_init_list(user_id, init_list)
    "Saved your init values:\n" <> List.to_string(init_list)
  end

  defp handle_mass_roll(words) do
    if Enum.count(words) > 2 do
      raise ArgumentError
    else
      {amount, _} = Integer.parse(hd(words))
      {init_mod, _} = Integer.parse(Enum.at(words, 1))
      get_mass_roll_string(amount, init_mod, 1)
    end
  end

  defp get_mass_roll_string(amount, init_mod, index) do
    if amount == 1 do
      get_mass_roll_init_line(amount, index)
    else
      get_mass_roll_init_line(amount, index) <>
        "\n" <> get_mass_roll_string(amount - 1, init_mod, index + 1)
    end
  end

  defp get_mass_roll_init_line(init_mod, index) do
    Integer.to_string(index) <>
      ": " <> Integer.to_string(Dice.roll_one_y_sided_die(10) + init_mod)
  end

  defp handle_mass_roll_interaction(interaction) do
    message = get_answer_for_massroll_interaction(interaction)

    response = %{
      type: 4,
      data: %{
        content: message
      }
    }

    Api.create_interaction_response(interaction, response)
  end

  defp get_answer_for_massroll_interaction(interaction) do
    options = Map.get(interaction, :data) |> Map.get(:options)

    amount =
      Enum.filter(options, fn x -> Map.get(x, :name) == "amount" end)
      |> hd
      |> Map.get(:value)
      |> Integer.to_string()

    init_mods =
      Enum.filter(options, fn x -> Map.get(x, :name) == "init-mods" end)
      |> hd
      |> Map.get(:value)
      |> Integer.to_string()

    handle_mass_roll([amount, init_mods])
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
      Regex.match?(~r/^\d+d\d+$/, hd(words)) ->
        hd(words)
        |> Glyph.Dice_Parser.parse_dice_notation()
        |> Dice.roll_x_y_sided_dice()
        |> normal_dice_result_to_string()

      Regex.match?(~r/^\d+$/, hd(words)) ->
        handle_construct_roll(words)

      Regex.match?(~r/chance/, hd(words)) ->
        handle_chance_die()

      Regex.match?(~r/^one$/, hd(words)) ->
        Dice.roll_x_y_sided_dice({1, 10})
        |> normal_dice_result_to_string()
    end
  end

  defp handle_chance_die() do
    number = Dice.roll_one_y_sided_die(10)
    text = "You rolled a **" <> Integer.to_string(number) <> "**!"

    case number do
      10 -> text <> "\nWell, that's a **success**!"
      1 -> text <> "\nWell, that's a **critical failure**!"
      _ -> text
    end
  end

  def handle_construct_roll(words) do
    {dice_amount, dice_modifiers} = Glyph.Dice_Parser.parse_roll_options(words)
    result = Dice.roll_construct_dice({dice_amount, dice_modifiers})

    result_to_string_2d(result) <>
      get_success_message(
        Dice.count_successes_2d(result),
        Dice.count_ones_first_rolls(result),
        dice_amount
      )
  end

  defp normal_dice_result_to_string(result) do
    case Enum.count(result) do
      1 ->
        Integer.to_string(hd(result))

      _ ->
        normal_dice_result_to_string_inner(result) <> " = " <> Integer.to_string(Enum.sum(result))
    end
  end

  defp normal_dice_result_to_string_inner(result) do
    if Enum.count(result) == 1 do
      Integer.to_string(hd(result))
    else
      Integer.to_string(hd(result)) <> " + " <> normal_dice_result_to_string_inner(tl(result))
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
      Integer.to_string(hd(result)) <> "➔" <> result_to_string_1d(tl(result))
    end
  end
end
