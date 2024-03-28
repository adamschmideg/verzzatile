defmodule VerzzatileTest do
  use ExUnit.Case
  doctest Verzzatile

  test "Gets a cell that was added" do
    {:ok, _pid} = Verzzatile.start_link()
    cell = Verzzatile.add('value')
    assert {:ok, cell_got} = Verzzatile.get(cell)
    assert cell_got.value == 'value'
  end
end
