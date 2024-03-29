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

  @doc """
  Wraps the value in a cell, stores it, and returns the cell.
  """
  def add(value) do
    cell_id = "#{:rand.uniform 1000_000_000}"
    GenServer.cast(__MODULE__, {:add, cell_id, value})
    cell_id
  end

  def get(cell_id) do
    cell = GenServer.call(__MODULE__, {:get, cell_id})
    if cell == nil do
      {:error, :not_found}
    else
      {:ok, cell}
    end
  end

  def connect(cell1, cell2, dimension) do
    GenServer.cast(__MODULE__, {:connect, cell1, cell2, dimension})
  end

  def next(cell, dimension) do
    GenServer.call(__MODULE__, {:next, cell, dimension})
  end

  def prev(cell, dimension) do
    GenServer.call(__MODULE__, {:prev, cell, dimension})
  end

  # Server Callbacks

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:add, cell_id, value}, state) do
    cell = %{self: %{value: value, id: cell_id}, next: %{}, prev: %{}}
    updated_state = Map.put(state, cell_id, cell)
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
