ExUnit.start()

defmodule TestHelper do
  import StreamData
  alias Verzzatile.{Store, State}

  @cursors [:origin, :home, :friend, :enemy, :travel]

  @operations %{
    :cursor => @cursors,
    :move_next => nil,
    :move_prev => nil,
    :move_first => nil,
    :move_last => nil,
    :go_home => nil,
    :connect_cursor => @cursors,
    :add_and_move => ["Fred", "Wilma", "Barney", "Betty"],
    :change_dimension => [:east, :west, :north, :south]
  }

  def operation_gen() do
    @operations
    |> Map.keys()
    |> Enum.map(&constant(&1))
    |> one_of()
    |> StreamData.map(fn f -> if args = @operations[f], do: {f, Enum.random(args)}, else: {f, nil} end)
  end

  def apply_operations(operations, state \\ nil) do
    initial_state = state || State.new()
    Enum.reduce(operations, initial_state, fn {op, args}, acc_state ->
      if args == nil do
        apply(Store, op, [acc_state])
      else
        apply(Store, op, [acc_state, args])
      end
    end)
  end

end