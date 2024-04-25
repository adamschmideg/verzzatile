defmodule Console do
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
      loop(state)
    end

    def loop(state) do
      IO.puts("Enter a command:")
      case String.trim(IO.gets("> ")) |> String.split() do
        [command | args] ->
          case String.to_atom(command) do
            "quit" -> IO.puts("Goodbye!")
            function_name when function_name in @possible_functions ->
              new_state = apply(Functions, function_name, args)
              new_state |> Show.show() |> IO.puts()
              loop(new_state)
            _ ->
              IO.puts("Invalid function name. Use one of the following: #{@possible_functions}")
              loop(state)
          end
        _ ->
          IO.puts("Invalid input. Try again.")
          loop(state)
      end
    end

  end
end


Console.App.start()
