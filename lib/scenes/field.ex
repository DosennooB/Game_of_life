defmodule GameOfLife.Scene.Field do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  import Scenic.Components
  import Scenic.Primitives

  @text_size 64
  @offset 50
  @tile_field 900

  @moduledoc """
  Ist die eingentliche Ansicht des Zellautomaten.

  Besteht aus einem Spielfeld aus Buttons, die jeweils eine Zelle representieren.
  Durch den Button "next" kann der nächte Zustand des Spielfeldes berechnet werden.
  Durch "run" wird der der Zelleautomat angegewiesen in Intervallen seinen Zustand neu zu berechnen.
  """

  @graph Graph.build()
  |> button("next",
                id: :next_step,
                height: 100,
                width: 300,
                font_size: @text_size,
                t: {0,900}
              )
  |> button("run",
              id: :intervall,
              height: 100,
              width: 300,
              font_size: @text_size,
              t: {700,900})

@doc """
Initialisierung der Oberfläche

Läst das Gitter anhand der Dimensionen aus Agent **:xy** aufbauen.
"""
  def init(_, opts) do
    ##Damit die Agent gestartet werden können (nicht gut) //TODO
    Process.sleep(300)
    xline = Agent.get(:xy, &Map.get(&1, :x))
    yline = Agent.get(:xy, &Map.get(&1, :y))
    state = %{
      graph: @graph,
      xline: xline,
      yline: yline,
      map: %{},
      viewport: opts[:viewport]
    }
    g = build_rect(@graph, xline, yline, xline, yline, %{})
    {:ok, state, push: g}

  end

 @doc """
  Verarbeitet die Eingabe eines Buttons.


  `{:click, :next_step}`
  Lässt den Automaten den neuen Zustand berechnen.

  `{:click, :intervall}`
  Gibt den Zellautomaten dass Signal automatisch weiter zu laufen
  oder aufzuhören. Updatete den Button entsprechend.
  """

  @spec filter_event({:click , :next_step}, from :: pid(), state :: term())
  :: {:noreply, state::term(), [push: g::Scenic.Graph.t()]}
  def filter_event({:click, :next_step}, _from, state) do
    send :zellautomat, {:new_tick, self()}
    {:noreply, state}
  end


  @spec filter_event({:click , :intervall}, from :: pid(), state :: term())
  :: {:noreply, new_state::term(), [push: g :: Scenic.Graph.t()]}
  def filter_event({:click, :intervall}, _from, %{graph: gr} = state) do
    %{xline: xline} = state
    %{yline: yline} = state
    %{map: map} = state
    send :zellautomat, {:automatic_tick, true, self()}

    {_t, text} = Graph.get!(gr, :intervall).data
    g = run_stop(text, gr)
    g_new = build_rect(g,xline, yline, xline, yline, map)

    new_state = Map.put(state, :graph , g)

    {:noreply, new_state, push: g_new}
  end


  @doc """
  Ändert den Zustand der Zelle auf die geclickt wurde.

  Berrechnet ob der click auf dem Zellgitter getätigt wurde
  und berechnet die Zelle auf der die Interaktion statt fand.
  """
  @spec handle_input({:cursor_button, {:left, :press, 0, {xposo :: pos_integer(), ypos :: pos_integer()}}}, context :: Scenic.ViewPort.Context.t(), state :: term())
  :: {:noreply, state :: term()}
  def handle_input({:cursor_button, {:left, :press, 0, {xposo, ypos}}}, _context, state) do
    xpos = xposo - @offset
    if 0 <= xpos and xpos < @tile_field and 0 <= ypos and ypos < @tile_field do
      %{xline: xline} = state
      %{yline: yline} = state
      x = ceil(xpos/(@tile_field/xline))
      y = ceil(ypos/(@tile_field/yline))
      z = %Zelle{
        x: x,
        y: y
      }
      send :zellautomat, {:toggel_cell, z, self()}
    end
    {:noreply, state}
  end


  def handle_input(_event, _context, state) do
    {:noreply, state}
  end

  @doc """
  Updatet den Graph wenn ein neuer Zustand vom Zellautomaten berechnet wurde.

  Wartet auf eine Message vom Zellautomaten. Diese enthält einenen aktuellen Graphen.
  Der aktuelle Graph wird mit build_rect erstellt. Dieser wird anschießend angezeigt.
  übergibt den State die neuen dimensionen und den Zustand des Zellautomaten.
  """
  @spec handle_info({:new_map, map :: map()}, state :: term()) ::
  {:noreply, new_stat :: term(), [push: g :: Scenic.Graph.t()]}
  def handle_info({:new_map, map}, %{graph: g} = state) do
    xline = Agent.get(:xy,  &Map.get(&1, :x))
    yline = Agent.get(:xy, &Map.get(&1, :y))
    new_g = build_rect(g,xline, yline, xline, yline, map)
    new_state = Map.put(state, :xline , xline)
      |>Map.put(:yline, yline)
      |>Map.put(:map, map)
    {:noreply, new_state, push: new_g}
  end


#Hilfsfunktion für Filterevent intervall
  defp run_stop(text, gr)do
    if text == "run" do
      Graph.modify(gr, :intervall, &button(&1, "stop"))
    else
      Graph.modify(gr, :intervall, &button(&1, "run"))
    end
  end


  @doc false
  def build_rect(graph, 0, 1, _xline, _yline, _map)do
    graph
  end

  @doc false
  def build_rect(graph, 0, y, xline, yline, map)do
    build_rect(graph, xline, y-1, xline, yline, map)
  end

  @doc """
  Baut das Zellgitter mit den jeweiligen state des Zellautomaten auf.

  Funktion erstellt Rechtecke in passenden Größen und Positionen gemäß des State des Zellautomaten.
  """
  @spec build_rect(graph :: Scenic.Graph.t(), x :: pos_integer(), y :: pos_integer(), xline :: pos_integer(), yline :: pos_integer(), map :: map()) :: Scenic.Graph.t()
  def build_rect(graph =%Graph{},x, y, xline, yline, map)do
    z = %Zelle{
      x: x,
      y: y
    }
    n = Map.get(map, z, 0)
    cond do
      n == 1 ->
        g = graph
        |>rect({@tile_field/xline, @tile_field/yline}, fill: :black, translate: {@tile_field / xline * (x-1) + @offset, @tile_field / yline * (y-1)})
        build_rect(g, x-1, y, xline, yline, map)
      true ->
        g = graph
        |>rect({@tile_field/xline, @tile_field/yline}, fill: :white, stroke: {1, :black}, translate: {@tile_field / xline * (x-1) + @offset, @tile_field / yline * (y-1)})
        build_rect(g, x-1, y, xline, yline, map)
    end
  end
end
