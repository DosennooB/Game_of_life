defmodule Todo do
  use Agent

  @moduledoc """
  Enthält alle Zellen die im nächsten Schritt berechnet werden müssen.

  Wird als zwischen speicher genutzt.
  """


  @doc """
  Registriert den Prozess auf den passenden Namen.
  """
  @spec start_link(_opts :: any()) :: {:ok, pid()}
  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: :todo)
  end

  @doc """
  Gibt eine Liste an Zellen zurück die entsprechend bearbeitet werden sollen.
  """
  @spec get_list() :: [Zelle.t()]
  def get_list() do
    zellentodo_doppelt = Agent.get(:todo, fn list -> list end)
    Enum.uniq(zellentodo_doppelt)
  end

  @doc """
  Nimmt eine Neue zu bearbeitende Zelle in die Liste auf.
  """
  @spec add_to_list(nzelle :: Zelle.t()) :: :ok
  def add_to_list(nzelle) do
    Agent.update(:todo, fn list -> [nzelle|list] end)
  end

  @doc """
  Löscht alle Zellen aus der Liste.
  """
  @spec dell_list() :: :ok
  def dell_list() do
    Agent.update(:todo, fn _list -> [] end)
  end
end
