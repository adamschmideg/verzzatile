defmodule VerzzatileTest do
  use ExUnit.Case
  doctest Verzzatile

  test "Gets a cell that was added" do
    cell = Verzzatile.add('value')
    cell_got = Verzzatile.get(cell)
    assert !is_nil(cell_got)
    assert cell_got.value == 'value'
  end
end
