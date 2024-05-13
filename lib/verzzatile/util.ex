defmodule Verzzatile.Util do
  alias Verzzatile.{Cell, State}

  defp get_path_ids(state = %State{}, id, dimension, acc) do
    next_id = next_id(state, id, dimension)
    case next_id do
      nil -> Enum.reverse(acc)
      _ -> get_path_ids(state, next_id, dimension, [next_id | acc])
    end
  end

  def next_id(state = %State{}, id, dimension) do
    next = get_in(state, [:next, id, dimension])
    if next == get_in(state, [:head, id, dimension]) do
      nil
    else
      next
    end
  end

  def current_cursor(state) do
    state.cursors[state.cursor_name]
  end

  def path_ids(state = %State{}, cell = %Cell{}, dimension) do
    get_path_ids(state, cell.id, dimension, [cell.id])
  end

end