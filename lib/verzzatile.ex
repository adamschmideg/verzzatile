defmodule Verzzatile do
  @moduledoc """
  Documentation for `Verzzatile`.
  """

  defmodule Cell do
    defstruct id: nil, value: nil

    def new(value) do
      id = "#{:rand.uniform 1000_000_000}"
      new_with_id(id, value)
    end

    def new_with_id(id, value) do
      %Cell{id: id, value: value}
    end

    def get_id(%{id: id}), do: id
    def get_id(id), do: id

  end

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
    cell = Cell.new(value)
    GenServer.cast(__MODULE__, {:add, cell})
    cell
  end

  def get(cell_or_id) do
    id = Cell.get_id(cell_or_id)
    cell = GenServer.call(__MODULE__, {:get, id})
    if cell == nil do
      {:error, :not_found}
    else
      {:ok, cell}
    end
  end

  # Server Callbacks

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:add, cell}, state) do
    updated_state = Map.put(state, cell.id, cell)
    {:noreply, updated_state}
  end

  @impl true
  def handle_call({:get, cell_id}, _from, state) do
    cell = Map.get(state, cell_id, nil)
    {:reply, cell, state}
  end

end
