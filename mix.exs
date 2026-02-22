defmodule Blighty.MixProject do
  use Mix.Project

  def project do
    [
      app: :blighty,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Mutation testing for Elixir. That which doesn't kill you makes you stronger.",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/improvingjef/blighty"}
    ]
  end
end
