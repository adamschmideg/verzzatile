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

  # Server Callbacks

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:add, cell_id, value}, state) do
    updated_state = Map.put(state, cell_id, %{self: %{value: value, id: cell_id}})
    {:noreply, updated_state}
  end

  @impl true
  def handle_cast({:connect, cell1, cell2, dimension}, state) do
    updated_state = Map.put(state, cell1.id, cell1)
    updated_state = Map.put(updated_state, cell2.id, cell2)
    {:noreply, updated_state}
  end

  @impl true
  def handle_call({:get, cell_id}, _from, state) do
    {:reply, get_in(state, [cell_id, :self]), state}
  end

end
