defmodule GameOfLife.Scene.Field do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  import Scenic.Components
  import Scenic.Primitives

  @text_size 50
  @offset 00
  @tile_field 900

  @muster_einezelle [{0, 0}]
  @muster_blinker [{0, 0}, {1, 0}, {2, 0}]
  @muster_uhr [{0, 0}, {1, 0}, {2, -1}, {2, 1}, {3, 1}, {1, 2}]
  @muster_kroete [{0, 0}, {0, 1}, {0, 2}, {1, 1}, {1, 2}, {1, 3}]
  @muster_gleiter [{0, 0}, {1, 0}, {2, 0}, {2, -1}, {1, -2}]
  @moduledoc """
  Ist die Ansicht des Zellautomaten.

  Besteht aus einem Feld aus Zellen und mehreren Parametern die sich zur Laufzeit verändern lassen.
  """

  @graph Graph.build()
         |> button("next",
           id: :next_step,
           height: 100,
           width: 300,
           font_size: @text_size,
           t: {0, 900}
         )
         |> button("run",
           id: :intervall,
           height: 100,
           width: 300,
           font_size: @text_size,
           t: {600, 900}
         )
         |> text("Torisch:",
           height: 100,
           width: 300,
           text_align: :left,
           font_size: @text_size,
           t: {1000, 100}
         )
         |> toggle(
           false,
           height: 100,
           width: 300,
           id: :toggle_torisch,
           thumb_radius: @text_size / 4,
           t: {1200, 100}
         )
         |> text("Speed",
           height: 100,
           font_size: @text_size,
           t: {1000, 200}
         )
         |> slider(
           {{1, 500}, 500},
           height: 100,
           width: 250,
           id: :tick_rate,
           t: {1150, 200}
         )
         |> text("Dimension XY",
           height: 100,
           wigth: 300,
           font_size: @text_size,
           t: {1000, 300}
         )
         |> slider(
           {{1, 200}, 20},
           height: 100,
           width: 400,
           id: :dimension_xy,
           t: {1000, 350}
         )
         |> text("Objekt Auswahl",
           height: 100,
           width: 300,
           font_size: @text_size,
           t: {1000, 400}
         )
         |> dropdown(
           {[
              {"Eine Zelle", :eine_zelle},
              {"Blinker", :blinker},
              {"Uhr", :uhr},
              {"Kröte", :kroete},
              {"Gleiter", :gleiter}
            ], :eine_zelle},
           height: 75,
           width: 400,
           font_size: @text_size,
           id: :dropdown_objekte,
           t: {1000, 450}
         )
         |> button("crash Gui",
           id: :crash_GUI,
           height: 100,
           width: 200,
           font_size: @text_size,
           t: {1000, 900}
         )
         |> button("crash Zellautomat",
           id: :crash_Zellautomat,
           height: 100,
           width: 200,
           font_size: @text_size,
           t: {1250, 900}
         )

  @doc """
  Initialisierung der Oberfläche

  Läst das Gitter anhand der Dimensionen aus Agent **:xy** aufbauen.
  """
  def init(_, opts) do
    Process.register(self(), :field)

    # params = XY.get_all()
    # methoden schreiben die das element aus der Liste nehmen und den Graph verändern.

    map = Zustand.get_akt_map()
    g = build_rect(@graph, map)

    state = %{
      graph: @graph,
      dropdown_objekte: :eine_zelle,
      map: map,
      viewport: opts[:viewport]
    }

    {:ok, state, push: g}
  end

  @doc """
  Verarbeitet die Eingabe der Events.

  `{:value_changed, :toggle_torisch, bool}`
  Andert den Parameter für Torisch im Zellautomat.

  `{:value_changed, :tick_rate, value}`
  Ändert den Parameter für tick rate im Zellautomat.

  `{:value_changed, :dimension_xy, value}`
  Ändert den Parameter für die Dimension im Zellautomat.

  `{value_changed, :dropdown_objekte, value}`
  Ändert den State für die Angabe welches Muster auf dem Zellautomaten gezeichnet wird.

  `{:click, :next_step}`
  Lässt den Automaten den neuen Zustand berechnen.

  `{:click, :intervall}`
  Gibt den Zellautomaten dass Signal automatisch weiter zu laufen
  oder aufzuhören. Updatete den Button entsprechend.

  `{:click, :crash_Zellautomat}
  Lässt den Zellautomaten abstürzen.

  `{:click, :crash_GUI}`
  Lässt die Gui abstürzen.

  """
  def filter_event({:value_changed, :toggle_torisch, bool}, _from, state) do
    send(:zellautomat, {:set_torisch, bool})
    {:noreply, state}
  end

  def filter_event({:value_changed, :tick_rate, value}, _from, state) do
    send(:zellautomat, {:set_tick_rate, value})
    {:noreply, state}
  end

  def filter_event({:value_changed, :dimension_xy, value}, _from, state) do
    send(:zellautomat, {:set_xy, value, value})
    {:noreply, state}
  end

  def filter_event({:value_changed, :dropdown_objekte, value}, _from, state) do
    new_state = Map.put(state, :dropdown_objekte, value)
    {:noreply, new_state}
  end

  @spec filter_event({:click, :next_step}, from :: pid(), state :: term()) ::
          {:noreply, state :: term(), [push: g :: Scenic.Graph.t()]}
  def filter_event({:click, :next_step}, _from, state) do
    send(:zellautomat, {:new_tick})
    {:noreply, state}
  end

  @spec filter_event({:click, :intervall}, from :: pid(), state :: term()) ::
          {:noreply, new_state :: term(), [push: g :: Scenic.Graph.t()]}
  def filter_event({:click, :intervall}, _from, %{graph: gr} = state) do
    %{map: map} = state
    send(:zellautomat, {:automatic_tick, true})

    {_t, text} = Graph.get!(gr, :intervall).data
    g = run_stop(text, gr)
    g_new = build_rect(g, map)

    new_state = Map.put(state, :graph, g)

    {:noreply, new_state, push: g_new}
  end

  def filter_event({:click, :crash_Zellautomat}, _from, state) do
    Process.exit(:zellautomat, :kill)
    {:noreply, state}
  end

  def filter_event({:click, :crash_GUI}, _from, state) do
    Process.exit(self(), 0)
    {:noreply, state}
  end

  @doc """
  Ändert den Zustand der Zelle auf die geclickt wurde.

  Berrechnet ob der click auf dem Zellgitter getätigt wurde
  und berechnet die Zelle auf der die Interaktion statt fand.
  """
  @spec handle_input(
          {:cursor_button, {:left, :press, 0, {xposo :: pos_integer(), ypos :: pos_integer()}}},
          context :: Scenic.ViewPort.Context.t(),
          state :: term()
        ) ::
          {:noreply, state :: term()}
  def handle_input(
        {:cursor_button, {:left, :press, 0, {xposo, ypos}}},
        _context,
        %{dropdown_objekte: muster} = state
      ) do
    xpos = xposo - @offset

    if 0 <= xpos and xpos < @tile_field and 0 <= ypos and ypos < @tile_field do
      xline = XY.get(:x)
      yline = XY.get(:y)
      x = ceil(xpos / (@tile_field / xline))
      y = ceil(ypos / (@tile_field / yline))

      z = %Zelle{
        x: x,
        y: y
      }

      z_list = cell_pattern(z, muster)
      send(:zellautomat, {:toggel_cell, z_list})
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
  übergibt den State den neuen Zustand des Zellautomaten.
  """
  @spec handle_info({:new_map, map :: map()}, state :: term()) ::
          {:noreply, new_stat :: term(), [push: g :: Scenic.Graph.t()]}
  def handle_info({:new_map, map}, %{graph: g} = state) do
    new_g = build_rect(g, map)
    new_state = Map.put(state, :map, map)
    {:noreply, new_state, push: new_g}
  end

  # Hilfsfunktion für Filterevent intervall
  defp run_stop(text, gr) do
    if text == "run" do
      Graph.modify(gr, :intervall, &button(&1, "stop"))
    else
      Graph.modify(gr, :intervall, &button(&1, "run"))
    end
  end

  @spec cell_pattern(z :: Zelle.t(), muster :: atom()) :: [Zelle.t()]
  def cell_pattern(z, muster) do
    cond do
      muster == :eine_zelle ->
        Enum.map(@muster_einezelle, fn {x, y} ->
          %Zelle{
            x: x + z.x,
            y: y + z.y
          }
        end)

      muster == :blinker ->
        Enum.map(@muster_blinker, fn {x, y} ->
          %Zelle{
            x: x + z.x,
            y: y + z.y
          }
        end)

      muster == :uhr ->
        Enum.map(@muster_uhr, fn {x, y} ->
          %Zelle{
            x: x + z.x,
            y: y + z.y
          }
        end)

      muster == :kroete ->
        Enum.map(@muster_kroete, fn {x, y} ->
          %Zelle{
            x: x + z.x,
            y: y + z.y
          }
        end)

      muster == :gleiter ->
        Enum.map(@muster_gleiter, fn {x, y} ->
          %Zelle{
            x: x + z.x,
            y: y + z.y
          }
        end)
    end
  end

  @doc """
  Baut das Zellgitter mit den jeweiligen state des Zellautomaten auf.

  Ruft Funktionen für das erstellen des Gitters und zeichnen der aktiven Zellen auf.
  """
  @spec build_rect(graph :: Scenic.Graph.t(), map :: map()) :: Scenic.Graph.t()
  def build_rect(graph, map) do
    xline = XY.get(:x)
    yline = XY.get(:y)

    graph
    |> rect({@tile_field, @tile_field}, fill: :white, translate: {@offset, 0})
    |> build_lines_h(yline, yline)
    |> build_lines_v(xline, xline)
    |> fill_rect(xline, yline, Map.to_list(map))
  end

  @doc false
  def fill_rect(graph = %Graph{}, _xline, _yline, []) do
    graph
  end

  @doc """
  Zeichnet die aktiven Zellen.

  Die Zellen in der Liste werden schwarz gezeichnet.
  """
  @spec fill_rect(graph :: Scenic.Graph.t(), xline :: pos_integer(), yline :: pos_integer(), list) ::
          Scenic.Graph.t()
  def fill_rect(graph = %Graph{}, xline, yline, [{zelle, wert} = _head | tail]) do
    if wert == 1 do
      g =
        graph
        |> rect({@tile_field / xline, @tile_field / yline},
          fill: :black,
          translate:
            {@tile_field / xline * (zelle.x - 1) + @offset, @tile_field / yline * (zelle.y - 1)}
        )

      fill_rect(g, xline, yline, tail)
    else
      fill_rect(graph, xline, yline, tail)
    end
  end

  @doc """
  Zeichent horizontale Linien

  Die Linien erzeugen die passenden Rechtecke die dem State des Zellautomaten passen.
  """
  @spec build_lines_h(graph :: Scenic.Graph.t(), y :: pos_integer(), yline :: pos_integer()) ::
          Scenic.Graph.t()
  def build_lines_h(graph = %Graph{}, y, yline) do
    g =
      graph
      |> line(
        {{@offset, @tile_field / yline * y}, {@offset + @tile_field, @tile_field / yline * y}},
        fill: :black
      )

    if y > 0 do
      build_lines_h(g, y - 1, yline)
    else
      g
    end
  end

  @doc """
  Zeichent vertikale Linien

  Die Linien erzeugen die passenden Rechtecke die dem State des Zellautomaten passen.
  """
  @spec build_lines_v(graph :: Scenic.Graph.t(), x :: pos_integer(), xline :: pos_integer()) ::
          Scenic.Graph.t()
  def build_lines_v(graph = %Graph{}, x, xline) do
    g =
      graph
      |> line(
        {{@offset + @tile_field / xline * x, 0},
         {@offset + @tile_field / xline * x, @tile_field}},
        fill: :black
      )

    if x > 0 do
      build_lines_v(g, x - 1, xline)
    else
      g
    end
  end
end
