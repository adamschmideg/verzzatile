defmodule Verzzatile do
  @moduledoc """
  Documentation for `Verzzatile`.
  """

  defmodule ZZstructure do
    defstruct id_to_cell: %{}
  end

  use GenServer

  # Client API

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  defp get_id(cell_or_id) do
    case cell_or_id do
      %{} -> cell_or_id[:id]
      _ -> cell_or_id
    end
  end

  @doc """
  Wraps the value in a cell, stores it, and returns the cell.
  """
  def add(value) do
    cell = %{id: :rand.uniform(1000_000_000), value: value}
    GenServer.cast(__MODULE__, {:add, cell})
    cell
  end

  def add_many(values, dimension) do
    cells = Enum.map(values, fn value -> add(value) end)
    cells
      |> Enum.zip(Enum.drop(cells, 1))
      |> Enum.map(fn {cell1, cell2} -> connect(cell1, cell2, dimension) end)
    cells
  end

  def get(cell_or_id) do
    GenServer.call(__MODULE__, {:get, get_id(cell_or_id)})
  end

  def connect(cell_or_id1, cell_or_id2, dimension) do
    GenServer.cast(__MODULE__, {:connect, get_id(cell_or_id1), get_id(cell_or_id2), dimension})
  end

  def next(cell_or_id, dimension) do
    GenServer.call(__MODULE__, {:next, get_id(cell_or_id), dimension})
  end

  def prev(cell_or_id, dimension) do
    GenServer.call(__MODULE__, {:prev, get_id(cell_or_id), dimension})
  end


  def head(cell_or_id, dimension) do
    cell_id = get_id(cell_or_id)
    cell = get(cell_id)
    Enum.reduce_while([cell], nil, fn cell, _acc ->
      prev_cell = prev(cell, dimension)
      case prev_cell do
        nil -> {:halt, cell}
        _ -> {:cont, prev_cell}
      end
    end)
  end

  @doc """
  Returns the cells connected to the given cell in the given dimension.
  """
  def full_path(cell_or_id, dimension) do
    head = head(cell_or_id, dimension)
    full_path_from_head(head, dimension)
  end

  defp full_path_from_head(head, dimension) do
    next = next(head, dimension)
    case next do
      nil -> [head]
      _ -> [head | full_path_from_head(next, dimension)]
    end
  end

  # Server Callbacks

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:add, cell}, state) do
    full_cell = %{self: cell, next: %{}, prev: %{}}
    updated_state = Map.put(state, cell[:id], full_cell)
    {:noreply, updated_state}
  end

  @impl true
  def handle_cast({:connect, cell1_id, cell2_id, dimension}, state) do
    cond do
      (value = get_in(state, [cell1_id, :next, dimension])) != nil ->
        {:error, {:cell1_next_not_nil, value}}

      (value = get_in(state, [cell2_id, :prev, dimension])) != nil ->
        {:error, {:cell2_prev_not_nil, value}}

      true ->
        updated_state = state
          |> update_in([cell1_id, :next, dimension], fn _ -> cell2_id end)
          |> update_in([cell2_id, :prev, dimension], fn _ -> cell1_id end)
        {:noreply, updated_state}
    end
  end

  @impl true
  def handle_call({:get, cell_id}, _from, state) do
    {:reply, get_in(state, [cell_id, :self]), state}
  end

  @impl true
  def handle_call({:next, cell_id, dimension}, _from, state) do
    id = get_in(state, [cell_id, :next, dimension])
    cell = get_in(state, [id, :self])
    {:reply, cell, state}
  end

  @impl true
  def handle_call({:prev, cell_id, dimension}, _from, state) do
    id = get_in(state, [cell_id, :prev, dimension])
    cell = get_in(state, [id, :self])
    {:reply, cell, state}
  end

end
