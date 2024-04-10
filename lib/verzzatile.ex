defmodule Verzzatile do
  @moduledoc """
  Documentation for `Verzzatile`.
  """

  defmodule Cell do
    defstruct id: nil, value: nil

    def new(value) do
      %Cell{id: :rand.uniform(1000_000_000), value: value}
    end
  end

  defmodule FullCell do
    defstruct self: Cell, next: %{}, prev: %{}, head: %{}

    def new(cell) do
      %FullCell{self: cell, next: %{}, prev: %{}, head: %{}}
    end

    def fetch(%FullCell{} = struct, key) do
      case Map.fetch(struct, key) do
        {:ok, value} -> {:ok, value}
        :error -> :error
      end
    end

    def get_and_update(data, key, fun) when is_map(data) do
      if Map.has_key?(data, key) do
        old_value = Map.fetch!(data, key)
        {_, new_value} = fun.(old_value)
        {old_value, Map.put(data, key, new_value)}
      else
        {:error, data}
      end
    end
  end

  defmodule Cursor do
    defstruct id: nil, dimension: nil

    def fetch(%Cursor{} = struct, key) do
      case Map.fetch(struct, key) do
        {:ok, value} -> {:ok, value}
        :error -> :error
      end
    end

    def get_and_update(data, key, fun) when is_map(data) do
      if Map.has_key?(data, key) do
        old_value = Map.fetch!(data, key)
        {_, new_value} = fun.(old_value)
        {old_value, Map.put(data, key, new_value)}
      else
        {:error, data}
      end
    end
  end

  defmodule State do
    defstruct cells: %{}, next: %{}, prev: %{}, errors: [], dimensions: %{}, cursors: %{}, origin: nil

    def new do
      origin = Cell.new(:origin)
      cursor = %Cursor{id: origin.id, dimension: :home}
      %State{cells: %{origin.id => origin},
             dimensions: %{home: 0},
             cursors: %{0 => cursor, 1 => cursor},
             origin: origin,
             next: %{},
             prev: %{},
             errors: []}
    end

    def fetch(%State{} = struct, key) do
      case Map.fetch(struct, key) do
        {:ok, value} -> {:ok, value}
        :error -> :error
      end
    end

    def get_and_update(data, key, fun) when is_map(data) do
      if Map.has_key?(data, key) do
        old_value = Map.fetch!(data, key)
        {_, new_value} = fun.(old_value)
        {old_value, Map.put(data, key, new_value)}
      else
        {:error, data}
      end
    end
  end

  defmodule Db do
    defp ensure_dimension(state, dimension) do
      if Map.has_key?(state.dimensions, dimension) do
        state
      else
        put_in(state, [:dimensions, dimension], map_size(state.dimensions))
      end
    end

    defp add_error(state, error) do
      put_in(state, [:errors], error)
    end

    defp connect(state, from, to, dimension) do
      next = get_in(state, [:next, from.id, dimension])
      prev = get_in(state, [:prev, to.id, dimension])
      cond do
        next != nil -> add_error(state, {:already_connected, from, next})
        prev != nil -> add_error(state, {:already_connected, prev, to})
        true ->
          new_next_ids = state.next[from.id] || %{} |> Map.put(dimension, to.id)
          new_prev_ids = state.prev[to.id] || %{} |> Map.put(dimension, from.id)
          updated_state = state
                          |> put_in([:next, from.id], new_next_ids)
                          |> put_in([:prev, to.id], new_prev_ids)
          updated_state
      end
    end

    def change_dimension(state, dimension) do
      updated_state = ensure_dimension(state, dimension)
      put_in(updated_state, [:cursors, 0, :dimension], dimension)
    end

    def move_next(state) do
      cursor = state.cursors[0]
      next_id = get_in(state, [:next, cursor.id, cursor.dimension])
      if next_id do
        put_in(state, [:cursors, 0, :id], next_id)
      else
        add_error(state, {:no_next_cell, cursor})
      end
    end

    def move_prev(state) do
      cursor = state.cursors[0]
      prev_id = get_in(state, [:prev, cursor.id, cursor.dimension])
      if prev_id do
        put_in(state, [:cursors, 0, :id], prev_id)
      else
        add_error(state, {:no_prev_cell, cursor})
      end
    end

    def move_first(state) do
      cursor = state.cursors[0]
      head_id = get_in(state, [:head, cursor.id, cursor.dimension])
      if head_id do
        put_in(state, [:cursors, 0, :id], head_id)
      else
        add_error(state, {:no_head_cell, cursor})
      end
    end

    def move_last(state) do
      cursor = state.cursors[0]
      cell = state.cells[cursor.id]
      path = path(state, cell, cursor.dimension)
      last = Enum.at(path, -1)
      put_in(state, [:cursors, 0, :id], last.id)
    end

    def go_home(state) do
      put_in(state, [:cursors, 0], state.origin)
        |> change_dimension(:home)
    end

    def swap_cursors(state) do
      cursor1 = state.cursors[0]
      cursor2 = state.cursors[1]
      put_in(state, [:cursors, 0], cursor2)
        |> put_in([:cursors, 1], cursor1)
    end

    def connect_cursors(state) do
      cursor1 = state.cursors[0]
      cursor2 = state.cursors[1]
      connect(state, cursor1, cursor2, cursor1.dimension)
    end

    def add_and_move(state, value) do
      cursor = state.cursors[0]
      cell = Cell.new(value)
      from = state.cells[cursor.id]
      state
        |> put_in([:cells, cell.id], cell)
        |> connect(from, cell, cursor.dimension)
        |> move_next
    end

    def path_values(state) do
      cursor = state.cursors[0]
      cell = state.cells[cursor.id]
      path(state, cell, cursor.dimension) |> Enum.map(fn cell -> cell.value end)
    end

    def full_path_values(state) do
      cursor = state.cursors[0]
      head_id = get_in(state, [:head, cursor.id, cursor.dimension])
      head = state.cells[head_id]
      path(state, head, cursor.dimension) |> Enum.map(fn cell -> cell.value end)
    end

    def show_cursor(state) do
      cursor = state.cursors[0]
      cell = state.cells[cursor.id]
      {cursor.dimension, cell.value}
    end

    defp path(state, cell = %Cell{}, dimension) do
      Enum.reduce_while([cell], nil, fn cell, _acc ->
        next_id = get_in(state, [:next, cell.id, dimension])
        case next_id do
          nil -> {:halt, cell}
          _ -> {:cont, state.cells[next_id]}
        end
      end)
    end

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

  def add_many(values, dimension) do
    cells = Enum.map(values, fn value -> add(value) end)
    cells
      |> Enum.zip(Enum.drop(cells, 1))
      |> Enum.map(fn {cell1, cell2} -> connect(cell1, cell2, dimension, wait?: false) end)
    cells
  end

  def get(%Cell{id: id}), do: get(id)
  def get(id), do: GenServer.call(__MODULE__, {:get, id})

  def connect(from, to, dimension, wait? \\ true)
  def connect(%Cell{id: from}, %Cell{id: to}, dimension, wait?), do: connect(from, to, dimension, wait?)
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

  def next(%Cell{id: id}, dimension), do: next(id, dimension)
  def next(id, dimension), do: GenServer.call(__MODULE__, {:next, id, dimension})

  def prev(%Cell{id: id}, dimension), do: prev(id, dimension)
  def prev(id, dimension), do: GenServer.call(__MODULE__, {:prev, id, dimension})

  def head(cell = %Cell{}, dimension) do
    Enum.reduce_while([cell], nil, fn cell, _acc ->
      prev_cell = prev(cell, dimension)
      case prev_cell do
        nil -> {:halt, cell}
        _ -> {:cont, prev_cell}
      end
    end)
  end
  def head(id, dimension), do: head(get(id), dimension)

  @doc """
  Returns the cells connected to the given cell in the given dimension.
  """
  def full_path(%Cell{id: id}, dimension), do: full_path(id, dimension)
  def full_path(id, dimension) do
    head = head(id, dimension)
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
  def handle_cast({:add, cell = %Cell{}}, state) do
    full_cell = FullCell.new(cell)
    updated_state = Map.put(state, cell.id, full_cell)
    {:noreply, updated_state}
  end

  @impl true
  def handle_cast({:connect, caller_pid, from_id, to_id, dimension}, state) do
    next_cell = get_in(state, [from_id, :next, dimension])
    prev_cell = get_in(state, [to_id, :prev, dimension])
    if next_cell != nil or prev_cell != nil do
      send(caller_pid, {:async_reply, {:error, {:already_connected, next_cell || prev_cell}}})
      {:noreply, state}
    else
      updated_state = state
        |> put_in([from_id, :next, dimension], to_id)
        |> put_in([to_id, :prev, dimension], from_id)
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
    full_cell = state[cell_id]
    next_cell_id = full_cell.next[dimension]
    {:reply, get_in(state, [next_cell_id, :self]), state}
  end

  @impl true
  def handle_call({:prev, cell_id, dimension}, _from, state) do
    id = get_in(state, [cell_id, :prev, dimension])
    cell = get_in(state, [id, :self])
    {:reply, cell, state}
  end

end
