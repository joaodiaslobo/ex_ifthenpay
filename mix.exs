defmodule Ifthenpay.MixProject do
  use Mix.Project

  @app :ifthenpay
  @name "ifthenpay"
  @version "0.1.0"
  @description "ifthenpay API client for Elixir"

  def project do
    [
      app: @app,
      name: @name,
      version: @version,
      description: @description,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  def package do
    [
      name: "ifthenpay",
      maintainers: ["João Lobo"],
      licenses: ["MIT"]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [{:"README.md", [title: "Overview"]}],
      source_ref: "v#{@version}"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 2.2"},
      {:poison, "~> 5.0"},
      # docs
      {:ex_doc, "~> 0.32.1", only: :dev, runtime: false}
    ]
  end
end
