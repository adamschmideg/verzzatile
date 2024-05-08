defmodule Cli do
  alias Verzzatile.{Db, Show, State}

  defmodule Functions do
    def add(state, value) do
      Db.add_and_move(state, value)
    end

    def solar(_state) do
      state = State.new()
        |> Db.change_dimension(:planet)
        |> Db.add_and_move("Mercury")
        |> Db.add_and_move("Venus")
        |> Db.add_and_move("Earth")
        |> Db.change_dimension(:moon)
        |> Db.add_and_move("Luna")
        |> Db.move_prev()
        |> Db.change_dimension(:planet)
        |> Db.add_and_move("Mars")
        |> Db.change_dimension(:moon)
        |> Db.add_and_move("Phobos")
        |> Db.add_and_move("Deimos")
        |> Db.move_first()
        |> Db.change_dimension(:planet)
        |> Db.add_and_move("Jupiter")
      earth = state |> Db.move_first() |> Db.move_next() |> Db.move_next() |> Db.move_next()
      earth
    end

  end

  defmodule App do
    import Functions

    alias Verzzatile.Show

    @possible_functions Functions.__info__(:functions) |> Enum.map(&Atom.to_string(elem(&1,0)))

    def start do
      state = Functions.solar(nil)
      loop(state, "Enter a command", true)
    end

    def loop(state, message, show_state) do
      if show_state do
        state |> Show.show() |> IO.puts()
      end
      if message do
        IO.puts(message)
      end
      case IO.gets("> ") |> String.trim() |> String.split() do
        [] -> loop(state, nil, false)
        [command | args] ->
          case command do
            "quit" ->
              IO.puts("Goodbye!")
              System.halt(0)
            function_name when function_name in @possible_functions ->
              new_state = apply(Functions, String.to_atom(function_name), [state | args])
              loop(new_state, nil, true)
            function_name ->
              loop(state, "Invalid function name `#{function_name}`. Use one of the following: #{@possible_functions}", false)
          end
      end
    end

  end
end


Cli.App.start()
