defmodule Verzzatile.DbTest do
  use ExUnit.Case
  use ExUnitProperties
  alias Verzzatile.State
  alias Verzzatile.Db

  import StreamData

  @cursors [:origin, :home, :friend, :enemy, :travel]

  @operations %{
    :cursor => @cursors,
    :move_next => nil,
    :move_prev => nil,
    :move_first => nil,
    :move_last => nil,
    :go_home => nil,
    :jump => @cursors,
    :connect_cursor => @cursors,
    :add_and_move => ["Fred", "Wilma", "Barney", "Betty"],
    :change_dimension => [:east, :west, :north, :south]
  }

  def operation_gen() do
    @operations
    |> Map.keys()
    |> Enum.map(&constant(&1))
    |> one_of()
    |> StreamData.map(fn f -> if args = @operations[f], do: {f, Enum.random(args)}, else: {f, nil} end)
  end

  def apply_operations(operations, state \\ nil) do
    initial_state = state || State.new()
    Enum.reduce(operations, initial_state, fn {op, args}, acc_state ->
      if args == nil do
        apply(Db, op, [acc_state])
      else
        apply(Db, op, [acc_state, args])
      end
    end)
  end

  property "apply operations sequence without exceptions" do
    check all operations <- list_of(operation_gen(), min_length: 1, max_length: 10) do
      state = apply_operations(operations)

      assert map_size(state.next) == map_size(state.prev)
      assert true
    end
  end

  property "Adding a cell creates at least two consecutive cells" do
    check all operations <- list_of(operation_gen(), min_length: 1, max_length: 10) do
      state = apply_operations(operations)
        |> Db.clear_errors()
        |> Db.change_dimension(:brave_new_world)
        |> Db.add_and_move("America")
      assert Db.show_errors(state) == []
      new_cursor = Db.show_cursor(state)
      prev_cursor = state |> Db.move_prev() |> Db.show_cursor()
      assert new_cursor != prev_cursor
      assert new_cursor == state |> Db.move_prev() |> Db.move_next() |> Db.show_cursor()
    end
  end

  test "Add cell creates a new cell than is prev neighbor" do
    state = State.new()
            |> Db.add_and_move("Italy")
            |> Db.go_home()
            |> Db.cursor(:travel)
            |> Db.change_dimension(:brave_new_world)
            |> Db.add_and_move("America")
    assert [] = Db.show_errors(state)
    new_cursor = Db.show_cursor(state)
    prev_cursor = state |> Db.move_prev() |> Db.show_cursor()
    assert new_cursor != prev_cursor
    assert new_cursor == state |> Db.move_prev() |> Db.move_next() |> Db.show_cursor()
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
    assert {:friend, "Fred"} = Db.show_cursor(state)
    new_cursor = state
      |> Db.move_prev()
      |> Db.show_cursor()
    assert {:friend, :origin} = new_cursor
  end

  test "Add two cells and get the path" do
    state = State.new()
      |> Db.change_dimension(:friend)
      |> Db.add_and_move("Fred")
      |> Db.add_and_move("Wilma")
      |> Db.move_prev()
    assert ["Fred", "Wilma"] = Db.path_values(state)
  end

  test "Move to the first cell" do
    state = State.new()
      |> Db.add_and_move("Fred")
      |> Db.add_and_move("Wilma")
      |> Db.move_first()
    assert {:home, :origin} = Db.show_cursor(state)
  end

  test "Get the full path" do
    state = State.new()
            |> Db.change_dimension(:friend)
            |> Db.add_and_move("Fred")
            |> Db.add_and_move("Wilma")
            |> Db.move_prev()
    assert [:origin, "Fred", "Wilma"] = Db.full_path_values(state)
  end

  test "Connect cursors" do
    state = State.new()
            |> Db.add_and_move("Abroad")
            |> Db.change_dimension(:travel)
            |> Db.cursor(1)
            |> Db.cursor(0)
            |> Db.connect_cursor(1)
    assert ["Abroad", :origin] = Db.full_path_values(state)
  end

  test "Jumping with cursor" do
    state = State.new()
            |> Db.add_and_move("Abroad")
            |> Db.change_dimension(:travel)
            |> Db.cursor(1)
            |> Db.jump(0)
    assert {:travel, "Abroad"} = Db.show_cursor(state)
  end

  @tag :skip
  test "All functions in Db module work" do
    state = State.new()
      |> Db.change_dimension(:friend)
      |> Db.add_and_move('value1')
      |> Db.move_prev()
      |> Db.add_and_move('value2')
      |> Db.move_next()
      |> Db.cursor(1)
      |> Db.connect_cursor(0)
      |> Db.move_first()
      |> Db.jump(0)
      |> Db.move_last()
    assert [] = Db.show_cursor(state)
    assert [] = Db.path_values(state)
  end
end