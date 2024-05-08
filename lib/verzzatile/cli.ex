defmodule Cli do
  alias Verzzatile.Db

  defmodule Functions do
    def add(state, value) do
      Db.add_and_move(state, value)
    end

  end

  defmodule App do
    import Functions

    alias Verzzatile.Show

    @possible_functions Functions.__info__(:functions) |> Enum.map(&Atom.to_string(elem(&1,0)))

    def start do
      state = Verzzatile.State.new()
      loop(state, "Enter a command")
    end

    def loop(state, message) do
      if message do
        IO.puts(message)
      end
      case IO.gets("> ") |> String.trim() |> String.split() do
        [] -> loop(state, nil)
        [command | args] ->
          case command do
            "quit" ->
              IO.puts("Goodbye!")
              System.halt(0)
            function_name when function_name in @possible_functions ->
              new_state = apply(Functions, String.to_atom(function_name), [state | args])
              new_state |> Show.show() |> IO.puts()
              loop(new_state, nil)
            function_name ->
              loop(state, "Invalid function name `#{function_name}`. Use one of the following: #{@possible_functions}")
          end
      end
    end

  end
end


Cli.App.start()
