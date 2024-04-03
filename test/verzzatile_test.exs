defmodule VerzzatileTest do
  use ExUnit.Case
  doctest Verzzatile

  test "Gets a cell that was added" do
    {:ok, _pid} = Verzzatile.start_link()
    cell = Verzzatile.add('value')
    assert 'value' = Verzzatile.get(cell.id).value
  end

  test "Connect two cells and check if they are connected" do
    {:ok, _pid} = Verzzatile.start_link()
    cell1 = Verzzatile.add('value1')
    cell2 = Verzzatile.add('value2')
    assert :ok = Verzzatile.connect(cell1, cell2, :friend)
    assert cell2 == Verzzatile.next(cell1, :friend)
    assert is_nil Verzzatile.next(cell2, :friend)
    assert cell1 == Verzzatile.prev(cell2, :friend)
    assert is_nil Verzzatile.prev(cell1, :friend)
  end

  test "Connected cells are not connected in other dimensions" do
    {:ok, _pid} = Verzzatile.start_link()
    cell1 = Verzzatile.add('value1')
    cell2 = Verzzatile.add('value2')
    assert :ok = Verzzatile.connect(cell1, cell2, :friend)
    assert is_nil Verzzatile.next(cell1, :enemy)
    assert is_nil Verzzatile.prev(cell2, :enemy)
  end

  test "Cell can connect to itself" do
    {:ok, _pid} = Verzzatile.start_link()
    cell = Verzzatile.add('value')
    assert :ok = Verzzatile.connect(cell, cell, :friend)
    assert cell == Verzzatile.next(cell, :friend)
    assert cell == Verzzatile.prev(cell, :friend)
  end

  test "Add many cells and connect them" do
    {:ok, _pid} = Verzzatile.start_link()
    cells = Verzzatile.add_many(['value1', 'value2', 'value3'], :friend)
    get_value = fn %{value: value} -> value end
    values = Enum.map(cells, fn cell -> cell |> Verzzatile.get |> get_value.() end)
    assert ['value1', 'value2', 'value3'] == values
  end

  test "Get head cell of a given cell in a given dimension" do
    {:ok, _pid} = Verzzatile.start_link()
    cells = Verzzatile.add_many(['value1', 'value2', 'value3'], :friend)
    mid_cell = Enum.at(cells, 1)
    head = Verzzatile.head(mid_cell, :friend)
    assert head == Enum.at(cells, 0)
  end

  test "Full path of a cell returns cells connected to it in a given dimension" do
    {:ok, _pid} = Verzzatile.start_link()
    cells = Verzzatile.add_many(['value1', 'value2', 'value3'], :friend)
    mid_cell = Enum.at(cells, 1)
    path = Verzzatile.full_path(mid_cell, :friend)
    IO.inspect(path)
    assert ['value1', 'value2', 'value3'] == path
  end
end
