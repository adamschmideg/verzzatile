defmodule Verzzatile do
  @moduledoc """
  Documentation for `Verzzatile`.
  """

  defmodule ZZstructure do
    defstruct id_to_cell: %{}
  end

  defmodule Cell do
    defstruct id: nil, value: nil
  end

  defmodule FullCell do
    defstruct self: Cell, next: %{}, prev: %{}, head: %{}
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
      |> Enum.map(fn {cell1, cell2} -> connect(cell1, cell2, dimension, wait?: false) end)
    cells
  end

  def get(%{id: id}), do: get(id)
  def get(id), do: GenServer.call(__MODULE__, {:get, id})

  def connect(from, to, dimension, wait? \\ true)
  def connect(%{id: from}, %{id: to}, dimension, wait?), do: connect(from, to, dimension, wait?)
  def connect(from_id, to_id, dimension, wait?) do
    GenServer.cast(__MODULE__, {:connect, self(), from_id, to_id, dimension})
    if wait? do
      receive do
        {:async_reply, response} -> response
      after
        5000 -> {:error, :timeout}
      end
    end
  end

  def next(%{id: id}, dimension), do: next(id, dimension)
  def next(id, dimension), do: GenServer.call(__MODULE__, {:next, id, dimension})

  def prev(%{id: id}, dimension), do: prev(id, dimension)
  def prev(id, dimension), do: GenServer.call(__MODULE__, {:prev, id, dimension})

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
  def handle_cast({:connect, caller_pid, cell1_id, cell2_id, dimension}, state) do
    next_cell = get_in(state, [cell1_id, :next, dimension])
    prev_cell = get_in(state, [cell2_id, :prev, dimension])
    if next_cell != nil or prev_cell != nil do
      send(caller_pid, {:async_reply, {:error, {:already_connected, next_cell || prev_cell}}})
      {:noreply, state}
    else
      updated_state = state
        |> update_in([cell1_id, :next, dimension], fn _ -> cell2_id end)
        |> update_in([cell2_id, :prev, dimension], fn _ -> cell1_id end)
      send(caller_pid, {:async_reply, :ok})
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
