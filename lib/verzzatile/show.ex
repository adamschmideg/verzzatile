defmodule Verzzatile.Show do
  alias Verzzatile.Db
  alias Verzzatile.Direction
  alias Verzzatile.State

  import Verzzatile.Db, only: [current_cursor: 1, path_ids: 3]

  def extract_and_pad(list, element, left_count, right_count) when left_count > 0 and right_count > 0 do
    position = Enum.find_index(list, &(&1 == element))
    left_index = max(position - left_count, 0)
    left_side = Enum.slice(list, left_index, left_count)
    left_pad = List.duplicate(nil, left_count - length(left_side))
    right_index = min(position + 1, length(list))
    right_side = Enum.slice(list, right_index, right_count)
    right_pad = List.duplicate(nil, right_count - length(right_side))

    left_pad ++ left_side ++ [element] ++ right_side ++ right_pad
  end

  def errors(state) do
    state.errors
  end

  def show_connected_cells(state = %State{}, cell, x_dimension, y_dimension, view_window = %Direction{}) do
    head_id = get_in(state, [:head, cell.id, x_dimension])
    head = state.cells[head_id]
    main_ids = Db.path_ids(state, head, x_dimension)
    main_ids = extract_and_pad(main_ids, cell.id, view_window.left, view_window.right)
    {main_ids, y_dimension}
  end

  def cursor(state = %State{}) do
    cursor = current_cursor(state)
    cell = state.cells[cursor.id]
    {cursor.dimension, cell.value}
  end

  def path_values(state) do
    cursor = current_cursor(state)
    cell = state.cells[cursor.id]
    path_ids(state, cell, cursor.dimension)
    |> Enum.map(fn id -> state.cells[id].value end)
  end

  def full_path_values(state) do
    cursor = current_cursor(state)
    head_id = get_in(state, [:head, cursor.id, cursor.dimension])
    head = state.cells[head_id]
    path_ids(state, head, cursor.dimension)
    |> Enum.map(fn id -> state.cells[id].value end)
  end

end