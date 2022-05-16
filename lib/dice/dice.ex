defmodule Glyph.Dice do
  def roll_one_y_sided_die(sides) do
    Enum.random(1..sides)
  end

  def roll_x_y_sided_dice({amount, sides}) do
    if amount == 0 do
      []
    else
      [roll_one_y_sided_die(sides) | roll_x_y_sided_dice({amount - 1, sides})]
    end
  end

  def roll_construct_die(dice_modifiers) do
    number = roll_one_y_sided_die(10)
    {reroll?, new_modifiers} = should_reroll_number(number, dice_modifiers)

    if reroll? do
      [number | roll_construct_die(new_modifiers ++ dice_modifiers)]
    else
      [number]
    end
  end

  def roll_shadowrun_die(is_edge) do
    number = roll_one_y_sided_die(6)

    if is_edge do
      if(number == 6) do
        [number | roll_shadowrun_die(is_edge)]
      else
        [number]
      end
    else
      [number]
    end
  end

  def should_reroll_number(number, dice_modifiers) do
    cond do
      :no_reroll in dice_modifiers ->
        {false, []}

      number == 10 ->
        {true, []}

      :nine_again in dice_modifiers && number >= 9 ->
        {true, []}

      :eight_again in dice_modifiers && number >= 8 ->
        {true, []}

      :seven_again in dice_modifiers && number >= 7 ->
        {true, []}

      :rote_quality in dice_modifiers && :rote_quality_used not in dice_modifiers ->
        {true, [:rote_quality_used]}

      true ->
        {false, []}
    end
  end

  def count_ones_first_rolls(result) do
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

  def count_shadowrun_successes_2d(result) do
    if Enum.empty?(result) do
      0
    else
      count_shadowrun_successes_1d(hd(result)) + count_shadowrun_successes_2d(tl(result))
    end
  end

  def count_shadowrun_successes_1d(result) do
    Enum.count(result, fn x -> x >= 5 end)
  end

  def count_successes_2d(result) do
    if Enum.empty?(result) do
      0
    else
      count_successes_1d(hd(result)) + count_successes_2d(tl(result))
    end
  end

  def count_successes_1d(result) do
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

  def roll_shadowrun_dice({dice_amount, is_edge}) do
    if dice_amount > 0 do
      [roll_shadowrun_die(is_edge) | roll_shadowrun_dice({dice_amount - 1, is_edge})]
    else
      []
    end
  end

  def shadowrun_reroll(last_roll_result, is_edge) do
    Enum.map(last_roll_result, fn roll ->
      case length(roll) do
        1 -> if hd(roll) >= 5, do: roll, else: [hd(roll) | roll_shadowrun_die(is_edge)]
        _ -> roll
      end
    end)
  end
end
