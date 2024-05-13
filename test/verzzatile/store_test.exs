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
        |> Store.clear_errors()
        |> Store.change_dimension(:brave_new_world)
        |> Store.add_and_move("America")
      assert View.errors(state) == []
      new_cursor = View.cursor(state)
      prev_cursor = state |> Store.move_prev() |> View.cursor()
      assert new_cursor != prev_cursor
      assert new_cursor == state |> Store.move_prev() |> Store.move_next() |> View.cursor()
    end
  end

  test "Add cell creates a new cell than is prev neighbor" do
    state = State.new()
            |> Store.add_and_move("Italy")
            |> Store.go_home()
            |> Store.cursor(:travel)
            |> Store.change_dimension(:brave_new_world)
            |> Store.add_and_move("America")
    assert [] = View.errors(state)
    new_cursor = View.cursor(state)
    prev_cursor = state |> Store.move_prev() |> View.cursor()
    assert new_cursor != prev_cursor
    assert new_cursor == state |> Store.move_prev() |> Store.move_next() |> View.cursor()
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
      |> Store.change_dimension(:friend)
      |> Store.add_and_move("Fred")
    assert {:friend, "Fred"} = View.cursor(state)
    new_cursor = state
      |> Store.move_prev()
      |> View.cursor()
    assert {:friend, :origin} = new_cursor
  end

  test "Add two cells and get the path" do
    state = State.new()
      |> Store.change_dimension(:friend)
      |> Store.add_and_move("Fred")
      |> Store.add_and_move("Wilma")
      |> Store.move_prev()
    assert ["Fred", "Wilma"] = View.path_values(state)
  end

  test "Move to the first cell" do
    state = State.new()
      |> Store.add_and_move("Fred")
      |> Store.add_and_move("Wilma")
      |> Store.move_first()
    assert {:home, :origin} = View.cursor(state)
  end

  test "Get the full path" do
    state = State.new()
            |> Store.change_dimension(:friend)
            |> Store.add_and_move("Fred")
            |> Store.add_and_move("Wilma")
            |> Store.move_prev()
    assert [:origin, "Fred", "Wilma"] = View.full_path_values(state)
  end

  test "Connect cursors" do
    state = State.new()
            |> Store.add_and_move("Abroad")
            |> Store.change_dimension(:travel)
            |> Store.cursor(1)
            |> Store.cursor(0)
            |> Store.connect_cursor(1)
    assert ["Abroad", :origin] = View.full_path_values(state)
  end

  test "Nested structure ensuring non-existent substructure" do
    map = %{}
    keys = [:a, :b, :c]
    assert %{:a => %{:b => %{:c => 0}}} == Store.put_in_always(map, keys, 0)
  end

end