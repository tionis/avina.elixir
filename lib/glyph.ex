defmodule Avina do
  @moduledoc """
  Documentation for `Avina`.
  """
  use Application

  def start(_type, _args) do
    IO.puts "Starting Avina Bot..."
    Avina.Supervisor.start_link([])
  end
end
