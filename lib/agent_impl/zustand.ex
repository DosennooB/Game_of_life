defmodule Zustand do
  use Agent

  @moduledoc """
  Es Speicher für den Zellautomaten.

  Enthält zwei Maps einen für den Aktuellen Zustand und einen für den neuen Zustand des Automaten.
  """

  @doc """
  Startet die Agents für den Aktuellen und zu berechnenden Zustand.
  """
  @spec start_link(_opts :: any()) :: {:ok, pid()}
  def start_link(_opst) do
    Agent.start_link(fn -> %{} end, name: :akt_map)
    Agent.start_link(fn -> %{} end, name: :new_map)
  end

  @doc """
  Verändert die übergebenden Zellen im Aktuellen Zustand des Automaten.

  Die übergebenden Zellen werden im Automaten von null auf eins oder umgekert gesetzt.
  """
  @spec toggel_cell(z :: [Zelle.t()]) :: [true | false]
  def toggel_cell(z) do
    Enum.map(z, fn zelle ->
      Agent.update(:akt_map, fn map ->
        Map.update(map, zelle, 1, &rem(&1 + 1, 2))
      end)
    end)
  end

  @doc """
  Der aktuelle Zustand wird als Map übergeben.
  """
  @spec get_akt_map :: map()
  def get_akt_map() do
    Agent.get(:akt_map, fn map -> map end)
  end

  @doc """
  Gibt den Wert der Aktuellen Zelle zurück.

  Wenn die Zelle sich auserhalb der Dimensionen befindet wird Sie auch als 0 betrachtet.
  """
  @spec get_akt_cell_wert(z :: Zelle.t()) :: 0 | 1
  def get_akt_cell_wert(z = %Zelle{}) do
    Agent.get(:akt_map, &Map.get_lazy(&1, z, fn -> 0 end))
  end

  @doc """
  Setzt eine übergebende Zelle mit dem Wert 1 in die Map für den neuen Zustand
  """
  @spec set_new_cell(z :: Zelle.t()) :: :ok
  def set_new_cell(z = %Zelle{}) do
    Agent.update(:new_map, &Map.put(&1, z, 1))
  end

  @doc """
  Der neu berechnete Zustand des Zellautomaten wird als aktueller Zustand festgelegt.

  Die Map für den Alten Zustand wird gelöscht.
  """
  @spec end_tick() :: :ok
  def end_tick() do
    nmap = Agent.get(:new_map, fn map -> map end)
    Agent.update(:akt_map, fn _oldmap -> nmap end)
    Agent.update(:new_map, fn _old -> %{} end)
    :ok
  end
end
