defmodule Zellautomat do
  use GenServer
@moduledoc """
Logic des Zellautomaten.
Die nötigen Paarameter werden in Agents gespeichert.

**Agents:**
- **xy:** hier werden die Dimensionen des Zellautomaten gespeichert
  es wird auch noch gespeichert ob der Automat von selber laufen soll oder nicht
- **akt_map:** Die Werte der zellen werden als 1 und 0 in einer map mit dem Zellenstruct als id gespeichert
  um Platz zu sparen werden nach möglichkeit nur zellen mit 1 gespeichert
- **new_map:** dient als Zwischenspicher bei der Berechnung des neuen Zellautomaten
- **todo:** enthält Zellen die zum nächsten Schritt neu berechnet werden müssen
"""



@doc """
Initialisierung des Automaten.

Starten der Agenten und setzen der Dimensionen für den Zellautomaten.
"""

  def start_link(_opts) do
      GenServer.start_link(__MODULE__, %{}, name: :zellautomat)
  end

  @impl true
  def init(opts) do
    Agent.start_link(fn-> %{:x=>20, :y=> 20, :toggel => false, :torisch => false} end, name: :xy)
      Agent.start_link(fn -> %{} end, name: :akt_map)
      Agent.start_link(fn -> %{} end, name: :new_map)
    {:ok, opts}
  end
  @doc """
  Hauptschleife

  Es werde drei Signale verarbeitet
  die neuen Werte werden über `{:new_map, data :: map()}`
  zurück gegeben.

  - **toggel_cell:**
  Es kann geziehlt eine Zelle an oder aus geschaltet werden,
  abhängig von ihrem aktuellen Zustand. Es können mehrere Zellen gleichzeitig
  verändert werden.


  - **new_tick:**
  Der nächste Zustand des Automaten wird berechnet.

  - **automatic_tick:**
  Alle n Sekunden wird ein neuer Zustand der Zellautomaten berechnet.
  Durch den Parameter toggle kann diese Funktion an oder ausgeschaltet werden.
  Gibt den neuen Zustand zurück.

  - **set_xy:**
  Die Dimensionen des Zellautomaten werden neu gesetzt.
  Kann wärend des Laufenden Programmes geschehen.
  """
  @impl true
  def handle_info({:toggel_cell, z , pid}, state) do
      Enum.map(z, fn zelle ->
        Agent.update(:akt_map, fn map ->
          Map.update(map, zelle, 1 , &(rem(&1+1,2)))
        end)
      end)

      send pid, {:new_map, Agent.get(:akt_map, fn map -> map end)}
      {:noreply, state}
  end

  @impl true
  def handle_info({:set_xy, x,y}, state) do
    Agent.update(:xy, &Map.put(&1, :x, x))
        Agent.update(:xy, &Map.put(&1, :y, y))
        {:noreply, state}
  end

  @impl true
  def handle_info({:new_tick, pid}, state) do
    tick()
        send pid, {:new_map, Agent.get(:akt_map, fn map -> map end)}
        {:noreply, state}
  end

  @impl true
  def handle_info({:automatic_tick, toggel , pid}, state) do
    if toggel do
      t =  Agent.get(:xy, &Map.get(&1, :toggel))
      Agent.update(:xy, fn map -> Map.put(map, :toggel, !t)end)
     end
     t  = Agent.get(:xy, &Map.get(&1, :toggel))
     if t do
       tick()
       send pid, {:new_map, Agent.get(:akt_map, fn map -> map end)}
       Process.send_after(self() , {:automatic_tick, false, pid}, 1000)
     end
     {:noreply, state}
  end

  @spec automat :: no_return()
  def automat() do
    receive do
      #z ist eine Liste aus Zellen
      {:toggel_cell, z , pid} ->
        Enum.map(z, fn zelle ->
          Agent.update(:akt_map, fn map ->
            Map.update(map, zelle, 1 , &(rem(&1+1,2)))
          end)
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
          send pid, {:new_map, Agent.get(:akt_map, fn map -> map end)}
          Process.send_after(self() , {:automatic_tick, false, pid}, 1000)
        end
        automat()

      {:set_xy, x,y} ->
        Agent.update(:xy, &Map.put(&1, :x, x))
        Agent.update(:xy, &Map.put(&1, :y, y))
        automat()
      end
  end

  @doc """
  Lässt den nächsten Zustand des Zellautomaten berechnen.

  Lässten nächten Zustand berechnen und gibt die neuen Werte
  an die Agents weiter. Nur Zellen die den Wert 1 haben oder Nachtbar einer
  Zelle mit dem Wert 1 sind, werden berechnet.
  """
  @spec tick :: :ok
  def tick() do
    map = Agent.get(:akt_map, fn map -> map end)
    Enum.map(map, fn{k,_v}-> todo_zellen_around(k) end)
    zellentodo = Todo.get_list()
    Enum.map(zellentodo, fn k -> alive_in_new_map(k) end)

    nmap = Agent.get(:new_map, fn map -> map end)
    Agent.update(:akt_map, fn _oldmap -> nmap end)
    Agent.update(:new_map, fn _old -> %{} end)
    Todo.dell_list()
  end

  @doc """
  Ermittelt Nachtbarn und die angegebene Zelle.

  Übergibt alle Nachtbarn und die angegebene Zelle,
  dem `:todo` Agent. Es sei den, sie befinden sich auserhalb des Zellautomaten.
  """
  @spec todo_zellen_around(zelle :: Zelle.t()) :: :ok
  def todo_zellen_around(zelle = %Zelle{}) do
    xline = Agent.get(:xy, &Map.get(&1, :x))
    yline = Agent.get(:xy, &Map.get(&1, :y))
    torisch = Agent.get(:xy, &Map.get(&1, :torisch))
    todo_zellen_around( xline, yline, [1,1,1,0,0,0,-1,-1,-1],[1,0,-1,1,0,-1,1,0,-1] ,zelle, torisch)
  end

  @doc false
  def todo_zellen_around( _xline, _yline, [], [], _k, _torisch) do
    :ok
  end

  @doc false
  def todo_zellen_around( xline, yline, [hx|tx], [hy|ty], k, torisch) do
    x = hx + k.x
    y = hy + k.y
    cond do
      torisch == false and 0 < x and x <= xline and 0 < y and y <= yline ->
        nzelle = %Zelle{
          x: x,
          y: y
        }
        Todo.add_to_list(nzelle)
        todo_zellen_around( xline, yline, tx, ty, k, torisch)
      torisch == true ->
        nzelle = %Zelle{
          x: torus_func(x, xline),
          y: torus_func(y, yline)
        }
        Todo.add_to_list(nzelle)
        todo_zellen_around( xline, yline, tx, ty, k, torisch)
      true ->
        todo_zellen_around( xline, yline, tx, ty, k, torisch)
      end
  end

  @doc """
  Enscheidet über den Zustand der Zelle

  Überprüft ob die Zelle den Wert 0 oder 1 bekommt,
  anhand des eigenen Wertes und der Summe der Nachbarn.
  Übergibt nur Zellen mit Wert 1 dem `:new_map` Agent
  """
  @spec alive_in_new_map(k :: Zelle.t()) :: true | false
  def alive_in_new_map(k = %Zelle{}) do
    xline = Agent.get(:xy, &Map.get(&1, :x))
    yline = Agent.get(:xy, &Map.get(&1, :y))
    torisch = Agent.get(:xy, &Map.get(&1, :torisch))
    wert =  around_wert(0, xline,yline, [1,1,1,0,0,-1,-1,-1],[1,0,-1,1,-1,1,0,-1] ,k, torisch)
    zellenwert = Agent.get(:akt_map, &Map.get_lazy(&1, k, fn -> 0 end))
    cond do
      zellenwert == 1 ->
        if wert == 2 or wert == 3 do
          Agent.update(:new_map, &Map.put(&1, k, 1))
          true
        end
      zellenwert == 0 ->
        if wert == 3 do
          Agent.update(:new_map, &Map.put(&1, k, 1))
          false
        end
    end
    false
  end


  @doc """
  Summe der Nachtbarn

  Berechnet die Summe der Umligenden Zellen und gibt diese zurück.
  """
  @spec around_wert(wert :: pos_integer(), xline :: pos_integer(), yline :: pos_integer(), list1 :: list(), list2 :: list(), k :: Zelle.t(), torisch :: boolean()) :: pos_integer()
  def around_wert(wert, _xline, _yline, [], [], _k, _torisch) do
    wert
  end

  def around_wert(wert, xline, yline, [hx|tx], [hy|ty], k = %Zelle{}, torisch) do
     x = hx + k.x
     y = hy + k.y
    cond do
      torisch == false and 0 < x  and x <= xline and 0 < y and y <= yline ->
        nachtbar = %Zelle{
          x: x,
          y: y
        }
        Agent.get(:akt_map, &Map.get_lazy(&1, nachtbar, fn -> 0 end)) + wert
        |>around_wert(xline, yline,tx,ty,k,torisch)

      torisch == true ->
        nachtbar = %Zelle{
          x: torus_func(x, xline),
          y: torus_func(y, yline)
        }
        IO.inspect(nachtbar)
        Agent.get(:akt_map, &Map.get_lazy(&1, nachtbar, fn -> 0 end)) + wert
        |>around_wert(xline, yline,tx,ty,k,torisch)

      true ->
        around_wert(wert, xline, yline, tx, ty, k, torisch)
    end
  end

  @doc """
  Setzt eine Zelle auseherhalb der Dimension in den Torischen Bereich

  """
  @spec torus_func(wert :: pos_integer(), dimension :: pos_integer()) :: pos_integer()
  def torus_func(wert, dimension) do
    cond do
      wert <= 0 ->
        wert+ dimension
      wert > dimension ->
        wert - dimension
      true ->
        wert
    end
  end
end
