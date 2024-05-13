defmodule Cli do
  alias Verzzatile.{Store, Show, State}

  defmodule Functions do
    def add(state, value) do
      Store.add_and_move(state, value)
    end

    def solar(_state) do
      state = State.new()
        |> Store.change_dimension(:planet)
        |> Store.add_and_move("Mercury")
        |> Store.add_and_move("Venus")
        |> Store.add_and_move("Earth")
        |> Store.change_dimension(:moon)
        |> Store.add_and_move("Luna")
        |> Store.move_prev()
        |> Store.change_dimension(:planet)
        |> Store.add_and_move("Mars")
        |> Store.change_dimension(:moon)
        |> Store.add_and_move("Phobos")
        |> Store.add_and_move("Deimos")
        |> Store.move_first()
        |> Store.change_dimension(:planet)
        |> Store.add_and_move("Jupiter")
      earth = state |> Store.move_first() |> Store.move_next() |> Store.move_next() |> Store.move_next()
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
