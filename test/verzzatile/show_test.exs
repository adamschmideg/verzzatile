defmodule Verzzatile.ShowTest do
  use ExUnit.Case
  use ExUnitProperties

  import Verzzatile.Show
  import StreamData

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
    check all state <- map_of(:integer, :map, min_size: 1) do
      start_id = Map.keys(state) |> List.first()
      dimension = Map.values(state) |> List.first() |> Map.keys() |> List.first()
      head_id = head_id(state, start_id, dimension)
      assert head_id == start_id, "head_id is not the first cell in the path"
    end
  end
end