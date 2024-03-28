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

  @doc """
  Wraps the value in a cell and returns the cell.
  """
  def add(value) do
    cell = Cell.new(value)
    cell
  end

  def get(cell_or_id) do
    id = Cell.get_id(cell_or_id)
    {:ok, cell_or_id}
  end

end
