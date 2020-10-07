defmodule Zellautomat do

  def init() do
    Process.register(self(), :zellautomat)
    receive do
      {:set_xy, x,y} ->
        Agent.start_link(fn-> %{:x=>x, :y=> y, :toggel => false} end, name: :xy)
        Agent.start_link(fn -> %{} end, name: :akt_map)
        Agent.start_link(fn -> %{} end, name: :new_map)
        Agent.start_link(fn -> [] end, name: :todo)
        automat()

    end
  end

  def automat() do
    receive do
      {:toggel_cell, zelle, pid} ->
        Agent.update(:akt_map, fn map ->
          Map.update(map, zelle, 1 , &(rem(&1+1,2)))
        end)
        send pid, {:new_map, Agent.get(:akt_map, fn map -> map end)}
        automat()

      {:new_tick, pid} ->
        tick()
        send pid, {:new_map, Agent.get(:akt_map, fn map -> map end)}
        automat()

      {:automatic_tick, toggel , pid} ->
        if toggel do
         t =  Agent.get(:xy, &Map.get(&1, :toggel))
         Agent.update(:xy, fn map -> Map.put(map, :toggel, !t)end)
        end
        t  = Agent.get(:xy, &Map.get(&1, :toggel))
        if t do
          tick()
          Process.send_after(self() , {:automatic_tick, false, pid}, 1000)
        end
        send pid, {:new_map, Agent.get(:akt_map, fn map -> map end)}
        automat()
      end
  end

  def tick() do
    map = Agent.get(:akt_map, fn map -> map end)
    Enum.map(map, fn{k,_v}-> todo_zellen_around(k) end)
    zellentodo = Agent.get(:todo, fn list -> list end)
    Enum.map(zellentodo, fn k -> alive_in_new_map(k) end)

    nmap = Agent.get(:new_map, fn map -> map end)
    Agent.update(:akt_map, fn _oldmap -> nmap end)
    Agent.update(:new_map, fn _old -> %{} end)
    Agent.update(:todo, fn _list -> [] end)
  end

  def todo_zellen_around(k = %Zelle{}) do
    xline = Agent.get(:xy, &Map.get(&1, :x))
    yline = Agent.get(:xy, &Map.get(&1, :y))
    todo_zellen_around( xline, yline, [1,1,1,0,0,0,-1,-1,-1],[1,0,-1,1,0,-1,1,0,-1] ,k)
  end

  def todo_zellen_around( _xline, _yline, [], [], _k) do
    true
  end

  def todo_zellen_around( xline, yline, [hx|tx], [hy|ty], k) do
    x = hx + k.x
    y = hy + k.y
    cond do
      0 < x and x <= xline and 0 < y and y <= yline ->
        nzelle = %Zelle{
          x: x,
          y: y
        }
        Agent.update(:todo, fn list -> [nzelle|list] end)
        todo_zellen_around( xline, yline, tx, ty, k)
      true ->
        todo_zellen_around( xline, yline, tx, ty, k)
      end
  end

  def alive_in_new_map(k = %Zelle{}) do
    xline = Agent.get(:xy, &Map.get(&1, :x))
    yline = Agent.get(:xy, &Map.get(&1, :y))
    wert =  around_wert(0, xline,yline, [1,1,1,0,0,-1,-1,-1],[1,0,-1,1,-1,1,0,-1] ,k)
    zellenwert = Agent.get(:akt_map, &Map.get_lazy(&1, k, fn -> 0 end))
    cond do
      zellenwert == 1 ->
        if wert == 2 or wert == 3 do
          Agent.update(:new_map, &Map.put(&1, k, 1))
        end
      zellenwert == 0 ->
        if wert == 3 do
          Agent.update(:new_map, &Map.put(&1, k, 1))
        end
    end
  end

  def around_wert(wert, _xline, _yline, [], [], _k) do
     wert
  end
  def around_wert(wert, xline, yline, [hx|tx], [hy|ty], k = %Zelle{}) do
     x = hx + k.x
     y = hy + k.y
    cond do
      0 < x  and x <= xline and 0 < y and y <= yline ->
        nachtbar = %Zelle{
          x: x,
          y: y
        }
        Agent.get(:akt_map, &Map.get_lazy(&1, nachtbar, fn -> 0 end)) + wert
        |>around_wert(xline, yline,tx,ty,k)
      true ->
        around_wert(wert, xline, yline, tx, ty, k)
    end
  end
end
