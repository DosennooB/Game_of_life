defmodule Zelle do
  @moduledoc """
  Gibt die Koordinaten im Zellautomaten wieder

  ## Parameter
   - x, y: Koordinaten im Zellautomaten
  """
  @type t:: %__MODULE__{
    x: integer(),
    y: integer()
  }

  @enforce_keys [:x,:y]
  defstruct [:x,:y]
end
