defmodule Verzzatile.DbTest do
  use ExUnit.Case
  alias Verzzatile.State
  alias Verzzatile.Db

  test "FullCell fetches a key" do
    cell = Verzzatile.Cell.new('value')
    full_cell = Verzzatile.FullCell.new(cell)
    full_cell = %Verzzatile.FullCell{full_cell | next: %{friend: cell.id}}
    assert cell.id == get_in(full_cell, [:next, :friend])
    assert is_nil get_in(full_cell, [:next, :enemy, :id])

    full_cell = put_in(full_cell, [:next, :enemy], cell.id)
    assert cell.id == get_in(full_cell, [:next, :enemy])
  end

  test "Add a cell and move the cursor" do
    state = State.new()
      |> Db.change_dimension(:friend)
      |> Db.add_and_move("Fred")
    assert {:friend, "Fred"} = Db.show_cursor(state)
  end

  @tag :skip
  test "All functions in Db module work" do
    state = State.new()
      |> Db.change_dimension(:friend)
      |> Db.add_and_move('value1')
      |> Db.move_prev()
      |> Db.add_and_move('value2')
      |> Db.swap_cursors()
      |> Db.move_next()
      |> Db.swap_cursors()
      |> Db.connect_cursors()
      |> Db.move_first()
      |> Db.move_last()
    assert [] = Db.show_cursor(state)
    assert [] = Db.path(state)
  end
end