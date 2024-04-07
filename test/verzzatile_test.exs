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

  test "Cannot connect cells already connected" do
    {:ok, _pid} = Verzzatile.start_link()
    [c1, _, c3] = Verzzatile.add_many(['value1', 'value2', 'value3'], :friend)
    new_cell = Verzzatile.add('value4')
    assert {:error, {:already_connected, _}} = Verzzatile.connect(c1, c3, :friend)
    assert {:error, {:already_connected, _}} = Verzzatile.connect(c1, new_cell, :friend)
    assert {:error, {:already_connected, _}} = Verzzatile.connect(new_cell, c3, :friend)
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
    assert ['value1', 'value2', 'value3'] == Enum.map(cells, fn cell -> cell.value end)
  end

  test "You can create a loop" do
    {:ok, _pid} = Verzzatile.start_link()
    [c1, _c2, c3] = Verzzatile.add_many(['value1', 'value2', 'value3'], :friend)
    assert :ok = Verzzatile.connect(c3, c1, :friend)
    assert c1 == Verzzatile.next(c3, :friend)
    assert c3 == Verzzatile.prev(c1, :friend)
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
    assert cells == path
  end

  @tag :skip
  test "Full path of a looped cell returns all cells in the loop" do
    {:ok, _pid} = Verzzatile.start_link()
    [c1, c2, c3] = Verzzatile.add_many(['value1', 'value2', 'value3'], :friend)
    Verzzatile.connect(c3, c1, :friend)
    path = Verzzatile.full_path(c1, :friend)
    assert [c1, c2, c3] == path
  end

end
