defmodule Verzzatile.Show do
  alias Verzzatile.Cell
  alias Verzzatile.Direction
  alias Verzzatile.State

  def extract_and_pad(list, element, left_count, right_count) when left_count > 0 and right_count > 0 do
    position = Enum.find_index(list, &(&1 == element))
    if position == nil do
      List.duplicate(nil, left_count) ++ [element] ++ List.duplicate(nil, right_count)
    else
      left_index = max(position - left_count, 0)
      left_side = Enum.slice(list, left_index, left_count)
      left_pad = List.duplicate(nil, left_count - length(left_side))
      right_index = min(position + 1, length(list))
      right_side = Enum.slice(list, right_index, right_count)
      right_pad = List.duplicate(nil, right_count - length(right_side))

      left_pad ++ left_side ++ [element] ++ right_side ++ right_pad
    end
  end

  def errors(state) do
    state.errors
  end

  defp head_id(_state = %State{}, id, nil, _dimension), do: id
  defp head_id(state = %State{}, _id, prev_id, dimension) do
    head_id(state, prev_id, get_in(state, [:prev, prev_id, dimension]), dimension)
  end
  def head_id(state = %State{}, id, dimension) do
    head_id(state, id, get_in(state, [:prev, id, dimension]), dimension)
  end

  def show_connected_cells(state = %State{}, cell, x_dimension, y_dimension) do
    show_connected_cells(state, cell, x_dimension, y_dimension, %Direction{left: 3, right: 3, up: 3, down: 3})
  end

  def show_connected_cells(state = %State{}, cell, x_dimension, y_dimension, view_window = %Direction{}) do
    head_id = get_in(state, [:head, cell.id, x_dimension])
    head = state.cells[head_id] || cell
    matrix = state
      |> path(head, x_dimension)
      |> extract_and_pad(cell, view_window.left, view_window.right)
      |> Enum.map(fn cell ->
           case cell do
              nil -> []
              _ -> path(state, cell, y_dimension)
            end
             |> extract_and_pad(cell, view_window.up, view_window.down) end)
    matrix
      |> update_in([Access.at(view_window.left), Access.at(view_window.up)], fn cell -> %{cell | value: "| #{cell.value} |"} end)
  end

  def matrix_to_string(matrix, cell_width \\ 10) do
    Enum.map(matrix, fn row ->
      Enum.map(row, fn cell ->
        case cell do
          nil -> String.duplicate(" ", cell_width)
          _ -> cell.value |> to_string |> String.pad_leading(cell_width)
        end
      end)
      |> Enum.join(" ")
    end)
    |> Enum.join("\n")
  end

  def show(state = %State{}) do
    cursor = current_cursor(state)
    cell = state.cells[cursor.id]
    show_connected_cells(state, cell, :planet, :moon, %Direction{left: 3, right: 3, up: 3, down: 3})
      |> matrix_to_string()
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

  def current_cursor(state) do
    state.cursors[state.cursor_name]
  end

  def next_id(state = %State{}, id, dimension) do
    next = get_in(state, [:next, id, dimension])
    if next == get_in(state, [:head, id, dimension]) do
      nil
    else
      next
    end
  end

  def path_ids(state = %State{}, cell = %Cell{}, dimension) do
    get_path_ids(state, cell.id, dimension, [cell.id])
  end

  def path(state = %State{}, cell=%Cell{}, dimension) do
    path_ids(state, cell, dimension)
    |> Enum.map(fn id -> state.cells[id] end)
  end

  defp get_path_ids(state = %State{}, id, dimension, acc) do
    next_id = next_id(state, id, dimension)
    case next_id do
      nil -> Enum.reverse(acc)
      _ -> get_path_ids(state, next_id, dimension, [next_id | acc])
    end
  end

end