defmodule VerzzatileTest do
  use ExUnit.Case
  doctest Verzzatile

  test "Gets a cell that was added" do
    {:ok, _pid} = Verzzatile.start_link()
    cell = Verzzatile.add('value')
    assert {:ok, cell_got} = Verzzatile.get(cell.id)
    assert cell_got.value == 'value'
  end

  test "Connect two cells and check if they are connected" do
    {:ok, _pid} = Verzzatile.start_link()
    cell1 = Verzzatile.add('value1')
    cell2 = Verzzatile.add('value2')
    assert :ok = Verzzatile.connect(cell1, cell2, :friend)
    assert cell2.id == Verzzatile.next_id(cell1, :friend)
    assert is_nil Verzzatile.next_id(cell2, :friend)
    assert cell1.id == Verzzatile.prev_id(cell2, :friend)
    assert is_nil Verzzatile.prev_id(cell1, :friend)
  end

  test "Connected cells are not connected in other dimensions" do
    {:ok, _pid} = Verzzatile.start_link()
    cell1 = Verzzatile.add('value1')
    cell2 = Verzzatile.add('value2')
    assert :ok = Verzzatile.connect(cell1, cell2, :friend)
    assert is_nil Verzzatile.next_id(cell1, :enemy)
    assert is_nil Verzzatile.prev_id(cell2, :enemy)
  end

  test "Cell can connect to itself" do
    {:ok, _pid} = Verzzatile.start_link()
    cell = Verzzatile.add('value')
    assert :ok = Verzzatile.connect(cell, cell, :friend)
    assert cell.id == Verzzatile.next_id(cell, :friend)
    assert cell.id == Verzzatile.prev_id(cell, :friend)
  end

  test "Add many cells and connect them" do
    {:ok, _pid} = Verzzatile.start_link()
    cells = Verzzatile.add_many(['value1', 'value2', 'value3'], :friend)
    get_value = fn {:ok, %{value: value}} -> value end
    values = Enum.map(cells, fn cell -> cell |> Verzzatile.get |> get_value.() end)
    assert ['value1', 'value2', 'value3'] == values
  end

  test "Get head cell of a given cell in a given dimension" do
    {:ok, _pid} = Verzzatile.start_link()
    cells = Verzzatile.add_many(['value1', 'value2', 'value3'], :friend)
    mid_cell = Enum.at(cells, 1)
    head_id = Verzzatile.head_id(mid_cell, :friend)
    assert head_id == Enum.at(cells, 0).id
  end

  test "Full path of a cell returns cells connected to it in a given dimension" do
    {:ok, _pid} = Verzzatile.start_link()
    last_cell = Verzzatile.add_many(['value1', 'value2', 'value3'], :friend)
    path = Verzzatile.full_path(last_cell, :friend)
    values = path |> Enum.map(fn cell -> Verzzatile.get(cell) end)
    assert ['value1', 'value2', 'value3'] == values
  end
end
