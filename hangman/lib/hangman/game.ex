defmodule Hangman.Game do

  defstruct(
    turns_left: 7,
    state: :initializing,
    letters: [],
    used: MapSet.new()
  )
  
  def new_game() do
    new_game(Dictionary.random_word())
  end
  def new_game(word) do
    %Hangman.Game{
      letters: word |> String.codepoints
    }
  end

  def make_move(game = %{state: state}, _guess) when state in [:won, :lost] do
    game
  end
  def make_move(game, guess) do
    accept_move(game, guess, MapSet.member?(game.used, guess))
  end

  def tally(game) do
    %{
      state: game.state,
      turns_left: game.turns_left,
      letters: game.letters |> reveal_guessed(game.used)
    }
  end

  ####################################################
  
  defp accept_move(game, _guess, _already_guessed = true) do
    Map.put(game, :state, :already_used)
  end
  defp accept_move(game, guess, _already_guessed) do
    accept_new_move(game, guess, valid?(guess))
  end

  defp valid?(guess) do
    String.match?(guess, ~r/^[a-z]{1}$/)
  end

  defp accept_new_move(game, _guess, _valid = false) do
    Map.put(game, :state, :invalid_move)
  end
  defp accept_new_move(game, guess, _valid) do
    Map.put(game, :used, MapSet.put(game.used, guess))
    |> score_guess(Enum.member?(game.letters, guess))
  end

  defp score_guess(game, _good_guess = true) do
    new_state = MapSet.new(game.letters)
    |> MapSet.subset?(game.used)
    |> maybe_won
    Map.put(game, :state, new_state)
  end
  defp score_guess(game = %{ turns_left: 1 }, _not_good_guess) do
    %{ game |
       state: :lost,
       turns_left: 0
    }
  end
  defp score_guess(game = %{ turns_left: turns_left }, _not_good_guess) do
    %{ game |
       state: :bad_guess,
       turns_left: turns_left - 1
    }
  end
  
  defp reveal_guessed(letters, used) do
    letters
    |> Enum.map(fn (letter) ->
      reveal_letter(letter, MapSet.member?(used, letter))
    end)
  end

  defp reveal_letter(letter, _member = true), do: letter
  defp reveal_letter(_letter, _member), do: "_"

  defp maybe_won(true), do: :won
  defp maybe_won(_), do: :good_guess
end