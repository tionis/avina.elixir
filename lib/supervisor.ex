defmodule Glyph.Supervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [Glyph.Bot.Consumer]
    :ets.new(:glyph_init_mod, [:named_table, :public]) # TODO: put this into its own process
    Supervisor.init(children, strategy: :one_for_one)
  end
end
