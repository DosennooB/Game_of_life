defmodule GameOfLife.Scene.Field do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  import Scenic.Components

  @text_size 64
  @offset 50
  @tile_field 900

  @moduledoc """
  Ist das eingentliche Spiel Feld.
  besteht aus einem Spielfeld aus Buttons die jeweils eine Zelle representieren.

  Durch den Button "next" kann der nächte Zustand des Spielfeldes berechnet werden.
  Durch "run" wird der der Zelleautomat gegewisen in Intervallen seinen Zustand neu zu berechnen.
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
Baut das Gitter auf anhand der Dimensionen aus Agent :xy
"""
  def init(_, opts) do
    ##Damit die Agent gestartet werden können (nicht gut) //TODO
    Process.sleep(300)
    xline = Agent.get(:xy, &Map.get(&1, :x))
    yline = Agent.get(:xy, &Map.get(&1, :y))

    g = build_up(@graph, xline, yline, xline, yline)
    state = %{
      graph: g,
      viewport: opts[:viewport]
    }
    {:ok, state, push: g}

  end


  @doc """
  Event auf dem Spielfeldraster.
  Zellen_struct wird als id zurück gegeben.
  Dies wird den Zellautomaten übergeben.
  """
  def filter_event({:click, z = %Zelle{}}, _from, %{graph: g} = state) do
    send :zellautomat, {:toggel_cell, z, self()}
    receive do
      {:new_map, map} ->
        new_g = refrech_cell(g,map)
        {:noreply, state, push: new_g}
      after 0_500 ->
        {:noreply, state, push: g}
    end
   #{:noreply, state, push: g}
  end
  @doc """
  lässt den automaten den neuen Status berechnen und
  die GUI den neuen State annehmen.
  """
  def filter_event({:click, :next_step}, _from, %{graph: g} = state) do
    send :zellautomat, {:new_tick, self()}
    receive do
      {:new_map, map} ->
        new_g = refrech_cell(g,map)
        {:noreply, state, push: new_g}
      after 0_500 ->
        {:noreply, state, push: g}
    end
  end

  @doc """
  Gibt den Zellautomaten dass Signal automatisch weiter zu laufen
  oder aufzuhören. Updatete den Button entsprechend.
  """
  def filter_event({:click, :intervall}, _from, %{graph: gr} = state) do
    send :zellautomat, {:automatic_tick, true, self()}
    {_t, text} = Graph.get!(gr, :intervall).data
    IO.inspect(text)
    g = run_stop(text, gr)
    new_state = Map.put(state, :graph , g)
    receive do
      {:new_map, map} ->
        new_g = refrech_cell(g,map)
        {:noreply, new_state, push: new_g}
      after 0_800 ->
        {:noreply, new_state, push: g}
    end
  end

#Hilfsfunktion für Filterefent intervall
  defp run_stop(text, gr)do
    if text == "run" do
      Graph.modify(gr, :intervall, &button(&1, "stop"))
    else
      Graph.modify(gr, :intervall, &button(&1, "run"))
    end
  end

  def build_up(graph, 0, 1, _xline, _yline)do
    graph
  end

  def build_up(graph, 0, y, xline, yline)do
    build_up(graph,xline,y-1,xline, yline)
  end

  @doc """
  Baut das Zellgitter gemäß der Dimensionen auf.
  Ich erstellt buttons in Richtigen Größen und an den richtigen Positionen.
  gibt diesen Graf zum Schluss zurrück
  """
  def build_up(graph =%Graph{}, x, y, xline, yline)do
    z = %Zelle{
      x: x,
      y: y
    }
    g = graph
    |>button("", id: z,theme: :dark, height: @tile_field / yline, width: @tile_field / xline, t: {@tile_field / xline * (x-1) +@offset, @tile_field / yline * (y-1)} )
    build_up(g,x-1,y,xline, yline)
  end

   @doc """
   Alle ids der Componenten in einem Graf werden ausgegeben und an change_theme
   übergeben
   """
  def refrech_cell(graph =%Graph{} , map)do
    id = Map.keys(graph.ids)
    change_theme(id, map, graph)
  end

  @doc """
  Ändert das Aussehen der Zellen so das sie dem Zustand des neuen
  Automaten enstsprechen.
  """
  def change_theme([],_map, g)do
    g
  end
  def change_theme([id= %Zelle{}|idtail], map, g)do
      wert = Map.get(map,id)
      if wert == 1 do
        new_g = Graph.modify(g, id, &button(&1, "hallo"))
        change_theme(idtail, map, new_g)
      else
        new_g = Graph.modify(g, id, &button(&1, ""))
        change_theme(idtail, map, new_g)
      end
  end
  def change_theme([_id|idtail], map, g) do
    change_theme(idtail, map, g)
  end

end
