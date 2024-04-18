defmodule Verzzatile.Db do
  alias Verzzatile.Cell
  alias Verzzatile.Cursor
  alias Verzzatile.Direction
  import Verzzatile.Show, only: [extract_and_pad: 4]

  defp ensure_dimension(state, dimension) do
    if Map.has_key?(state.dimensions, dimension) do
      state
    else
      put_in(state, [:dimensions, dimension], map_size(state.dimensions))
    end
  end

  def cursor(state, cursor_name) do
    state = %{state | cursor_name: cursor_name}
    if Map.has_key?(state.cursors, cursor_name) do
      state
    else
      put_in(state, [:cursors, cursor_name], %Cursor{id: state.origin.id, dimension: :home})
    end
  end

  defp add_error(state, error) do
    put_in(state, [:errors], error)
  end

  def clear_errors(state) do
    put_in(state, [:errors], [])
  end

  def show_errors(state) do
    state.errors
  end

  defp connect(state, from, to, dimension) do
    next = get_in(state, [:next, from.id, dimension])
    prev = get_in(state, [:prev, to.id, dimension])
    cond do
      next != nil -> add_error(state, {:already_connected, from, next})
      prev != nil -> add_error(state, {:already_connected, prev, to})
      true ->
        new_next_ids = Map.put(state.next[from.id] || %{}, dimension, to.id)
        new_prev_ids = Map.put(state.prev[to.id] || %{},dimension, from.id)
        updated_state = state
                        |> put_in([:next, from.id], new_next_ids)
                        |> put_in([:prev, to.id], new_prev_ids)
        head_id = get_in(state, [:head, from.id, dimension]) || from.id
        path = [from.id | path_ids(state, to, dimension)]
        change_head_ids(updated_state, path, head_id, dimension)
    end
  end

  defp change_head_ids(state, path, head_id, dimension) do
    Enum.reduce(path, state, fn id, acc_state ->
      dimension_path = [:head, id, dimension]
      id_path = [:head, id]

      # Check if the dimension exists for the id
      case get_in(acc_state, dimension_path) do
        nil ->
          # Dimension doesn't exist; create a new map for the id with dimension => head_id
          put_in(acc_state, id_path, %{dimension => head_id})
        _ ->
          # Dimension exists; update it with head_id
          put_in(acc_state, dimension_path, head_id)
      end
    end)
  end

  def change_dimension(state, dimension) do
    state
    |> ensure_dimension(dimension)
    |> put_in([:cursors, state.cursor_name, :dimension], dimension)
  end

  def move_next(state) do
    cursor = current_cursor(state)
    next_id = get_in(state, [:next, cursor.id, cursor.dimension])
    if next_id do
      put_in(state, [:cursors, state.cursor_name, :id], next_id)
    else
      add_error(state, {:no_next_cell, cursor})
    end
  end

  def move_prev(state) do
    cursor = current_cursor(state)
    prev_id = get_in(state, [:prev, cursor.id, cursor.dimension])
    if prev_id do
      put_in(state, [:cursors, state.cursor_name, :id], prev_id)
    else
      add_error(state, {:no_prev_cell, cursor})
    end
  end

  def move_first(state) do
    cursor = current_cursor(state)
    head_id = get_in(state, [:head, cursor.id, cursor.dimension])
    if head_id do
      put_in(state, [:cursors, state.cursor_name, :id], head_id)
    else
      add_error(state, {:no_head_cell, cursor})
    end
  end

  def move_last(state) do
    cursor = current_cursor(state)
    cell = state.cells[cursor.id]
    path = path_ids(state, cell, cursor.dimension)
    last_id = Enum.at(path, -1)
    put_in(state, [:cursors, state.cursor_name, :id], last_id)
  end

  def go_home(state) do
    put_in(state, [:cursors, state.cursor_name], %Cursor{id: state.origin.id, dimension: :home})
  end

  def connect_cursor(state, other_cursor_name) do
    other_cursor = state.cursors[other_cursor_name]
    if other_cursor do
      cursor = current_cursor(state)
      from = state.cells[cursor.id]
      to = state.cells[other_cursor.id]
      connect(state, from, to, cursor.dimension)
    else
      add_error(state, {:no_cursor, other_cursor_name})
    end
  end

  def add_and_move(state, value) do
    cursor = current_cursor(state)
    cell = Cell.new(value, map_size(state.cells))
    from = state.cells[cursor.id]
    state
    |> put_in([:cells, cell.id], cell)
    |> connect(from, cell, cursor.dimension)
    |> move_next
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

  defp current_cursor(state) do
    state.cursors[state.cursor_name]
  end

  def show_cursor(state) do
    cursor = current_cursor(state)
    cell = state.cells[cursor.id]
    {cursor.dimension, cell.value}
  end

  def show_connected_cells(state, cell, x_dimension, y_dimension, view_window = %Direction{}) do
    head_id = get_in(state, [:head, cell.id, x_dimension])
    head = state.cells[head_id]
    main_ids = path_ids(state, head, x_dimension)
    main_ids = extract_and_pad(main_ids, cell.id, view_window.left, view_window.right)
    {main_ids, y_dimension}
  end

  defp path_ids(state, cell = %Cell{}, dimension) do
    get_path_ids(state, cell.id, dimension, [cell.id])
  end

  defp get_path_ids(state, id, dimension, acc) do
    next_id = get_in(state, [:next, id, dimension])
    case next_id do
      nil -> Enum.reverse(acc)
      _ -> get_path_ids(state, next_id, dimension, [next_id | acc])
    end
  end

end