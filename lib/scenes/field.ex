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


  def init(_, opts) do
    Process.sleep(300)
    xline = Agent.get(:xy, &Map.get(&1, :x))
    yline = Agent.get(:xy, &Map.get(&1, :y))

    g = build_up(@graph, xline, yline, xline, yline)
    #g = Scenic.Component.Button.add_to_graph(@graph, "shgs")
    #g = Graph.add(@graph,b)
    state = %{
      graph: g,
      viewport: opts[:viewport]
    }
    {:ok, state, push: g}

  end

  def filter_event({:click, z = %Zelle{}}, _from, %{graph: g} = state) do
    send :zellautomat, {:toggel_cell, z, self()}
    receive do
      {:new_map, map} ->
        new_g = refrech_cell(g,map)
        {:noreply, state, push: new_g}
      after 0_800 ->
        {:noreply, state, push: g}
    end
   #{:noreply, state, push: g}
  end

  def filter_event({:click, :next_step}, _from, %{graph: g} = state) do
    send :zellautomat, {:new_tick, self()}
    receive do
      {:new_map, map} ->
        new_g = refrech_cell(g,map)
        {:noreply, state, push: new_g}
      after 0_800 ->
        {:noreply, state, push: g}
    end
  end

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


  def run_stop(text, gr)do
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
  def build_up(graph =%Graph{}, x, y, xline, yline)do

    z = %Zelle{
      x: x,
      y: y
    }
    g = graph
    |>button("", id: z,theme: :dark, height: @tile_field / yline, width: @tile_field / xline, t: {@tile_field / xline * (x-1) +@offset, @tile_field / yline * (y-1)} )
    #g = Scenic.Component.Button.add_to_graph(graph,"hallo", id: z, translate: {x*1 ,y*1 } )
     #|>button("", id: z,hight: @tile_field / yline, width: @tile_field / xline, t: {@tile_field / xline * (x-1), @tile_field / yline * (y-1)} )
    build_up(g,x-1,y,xline, yline)
  end

  def refrech_cell(graph =%Graph{} , map)do
    id = Map.keys(graph.ids)
    change_theme(id, map, graph)
  end

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
