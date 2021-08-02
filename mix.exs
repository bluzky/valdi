defmodule Valdi.MixProject do
  use Mix.Project

  def project do
    [
      app: :valdi,
      version: "0.1.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      name: "Valdi",
      description: description(),
      source_url: "https://github.com/onpointvn/valdi",
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs() do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp package() do
    [
      maintainers: ["Dung Nguyen"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/onpointvn/valdi"}
    ]
  end

  defp description() do
    """
    Simple data validation for Elixir
    """
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end
end
