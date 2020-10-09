defmodule GameOfLife.Scene.Field do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  import Scenic.Components

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

    g = build_up(@graph, xline, yline, xline, yline)
    state = %{
      graph: g,
      viewport: opts[:viewport]
    }
    {:ok, state, push: g}

  end

 @doc """
  Verarbeitet die Eingabe eines Buttons.

  `{:click, z::Zelle.t()}`
  Event auf dem Spielfeldraster.
  Zelle.t() wird dem Zellautomaten übergeben updatet die GUI


  `{:click, :next_step}`
  Lässt den Automaten den neuen Zustand berechnen und
  die GUI den neuen State annehmen.

  `{:click, :intervall}`
  Gibt den Zellautomaten dass Signal automatisch weiter zu laufen
  oder aufzuhören. Updatete den Button entsprechend.
  Kein Update des Feldes.
  """
  @spec filter_event({:click , z ::Zelle.t()}, from ::pid(), state::term())
  :: {:noreply, state::term(), [push: g::Scenic.Graph.t()]}|{:noreply, state::term(), [push: new_g::Scenic.Graph.t()]}
  def filter_event({:click, z = %Zelle{}}, _from, %{graph: g} = state) do
    send :zellautomat, {:toggel_cell, z, self()}
    receive do
      {:new_map, map} ->
        new_g = refrech_cell(g,map)
        new_state = Map.put(state, :graph , new_g)
        {:noreply, new_state, push: new_g}
      after 0_500 ->
        {:noreply, state, push: g}
        IO.puts("test")
    end
  end

  @spec filter_event({:click , :next_step}, from ::pid(), state::term())
  :: {:noreply, state::term(), [push: g::Scenic.Graph.t()]}|{:noreply, state::term(), [push: new_g::Scenic.Graph.t()]}
  def filter_event({:click, :next_step}, _from, %{graph: g} = state) do
    send :zellautomat, {:new_tick, self()}
    receive do
      {:new_map, map} ->
        new_g = refrech_cell(g,map)
        new_state = Map.put(state, :graph , new_g)
        {:noreply, new_state, push: new_g}
      after 0_500 ->
        {:noreply, state, push: g}
        IO.puts("test")
    end
  end


  @spec filter_event({:click , :intervall}, from ::pid(), state::term())
  :: {:noreply, new_state::term(), [push: g::Scenic.Graph.t()]}
  def filter_event({:click, :intervall}, _from, %{graph: gr} = state) do
    send :zellautomat, {:automatic_tick, true, self()}
    {_t, text} = Graph.get!(gr, :intervall).data
    g = run_stop(text, gr)
    new_state = Map.put(state, :graph , g)
    {:noreply, new_state, push: g}
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
  def build_up(graph, 0, 1, _xline, _yline)do
    graph
  end

  @doc false
  def build_up(graph, 0, y, xline, yline)do
    build_up(graph,xline,y-1,xline, yline)
  end

  @doc """
  Baut das Zellgitter gemäß den Dimensionen auf.

  Funktion erstellt buttons in passenden Größen und Positionen.
  Gibt diesen Graph zum Schluss zurrück
  """
  @spec build_up(graph :: Scenic.Graph.t(), x :: pos_integer(), y :: pos_integer(), xline :: pos_integer(), yline :: pos_integer()) :: Scenic.Graph.t()
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
   Extrahiert Ids aus dem Graph#

   Mit diesen Ids wird change_theme() aufgerufen.
   """
  @spec refrech_cell(graph :: Scenic.Graph.t(), map :: map()) :: Scenic.Graph.t()
   def refrech_cell(graph =%Graph{} , map)do
    id = Map.keys(graph.ids)
    change_theme(id, map, graph)
  end

  @doc """
  Passt den Zustand der Zellen an

  Ändert das Aussehen der Zellen so das sie dem neuen Zustand des Automaten enstsprechen.
  """
  @spec change_theme(id :: list(), map :: map(), g :: Scenic.Graph.t()) :: Scenic.Graph.t()
  def change_theme([],_map, g)do
    g
  end
  def change_theme([id= %Zelle{}|idtail], map, g)do
      wert = Map.get(map,id)
      if wert == 1 do
        #new_g = Graph.modify(g, id, fn  %{styles: st} = x -> %{x | styles: Map.put(st,:theme, :danger)}end)
        new_g = Graph.modify(g, id, &button(&1, "Hallo")) #schnelle Lösung
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
