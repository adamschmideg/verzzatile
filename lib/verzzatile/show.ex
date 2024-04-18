defmodule Verzzatile.Show do

  def extract_and_pad(list, element, left_count, right_count) when left_count > 0 and right_count > 0 do
    position = Enum.find_index(list, &(&1 == element))
    left_index = max(position - left_count, 0)
    left_side = Enum.slice(list, left_index, left_count)
    left_pad = List.duplicate(nil, left_count - length(left_side))
    right_index = min(position + 1, length(list))
    right_side = Enum.slice(list, right_index, right_count)
    right_pad = List.duplicate(nil, right_count - length(right_side))

    left_pad ++ left_side ++ [element] ++ right_side ++ right_pad
  end

end