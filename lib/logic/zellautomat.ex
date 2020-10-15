defmodule Zellautomat do
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
@spec init :: no_return()
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

  @doc """
  Hauptschleife

  Es werde drei Signale verarbeitet
  die neuen Werte werden über `{:new_map, data :: map()}`
  zurück gegeben.

  - **toggel_cell:**
  Es kann geziehlt eine Zelle an oder aus geschaltet werden,
  abhängig von ihrem aktuellen Zustand.


  - **new_tick:**
  Der nächste Zustand des Automaten wird berechnet.

  - **automatic_tick:**
  Alle n Sekunden wird ein neuer Zustand der Zellautomaten berechnet.
  Durch den Parameter toggle kann diese Funktion an oder ausgeschaltet werden.
  Gibt den neuen Zustand nicht zurück.
  """
  @spec automat :: no_return()
  def automat() do
    receive do
      {:toggel_cell, zelle = %Zelle{}, pid} ->
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
          send pid, {:new_map, Agent.get(:akt_map, fn map -> map end)}
          Process.send_after(self() , {:automatic_tick, false, pid}, 1000)
        end
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
    zellentodo_doppelt = Agent.get(:todo, fn list -> list end)
    zellentodo = Enum.uniq(zellentodo_doppelt)
    Enum.map(zellentodo, fn k -> alive_in_new_map(k) end)

    nmap = Agent.get(:new_map, fn map -> map end)
    Agent.update(:akt_map, fn _oldmap -> nmap end)
    Agent.update(:new_map, fn _old -> %{} end)
    Agent.update(:todo, fn _list -> [] end)
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
    todo_zellen_around( xline, yline, [1,1,1,0,0,0,-1,-1,-1],[1,0,-1,1,0,-1,1,0,-1] ,zelle)
  end

  @doc false
  def todo_zellen_around( _xline, _yline, [], [], _k) do
    :ok
  end

  @doc false
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
    wert =  around_wert(0, xline,yline, [1,1,1,0,0,-1,-1,-1],[1,0,-1,1,-1,1,0,-1] ,k)
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
  @spec around_wert(wert :: pos_integer(), xline :: pos_integer(), yline :: pos_integer(), list1 :: list(), list2 :: list(), k :: Zelle.t()) :: pos_integer()
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
