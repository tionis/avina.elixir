defmodule Avina.Data.Store do
  # TODO enforce TTL on all values except permanent user_data

  defp get_conn() do
    # TODO very very inefficient code, to be replaced with solution using for example connection pooling
    {:ok, conn} = Redix.start_link(Application.fetch_env!(:avina, :redis_uri))
    "OK" = Redix.command!(conn, ["AUTH", Application.fetch_env!(:avina, :redis_password)])
    conn
  end

  def get_context(user_id) do
    Redix.command!(get_conn(), ["GET", "user|" <> user_id <> "|context"])
  end

  def set_context(user_id, context) do
    Redix.command!(get_conn(), ["SET", "user|" <> user_id <> "|context", context])
  end

  def get_user_data(user_id, key) do
    Redix.command!(get_conn(), ["GET", "user|" <> user_id <> "|data|" <> key])
  end

  def set_user_data(user_id, key, value) do
    Redix.command!(get_conn(), ["SET", "user|" <> user_id <> "|data|" <> key, value])
  end
end
