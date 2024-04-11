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
    defstruct cells: %{}, next: %{}, prev: %{}, head: %{}, errors: [], dimensions: %{}, cursors: %{}, origin: nil, cursor_name: nil

    def new do
      origin = Cell.new(:origin)
      cursor = %Cursor{id: origin.id, dimension: :home}
      cursor_name = 0
      %State{cells: %{origin.id => origin},
             dimensions: %{home: 0},
             cursors: %{cursor_name => cursor},
             origin: origin,
             cursor_name: 0,
             next: %{},
             prev: %{},
             head: %{},
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

    def cursor(state, cursor_name) do
      state = %{state | cursor_name: cursor_name}
      if Map.has_key?(state.cursors, cursor_name) do
        state
      else
        put_in(state, [:cursors, cursor_name], %Cursor{id: state.origin.id, dimension: :home})
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
          head_id = get_in(state, [:head, from.id, dimension]) || from.id
          path = [from.id | path_ids(state, to, dimension)]
          change_head_ids(updated_state, path, head_id, dimension)
      end
    end

    defp change_head_ids(state, path, head_id, dimension) do
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
      path = path_ids(state, cell, cursor.dimension)
      last_id = Enum.at(path, -1)
      put_in(state, [:cursors, 0, :id], last_id)
    end

    def go_home(state) do
      put_in(state, [:cursors, state.cursor_name], state.origin)
        |> change_dimension(:home)
    end

    def connect_cursor(state, other_cursor_name) do
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

    def add_and_move(state, value) do
      cursor = current_cursor(state)
      cell = Cell.new(value)
      from = state.cells[cursor.id]
      state
        |> put_in([:cells, cell.id], cell)
        |> connect(from, cell, cursor.dimension)
        |> move_next
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

    defp current_cursor(state) do
      state.cursors[state.cursor_name]
    end

    def show_cursor(state) do
      cursor = current_cursor(state)
      cell = state.cells[cursor.id]
      {cursor.dimension, cell.value}
    end

    defp path_ids(state, cell = %Cell{}, dimension) do
      get_path_ids(state, cell.id, dimension, [cell.id])
    end

    defp get_path_ids(state, id, dimension, acc) do
      next_id = get_in(state, [:next, id, dimension])
      case next_id do
        nil -> Enum.reverse(acc)
        _ -> get_path_ids(state, next_id, dimension, [next_id | acc])
      end
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
