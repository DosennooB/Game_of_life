defmodule Zellautomaten_test do
  use ExUnit.Case
  doctest Zellautomat

  @tag timout: 3000
  test "toggel" do
    z = %Zelle{
      x: 3,
      y: 2
    }
    startup_process(3,3)
    send :zellautomat, {:toggel_cell, z, self()}
    map = %{z => 1}
    receive do
      {:new_map, value} ->
        end_prozess()
        assert value == map

    end
  end

  @tag timeout: 3000
  test "todo_zellen_around" do
    startup_process(3,3)
    z = %Zelle{
      x: 3,
      y: 3
    }
    z1 = %Zelle{
      x: 3,
      y: 2
    }
    z2 = %Zelle {
      x: 2,
      y: 3
    }
    z3 = %Zelle {
      x: 2,
      y: 2
    }
    Zellautomat.todo_zellen_around(z)
    list = Agent.get(:todo, fn list -> list end)
    end_prozess()
    assert list == [z3,z2,z1,z]
  end

  @tag timeout: 3000
  test "around_wert" do
    startup_process(3,3)
    z = %Zelle{
      x: 3,
      y: 3
    }
    z1 = %Zelle{
      x: 3,
      y: 2
    }
    z2 = %Zelle {
      x: 2,
      y: 3
    }
    z3 = %Zelle {
      x: 2,
      y: 2
    }
    send :zellautomat, {:toggel_cell, z, self()}
    send :zellautomat, {:toggel_cell, z1, self()}
    send :zellautomat, {:toggel_cell, z2, self()}
    Zellautomat.alive_in_new_map(z3)
    wert =  Agent.get(:new_map, &Map.get(&1, z3))

    end_prozess()
    assert 1== wert
  end

  @tag timeout: 3000
  test "tick" do
    startup_process(3,3)
    z = %Zelle{
      x: 3,
      y: 3
    }
    z1 = %Zelle{
      x: 3,
      y: 2
    }
    z2 = %Zelle {
      x: 2,
      y: 3
    }
    z3 = %Zelle {
      x: 2,
      y: 2
    }
    zn = %Zelle {
      x: 2,
      y: 1
    }
    send :zellautomat, {:toggel_cell, z, self()}
    send :zellautomat, {:toggel_cell, z1, self()}
    send :zellautomat, {:toggel_cell, z2, self()}
    Process.sleep(300)
    Zellautomat.tick()
    an = Agent.get(:akt_map, fn map -> map end)
    end_prozess()
    assert 1 == Map.get(an, z3)
    assert 1 == Map.get(an, z2)
    assert 1 == Map.get(an, z1)
    assert 1 == Map.get(an, z)
    assert nil == Map.get(an, zn)
  end

  def end_prozess() do
    Agent.stop(:xy, :normal)
    Agent.stop(:akt_map, :normal)
    Agent.stop(:new_map, :normal)
    Agent.stop(:todo, :normal)
    Process.unregister(:zellautomat)
    Process.sleep(100)
  end

  def startup_process(x, y) do
    zellautomat_pid = spawn(fn -> Zellautomat.init() end)
    send zellautomat_pid,{:set_xy, x, y}
    Process.sleep(100)
  end
end
