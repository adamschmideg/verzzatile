defmodule Verzzatile.StoreTest do
  use ExUnit.Case
  use ExUnitProperties
  alias Verzzatile.State
  alias Verzzatile.Store
  alias Verzzatile.View

  import StreamData
  import TestHelper


  property "apply operations sequence without exceptions" do
    check all operations <- list_of(operation_gen(), min_length: 1, max_length: 10) do
      apply_operations(operations)

      assert true
    end
  end

  property "Adding a cell creates at least two consecutive cells" do
    check all operations <- list_of(operation_gen(), min_length: 1, max_length: 10) do
      state = apply_operations(operations)
        |> Db.clear_errors()
        |> Db.change_dimension(:brave_new_world)
        |> Db.add_and_move("America")
      assert Show.errors(state) == []
      new_cursor = Show.cursor(state)
      prev_cursor = state |> Db.move_prev() |> Show.cursor()
      assert new_cursor != prev_cursor
      assert new_cursor == state |> Db.move_prev() |> Db.move_next() |> Show.cursor()
    end
  end

  test "Add cell creates a new cell than is prev neighbor" do
    state = State.new()
            |> Db.add_and_move("Italy")
            |> Db.go_home()
            |> Db.cursor(:travel)
            |> Db.change_dimension(:brave_new_world)
            |> Db.add_and_move("America")
    assert [] = Show.errors(state)
    new_cursor = Show.cursor(state)
    prev_cursor = state |> Db.move_prev() |> Show.cursor()
    assert new_cursor != prev_cursor
    assert new_cursor == state |> Db.move_prev() |> Db.move_next() |> Show.cursor()
  end

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
    assert {:friend, "Fred"} = Show.cursor(state)
    new_cursor = state
      |> Db.move_prev()
      |> Show.cursor()
    assert {:friend, :origin} = new_cursor
  end

  test "Add two cells and get the path" do
    state = State.new()
      |> Db.change_dimension(:friend)
      |> Db.add_and_move("Fred")
      |> Db.add_and_move("Wilma")
      |> Db.move_prev()
    assert ["Fred", "Wilma"] = Show.path_values(state)
  end

  test "Move to the first cell" do
    state = State.new()
      |> Db.add_and_move("Fred")
      |> Db.add_and_move("Wilma")
      |> Db.move_first()
    assert {:home, :origin} = Show.cursor(state)
  end

  test "Get the full path" do
    state = State.new()
            |> Db.change_dimension(:friend)
            |> Db.add_and_move("Fred")
            |> Db.add_and_move("Wilma")
            |> Db.move_prev()
    assert [:origin, "Fred", "Wilma"] = Show.full_path_values(state)
  end

  test "Connect cursors" do
    state = State.new()
            |> Db.add_and_move("Abroad")
            |> Db.change_dimension(:travel)
            |> Db.cursor(1)
            |> Db.cursor(0)
            |> Db.connect_cursor(1)
    assert ["Abroad", :origin] = Show.full_path_values(state)
  end

  test "Nested structure ensuring non-existent substructure" do
    map = %{}
    keys = [:a, :b, :c]
    assert %{:a => %{:b => %{:c => 0}}} == Db.put_in_always(map, keys, 0)
  end

end