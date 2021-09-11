defmodule Glyph do
  @moduledoc """
  Documentation for `Glyph`.
  """
  use Application

  def start(_type, _args) do
    IO.puts "Starting Glyph Bot..."
    Glyph.Supervisor.start_link([])
  end
end
