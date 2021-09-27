defmodule Glyph.Data.User do
  def get_init_list(user_id) do
    # TODO
    init_list = :ets.lookup(:glyph_init_mod, user_id)
    {:ok, init_list}
  end

  def set_init_list(user_id, init_list) do
    # TODO
    :ets.insert(:glyph_init_mod, {user_id, init_list})
    {:ok}
  end

  def get_id_from_discord_msg(msg) do
    "dc:" <> Integer.to_string(Map.get(msg, :author) |> Map.get(:id))
  end
end
