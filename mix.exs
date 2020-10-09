defmodule GameOfLife.MixProject do
  use Mix.Project

  def project do
    [
      app: :game_of_life,
      version: "0.2.0",
      elixir: "~> 1.7",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      #name: "GameOfLife",
      #main: "GameOfLife",
      source_url: "https://github.com/DosennooB/Game_of_life",
      docs: [
        main: "GameOfLife", # The main page in the docs
        extras: doc()
      ]
    ]
  end

  defp doc do
    [
      "doc_md/GameOfLife.md",
      "doc_md/Installation.md",
      "doc_md/Bedienung.md",
      "doc_md/Anforderungen.md",
      "doc_md/KritikundÄnderungen.md"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {GameOfLife, []},
      extra_applications: [:crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic, "~> 0.10"},
      {:scenic_driver_glfw, "~> 0.10", targets: :host},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
    ]
  end
end
