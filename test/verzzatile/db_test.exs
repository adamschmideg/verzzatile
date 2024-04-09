defmodule Verzzatile.DbTest do
  use ExUnit.Case
  alias Verzzatile.Cell
  import Verzzatile.Db, only: [add: 2, get: 2, connect: 4, next: 3, prev: 3]

  test "FullCell fetches a key" do
    cell = Verzzatile.Cell.new('value')
    full_cell = Verzzatile.FullCell.new(cell)
    full_cell = %Verzzatile.FullCell{full_cell | next: %{friend: cell.id}}
    assert cell.id == get_in(full_cell, [:next, :friend])
    assert is_nil get_in(full_cell, [:next, :enemy, :id])

    full_cell = put_in(full_cell, [:next, :enemy], cell.id)
    assert cell.id == get_in(full_cell, [:next, :enemy])
  end

  test "Connect two cells" do
    from = Cell.new('value1')
    to = Cell.new('value2')
    {:ok, state} = %{}
      |> add(from)
      |> add(to)
      |> connect(from, to, :friend)
    assert to = next(state, from, :friend)
    assert from = prev(state, to, :friend)
  end

end