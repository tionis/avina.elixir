defmodule Glyph.MixProject do
  use Mix.Project

  def project do
    [
      app: :glyph,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Glyph, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
	    #{:nostrum, "~> 0.4"},
      {:nostrum, github: "Kraigie/nostrum"},
      {:redix, "~> 1.1"},
      {:json, "~> 1.4"}
      #{:castore, ">= 0.0.0"}
    ]
  end

end
