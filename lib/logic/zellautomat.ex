defmodule Zellautomat do
  use GenServer

  @moduledoc """
  Logic des Zellautomaten.

  Die nötigen Paarameter werden in Agents gespeichert.
  Der Zelleautomat wird als Genserver Implementiert und von einem Supervisor überwacht.
  Er kann abstürtzen ohne das ein Datenverlust statt findet.
  """

  @doc """
  Initialisierung des Automaten.

  Starten des Zellautomaten Als Genserver. Optionale Parameter sind noch nicht vorgesehen.
  """
  @spec start_link(_opts :: any()) :: {:ok, pid}
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: :zellautomat)
  end

  @impl true
  def init(opts) do
    {:ok, opts}
  end

  @doc """
  Es kann geziehlt eine Zelle an oder aus geschaltet werden,
  abhängig von ihrem aktuellen Zustand.

  Es können mehrere Zellen gleichzeitig
  verändert werden.
  """
  @spec handle_info({:toggel_cell, z :: [Zelle.t()]}, state :: term()) ::
          {:noreply, state :: term()}
  @impl true
  def handle_info({:toggel_cell, z}, state) do
    ztr = relocate_cell(z)

    Zustand.toggel_cell(ztr)

    if !XY.get(:torisch) do
      resize()
    end

    send(:field, {:new_map, Zustand.get_akt_map()})
    {:noreply, state}
  end

  @doc """
  Die Dimensionen des Zellautomaten werden neu gesetzt.
  Kann wärend des Laufenden Programmes geschehen.
  """
  @spec handle_info({:set_xy, x :: pos_integer(), y :: pos_integer()}, state :: term()) ::
          {:noreply, state :: term()}
  @impl true
  def handle_info({:set_xy, x, y}, state) do
    XY.set(:x, max(x, 1))
    XY.set(:y, max(y, 1))
    resize()
    send(:field, {:new_map, Zustand.get_akt_map()})
    {:noreply, state}
  end

  @doc """
  Ändert den Torisch Wert in der Datenhaltung.
  """
  @spec handle_info({:set_torisch, torisch_wert :: boolean()}, state :: term()) ::
          {:noreply, state :: term()}
  def handle_info({:set_torisch, torisch_wert}, state) do
    XY.set(:torisch, torisch_wert)
    {:noreply, state}
  end

  @doc """
  Ändert den Wert für die Tickrate in Millisekunden.
  """
  @spec handle_info({:set_tick_rate, value :: integer()}, state :: term()) ::
          {:noreply, state :: term()}
  @impl true
  def handle_info({:set_tick_rate, value}, state) do
    XY.set(:tick_rate, max(value, 1))
    {:noreply, state}
  end

  @doc """
  Der nächste Zustand des Automaten wird berechnet.
  """
  @spec handle_info({:new_tick}, state :: term()) :: {:noreply, state :: term()}
  @impl true
  def handle_info({:new_tick}, state) do
    tick()
    send(:field, {:new_map, Zustand.get_akt_map()})
    {:noreply, state}
  end

  @doc """
  Alle n Sekunden wird ein neuer Zustand der Zellautomaten berechnet.

  Durch den Parameter toggle kann diese Funktion an oder ausgeschaltet werden.
  Gibt den neuen Zustand zurück.
  """
  @spec handle_info({:automatic_tick, toggel :: boolean()}, state :: term()) ::
          {:noreply, state :: term()}
  @impl true
  def handle_info({:automatic_tick, toggel}, state) do
    if toggel do
      t = XY.get(:toggel)
      XY.set(:toggel, !t)
    end

    t = XY.get(:toggel)

    if t do
      time = XY.get(:tick_rate)
      tick()
      send(:field, {:new_map, Zustand.get_akt_map()})
      Process.send_after(:zellautomat, {:automatic_tick, false}, time)
    end

    {:noreply, state}
  end

  @doc """
  Lässt den nächsten Zustand des Zellautomaten berechnen.

  Lässten nächten Zustand berechnen und gibt die neuen Werte
  an die Agents weiter. Nur Zellen die den Wert 1 haben oder Nachtbar einer
  Zelle mit dem Wert 1 sind, werden berechnet.
  """
  @spec tick() :: :ok
  def tick() do
    map = Zustand.get_akt_map()

    Enum.map(map, fn {k, v} ->
      if v == 1 do
        todo_zellen_around(k)
      end
    end)

    zellentodo = Todo.get_list()
    Enum.map(zellentodo, fn k -> alive_in_new_map(k) end)
    Todo.dell_list()
    Zustand.end_tick()
  end

  @doc """
  Löscht alle Zellen auserhalb der Vorgegeben Dimensionen.

  Schreibt dazu alle zellen innerhalb der Dimensionen in die neue Map und setzt diese dann
  als Aktuelle.
  """
  @spec resize() :: :ok
  def resize() do
    map = Zustand.get_akt_map()
    x = XY.get(:x)
    y = XY.get(:y)

    Enum.map(map, fn {k = %Zelle{}, v} ->
      if k.x <= x and k.y <= y and v == 1 do
        Zustand.set_new_cell(k)
      end
    end)

    Zustand.end_tick()
  end

  @doc """
  Ermittelt Nachtbarn und die angegebene Zelle.

  Übergibt alle Nachtbarn und die angegebene Zelle,
  dem `:todo` Agent. Es sei den, sie befinden sich auserhalb des Zellautomaten.
  """
  @spec todo_zellen_around(zelle :: Zelle.t()) :: :ok
  def todo_zellen_around(zelle = %Zelle{}) do
    xline = XY.get(:x)
    yline = XY.get(:y)
    torisch = XY.get(:torisch)

    todo_zellen_around(
      xline,
      yline,
      [1, 1, 1, 0, 0, 0, -1, -1, -1],
      [1, 0, -1, 1, 0, -1, 1, 0, -1],
      zelle,
      torisch
    )
  end

  @doc false
  def todo_zellen_around(_xline, _yline, [], [], _k, _torisch) do
    :ok
  end

  @doc false
  def todo_zellen_around(xline, yline, [hx | tx], [hy | ty], k, torisch) do
    x = hx + k.x
    y = hy + k.y

    cond do
      torisch == false and 0 < x and x <= xline and 0 < y and y <= yline ->
        nzelle = %Zelle{
          x: x,
          y: y
        }

        Todo.add_to_list(nzelle)
        todo_zellen_around(xline, yline, tx, ty, k, torisch)

      torisch == true ->
        nzelle = %Zelle{
          x: torus_func(x, xline),
          y: torus_func(y, yline)
        }

        Todo.add_to_list(nzelle)
        todo_zellen_around(xline, yline, tx, ty, k, torisch)

      true ->
        todo_zellen_around(xline, yline, tx, ty, k, torisch)
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
    xline = XY.get(:x)
    yline = XY.get(:y)
    torisch = XY.get(:torisch)

    wert =
      around_wert(
        0,
        xline,
        yline,
        [1, 1, 1, 0, 0, -1, -1, -1],
        [1, 0, -1, 1, -1, 1, 0, -1],
        k,
        torisch
      )

    zellenwert = Zustand.get_akt_cell_wert(k)

    cond do
      zellenwert == 1 ->
        if wert == 2 or wert == 3 do
          Zustand.set_new_cell(k)
          true
        end

      zellenwert == 0 ->
        if wert == 3 do
          Zustand.set_new_cell(k)
          false
        end
    end

    false
  end

  @doc """
  Summe der Nachtbarn

  Berechnet die Summe der Umligenden Zellen und gibt diese zurück.
  """
  @spec around_wert(
          wert :: pos_integer(),
          xline :: pos_integer(),
          yline :: pos_integer(),
          list1 :: list(),
          list2 :: list(),
          k :: Zelle.t(),
          torisch :: boolean()
        ) :: pos_integer()
  def around_wert(wert, _xline, _yline, [], [], _k, _torisch) do
    wert
  end

  def around_wert(wert, xline, yline, [hx | tx], [hy | ty], k = %Zelle{}, torisch) do
    x = hx + k.x
    y = hy + k.y

    cond do
      torisch == false and 0 < x and x <= xline and 0 < y and y <= yline ->
        nachtbar = %Zelle{
          x: x,
          y: y
        }

        (Zustand.get_akt_cell_wert(nachtbar) + wert)
        |> around_wert(xline, yline, tx, ty, k, torisch)

      torisch == true ->
        nachtbar = %Zelle{
          x: torus_func(x, xline),
          y: torus_func(y, yline)
        }

        (Zustand.get_akt_cell_wert(nachtbar) + wert)
        |> around_wert(xline, yline, tx, ty, k, torisch)

      true ->
        around_wert(wert, xline, yline, tx, ty, k, torisch)
    end
  end

  @doc """
  Setzt Zellen in den Torischen Körper.

  Wird nur aktive wenn der Zellautomat sich im Torischen Modus befindet.
  """
  @spec relocate_cell(z :: [Zelle.t()]) :: [Zelle.t()]
  def relocate_cell(z) do
    xline = XY.get(:x)
    yline = XY.get(:y)
    bool = XY.get(:torisch)

    cond do
      bool == true ->
        Enum.map(z, fn k = %Zelle{} ->
          %Zelle{
            x: torus_func(k.x, xline),
            y: torus_func(k.y, yline)
          }
        end)

      true ->
        z
    end
  end

  @doc """
  Setzt eine Zelle auseherhalb der Dimension in den Torischen Bereich

  """
  @spec torus_func(wert :: pos_integer(), dimension :: pos_integer()) :: pos_integer()
  def torus_func(wert, dimension) do
    cond do
      wert <= 0 ->
        wert + dimension

      wert > dimension ->
        wert - dimension

      true ->
        wert
    end
  end
end
