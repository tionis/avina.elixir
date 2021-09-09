defmodule Glyph do
  @moduledoc """
  Documentation for `Glyph`.
  """
  use Application

  def start(_type, _args) do
    IO.puts "Starting Glyph Bot..."
    GlyphSupervisor.start_link([])
  end

  @doc """
  Hello world.

  ## Examples

      iex> Glyph.hello()
      :world

  """
  def hello do
    :world
  end

end
