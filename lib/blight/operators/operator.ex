defmodule Blight.Operator do
  @moduledoc """
  Behaviour for mutation operators.

  Each operator traverses the Elixir AST to find opportunities for mutation,
  returning a list of `Blight.Mutant` structs describing each possible change.
  """

  @doc """
  Returns the human-readable name of this operator.
  """
  @callback name() :: String.t()

  @doc """
  Analyzes the given AST and returns a list of possible mutants.

  The AST is produced by `Code.string_to_quoted!/2` and the file path is
  provided for inclusion in the mutant struct.
  """
  @callback mutate(ast :: Macro.t(), file :: String.t()) :: [Blight.Mutant.t()]
end
