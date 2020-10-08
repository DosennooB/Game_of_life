defmodule GameOfLife.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  import Scenic.Components

  @moduledoc """
  Scene wird als erstes aufgerufen.
  In ihr werden die Dimension des Zellautomaten eingegeben.
  Wichtig: Zellen nur in Dimensionen bis maximal 20x20 eingeben.
  In der aktuellen Version eine Limitation des Frameworks
  """

  @text_size 64

  # ============================================================================
  # setup
  @graph Graph.build()
    |> text("Reihe", font_size: @text_size,translate: {200, 480-@text_size * 2})
    |> text_field("20", id: :reihe, filter: :number,  translate: {200,480-@text_size})
    |> text("Spalte", font_size: @text_size,translate: {400, 480-@text_size * 2})
    |> text_field("20", id: :spalte, filter: :number,  translate: {400,480-@text_size})
    |> text("Wichtig maximal Wert ist 20", id: :text, font_size: 24, translate: {200, 480})
    |> button("Starten", id: :start, width: 400 ,button_font_size: @text_size, translate: {200,480+@text_size})

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

  @doc """
  Startet und übergibt den Zellautomaten die Dimensionen.
  Ruft das Hauptfenster auf.
  """
  def filter_event({:click, :start}, _from, state) do
    %{spalte: spalte} = state
    %{reihe: reihe} = state
    zellautomat_pid = spawn(fn -> Zellautomat.init() end)
    send zellautomat_pid,{:set_xy, String.to_integer(reihe), String.to_integer(spalte)}
    %{viewport: vp} = state
    s = GameOfLife.Scene.Field
    ViewPort.set_root(vp, {s, nil})
    {:halt, state}
  end

  @doc """
  Neuer Wert für Reihe im State aktualisiert.
  """
  def filter_event({:value_changed, :reihe, value},_from, state) do
    new_state = Map.put(state, :reihe, value)
    {:noreply, new_state}
  end
  @doc """
  Neuer Wert für Zeile im State akualisiert
  """
  def filter_event({:value_changed, :spalte, value},_from, state) do
    new_state = Map.put(state, :spalte, value)
    {:noreply, new_state}
  end
end
