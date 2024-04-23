defmodule Verzzatile.ShowTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Verzzatile.{Db, Direction, Show}

  import Verzzatile.Show
  import StreamData

  import TestHelper

  property "extract_and_pad returns a list of correct length" do
    check all list <- list_of(integer(), min_length: 1, max_length: 100),
          pos <- integer(0..length(list) - 1),
          left_count <- integer(1..10),
          right_count <- integer(1..10) do
      element = Enum.at(list, pos)
      result = extract_and_pad(list, element, left_count, right_count)
      assert length(result) == left_count + 1 + right_count, "result length is not correct"
      assert Enum.at(result, left_count) == element, "element not in the middle of the result"
    end
  end

  property "Head ID is the first cell in the path" do
    check all operations <- list_of(operation_gen(), min_length: 1, max_length: 10) do
      state = apply_operations(operations)
      start_id = Map.keys(state) |> List.first()
      dimension = Map.values(state) |> List.first() |> Map.keys() |> List.first()
      head_id = head_id(state, start_id, dimension)
      assert head_id == start_id, "head_id is not the first cell in the path"
    end
  end

  property "Show connected cells" do
    # Problem with head: [add_and_move: "Betty", move_first: nil, change_dimension: :north, add_and_move: "Barney"]
    # Problem with head: [cursor: :enemy, connect_cursor: :enemy, change_dimension: :north, add_and_move: "Betty"]
    check all operations <- list_of(operation_gen(), min_length: 1, max_length: 10) do
      state = apply_operations(operations)
      Enum.each(state.next, fn {from_id, dim_to_id} ->
        Enum.each(dim_to_id, fn {dim, _to_id} ->
          assert get_in(state, [:head, from_id, dim])
        end)
      end)

      matrix = state
               |> Db.change_dimension(:east)
               |> Db.add_and_move("Italy")
               |> Db.go_home()
               |> Db.change_dimension(:north)
               |> Db.add_and_move("America")
               |> Db.change_dimension(:east)
               |> Show.show_connected_cells(state.origin, :east, :north, %Direction{left: 3, right: 3, up: 3, down: 3})

      assert Enum.at(Enum.at(matrix, 3), 3) == state.origin
    end
  end
end