defmodule Verzzatile.DbTest do
  use ExUnit.Case
  alias Verzzatile.State
  alias Verzzatile.Cursor
  import Verzzatile.Db, only: [move_cursor: 2]

  test "FullCell fetches a key" do
    cell = Verzzatile.Cell.new('value')
    full_cell = Verzzatile.FullCell.new(cell)
    full_cell = %Verzzatile.FullCell{full_cell | next: %{friend: cell.id}}
    assert cell.id == get_in(full_cell, [:next, :friend])
    assert is_nil get_in(full_cell, [:next, :enemy, :id])

    full_cell = put_in(full_cell, [:next, :enemy], cell.id)
    assert cell.id == get_in(full_cell, [:next, :enemy])
  end

  test "Move cursor" do
    state = State.new()
    new_state = move_cursor(state, %Cursor{dimension: :friend})
    assert new_state.errors == []
    assert new_state.dimensions[:friend]
    assert new_state.cursors[0]  == %Cursor{dimension: :friend, id: state.origin.id}
    unknown_id = 42
    assert {:cell_not_found, _} = move_cursor(state, %Cursor{id: unknown_id}).errors
  end

end