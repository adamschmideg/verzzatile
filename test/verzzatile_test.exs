defmodule VerzzatileTest do
  use ExUnit.Case
  doctest Verzzatile

  test "Gets a cell that was added" do
    {:ok, _pid} = Verzzatile.start_link()
    cell = Verzzatile.add('value')
    assert {:ok, cell_got} = Verzzatile.get(cell)
    IO.inspect(cell_got)
    assert cell_got.value == 'value'
  end

  test "Connect two cells and check if they are connected" do
    {:ok, _pid} = Verzzatile.start_link()
    cell1 = Verzzatile.add('value1')
    cell2 = Verzzatile.add('value2')
    assert :ok = Verzzatile.connect(cell1, cell2, :friend)
    assert cell2 = Verzzatile.next(cell1, :friend)
    assert is_nil Verzzatile.next(cell2, :friend)
    assert cell1 = Verzzatile.prev(cell2, :friend)
    assert is_nil Verzzatile.prev(cell1, :friend)
  end

  test "Connected cells are not connected in other dimensions" do
    {:ok, _pid} = Verzzatile.start_link()
    cell1 = Verzzatile.add('value1')
    cell2 = Verzzatile.add('value2')
    assert :ok = Verzzatile.connect(cell1, cell2, :friend)
    assert is_nil Verzzatile.next(cell1, :enemy)
    assert is_nil Verzzatile.prev(cell2, :enemy)
  end

  test "Cell can connect it itself" do
    {:ok, _pid} = Verzzatile.start_link()
    cell = Verzzatile.add('value')
    assert :ok = Verzzatile.connect(cell, cell, :friend)
    assert cell = Verzzatile.next(cell, :friend)
    assert cell = Verzzatile.prev(cell, :friend)
  end
end
