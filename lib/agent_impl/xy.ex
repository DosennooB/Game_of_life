defmodule XY do
  use Agent

  @moduledoc """
  Enthält weitere Parameter für den Zellautomaten.


  Prameter sind z.b.
  X Dimension :x
  Y Dimension :y
  Automatisches weiterlaufen :toggel
  Angabe über torisch oder nicht :torisch
  """

  @doc """
  Registriert den Prozess auf den passenden Namen.
  """
  @spec start_link(_opts :: any()) :: {:ok, pid()}
  def start_link(_opts) do
    Agent.start_link(
      fn -> %{:x => 20, :y => 20, :toggel => false, :torisch => false, :tick_rate => 1000} end,
      name: :xy
    )
  end

  @doc """
  Setzt einen einen paramert auf das mitgelieferte value
  """
  @spec set(key :: atom(), value :: any()) :: :ok
  def set(key, value) do
    Agent.update(:xy, &Map.put(&1, key, value))
  end

  @doc """
  Bekommt den Wert an der Stelle des Parameter zurück.
  """
  @spec get(key :: atom()) :: any()
  def get(key) do
    Agent.get(:xy, &Map.get(&1, key))
  end

  @doc """
  Gibt alle Parameter als map zurück.
  """
  @spec get_all() :: map()
  def get_all do
    Agent.get(:xy, fn map -> map end)
  end
end
