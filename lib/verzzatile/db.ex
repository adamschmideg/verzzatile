defmodule Verzzatile.Db do
  alias Verzzatile.Cell
  alias Verzzatile.Cursor
  alias Verzzatile.State

  import Verzzatile.Show, only: [current_cursor: 1, path_ids: 3]

  defp ensure_dimension(state = %State{}, dimension) do
    if Map.has_key?(state.dimensions, dimension) do
      state
    else
      put_in(state, [:dimensions, dimension], map_size(state.dimensions))
    end
  end

  def cursor(state = %State{}, cursor_name) do
    state = %{state | cursor_name: cursor_name}
    if Map.has_key?(state.cursors, cursor_name) do
      state
    else
      put_in(state, [:cursors, cursor_name], %Cursor{id: state.origin.id, dimension: :home})
    end
  end

  defp add_error(state = %State{}, error) do
    put_in(state, [:errors], error)
  end

  def clear_errors(state = %State{}) do
    put_in(state, [:errors], [])
  end

  defp connect(state = %State{}, from, to, dimension) do
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

  defp change_head_ids(state = %State{}, path, head_id, dimension) do
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

  def change_dimension(state = %State{}, dimension) do
    state
    |> ensure_dimension(dimension)
    |> put_in([:cursors, state.cursor_name, :dimension], dimension)
  end

  def move_next(state = %State{}) do
    cursor = current_cursor(state)
    next_id = get_in(state, [:next, cursor.id, cursor.dimension])
    if next_id do
      put_in(state, [:cursors, state.cursor_name, :id], next_id)
    else
      add_error(state, {:no_next_cell, cursor})
    end
  end

  def move_prev(state = %State{}) do
    cursor = current_cursor(state)
    prev_id = get_in(state, [:prev, cursor.id, cursor.dimension])
    if prev_id do
      put_in(state, [:cursors, state.cursor_name, :id], prev_id)
    else
      add_error(state, {:no_prev_cell, cursor})
    end
  end

  def move_first(state = %State{}) do
    cursor = current_cursor(state)
    head_id = get_in(state, [:head, cursor.id, cursor.dimension])
    if head_id do
      put_in(state, [:cursors, state.cursor_name, :id], head_id)
    else
      add_error(state, {:no_head_cell, cursor})
    end
  end

  def move_last(state = %State{}) do
    cursor = current_cursor(state)
    cell = state.cells[cursor.id]
    path = path_ids(state, cell, cursor.dimension)
    last_id = Enum.at(path, -1)
    put_in(state, [:cursors, state.cursor_name, :id], last_id)
  end

  def go_home(state = %State{}) do
    put_in(state, [:cursors, state.cursor_name], %Cursor{id: state.origin.id, dimension: :home})
  end

  def connect_cursor(state = %State{}, other_cursor_name) do
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

  def add_and_move(state = %State{}, value) do
    cursor = current_cursor(state)
    cell = Cell.new(value, map_size(state.cells))
    from = state.cells[cursor.id]
    state
    |> put_in([:cells, cell.id], cell)
    |> connect(from, cell, cursor.dimension)
    |> move_next
  end


end