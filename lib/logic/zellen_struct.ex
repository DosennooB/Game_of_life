defmodule Zelle do
  @moduledoc """
  Gibt die Koordinaten im Zellautomaten wieder

  ## Parameter
   - x, y: Koordinaten im Zellautomaten
  """

  @enforce_keys [:x,:y]
  defstruct [:x,:y]
end
