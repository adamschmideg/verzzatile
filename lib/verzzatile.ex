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
    GenServer.cast(__MODULE__, {:add, cell, value})
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
    cell = GenServer.call(__MODULE__, {:get, get_id(cell_or_id)})
    case cell do
      nil -> {:error, :not_found}
      _ -> {:ok, cell}
    end
  end

  def connect(cell_or_id1, cell_or_id2, dimension) do
    GenServer.cast(__MODULE__, {:connect, get_id(cell_or_id1), get_id(cell_or_id2), dimension})
  end

  def next_id(cell_or_id, dimension) do
    GenServer.call(__MODULE__, {:next, get_id(cell_or_id), dimension})
  end

  def prev_id(cell_or_id, dimension) do
    GenServer.call(__MODULE__, {:prev, get_id(cell_or_id), dimension})
  end


  def head_cell(cell_or_id, dimension) do
    cell_id = get_id(cell_or_id)
    Enum.reduce_while([cell_id], nil, fn cell_id, acc ->
      prev_cell_id = prev_id(cell_id, dimension)
      case prev_cell_id do
        nil -> {:halt, cell_id}
        _ -> {:cont, prev_cell_id}
      end
    end)
  end

  @doc """
  Returns the cells connected to the given cell in the given dimension.
  """
  def full_path(cell_or_id, dimension) do
    cell_id = get_id(cell_or_id)
    head = head_cell(cell_id, dimension)
    Enum.reduce_while([head], [], fn cell_id, acc ->
      next_cell_id = next_id(cell_id, dimension)
      case next_cell_id do
        nil -> {:halt, acc}
        _ -> {:cont, [next_cell_id | acc]}
      end
    end)
  end

  # Server Callbacks

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:add, cell, value}, state) do
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
    {:reply, get_in(state, [cell_id, :next, dimension]), state}
  end

  @impl true
  def handle_call({:prev, cell_id, dimension}, _from, state) do
    {:reply, get_in(state, [cell_id, :prev, dimension]), state}
  end

end
