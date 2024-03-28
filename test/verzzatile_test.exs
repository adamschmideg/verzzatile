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

  @tag :skip
  test "Connect two cells and check if they are connected" do
    {:ok, _pid} = Verzzatile.start_link()
    cell1 = Verzzatile.add('value1')
    cell2 = Verzzatile.add('value2')
    assert {:ok, _} = Verzzatile.connect(cell1, cell2, :friend)
    assert {:ok, cell2} = Verzzatile.next(cell1, :friend)
    assert {:not_found, _} = Verzzatile.next(cell2, :friend)
  end
end
