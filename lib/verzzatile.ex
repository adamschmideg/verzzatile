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
  end

  @doc """
  Wraps the value in a cell and returns the cell.
  """
  def add(value) do
    cell = Cell.new(value)
    cell
  end

  def get(cell_or_id) do
    id = if is_map(cell_or_id) do
           cell_or_id.id
         else
           cell_or_id
         end
    cell_or_id
  end

end
