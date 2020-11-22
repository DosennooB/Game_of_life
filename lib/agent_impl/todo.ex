defmodule Todo do
  use Agent


  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: :todo)
  end

  def get_list() do
    zellentodo_doppelt = Agent.get(:todo, fn list -> list end)
    Enum.uniq(zellentodo_doppelt)
  end

  def add_to_list(nzelle) do
    Agent.update(:todo, fn list -> [nzelle|list] end)
  end

  def dell_list() do
    Agent.update(:todo, fn _list -> [] end)
  end
end
