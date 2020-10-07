defmodule GameOfLife.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  import Scenic.Components

  @text_size 64

  # ============================================================================
  # setup
  @graph Graph.build()
    |> text("Game of Life", id: :text, font_size: @text_size, translate: {480, 80})
    |> text("Reihe", font_size: @text_size,translate: {200, 480-@text_size * 2})
    |> text_field("20", id: :reihe, filter: :number,  translate: {200,480-@text_size})
    |> text("Spalte", font_size: @text_size,translate: {400, 480-@text_size * 2})
    |> text_field("20", id: :spalte, filter: :number,  translate: {400,480-@text_size})
    |> button("Starten", id: :start ,button_font_size: @text_size, translate: {200,480})

  # --------------------------------------------------------

  def init(_, opts) do

    state = %{
      graph: @graph,
      reihe: "20",
      spalte: "20",
      viewport: opts[:viewport]
    }
    {:ok, state, push: @graph}
  end

  def filter_event({:click, :start}, _from, state) do
    IO.inspect(state)
    %{spalte: spalte} = state
    %{reihe: reihe} = state
    zellautomat_pid = spawn(fn -> Zellautomat.init() end)
    send zellautomat_pid,{:set_xy, String.to_integer(reihe), String.to_integer(spalte)}
    %{viewport: vp} = state
    s = GameOfLife.Scene.Field
    ViewPort.set_root(vp, {s, nil})
    {:halt, state}
  end

  def filter_event({:value_changed, :reihe, value},_from, state) do
    new_state = Map.put(state, :reihe, value)
    {:noreply, new_state}
  end
  def filter_event({:value_changed, :spalte, value},_from, state) do
    new_state = Map.put(state, :spalte, value)
    {:noreply, new_state}
  end
end
