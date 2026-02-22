defmodule Blight do
  @moduledoc """
  Mutation testing for Elixir.

  That which doesn't kill you makes you stronger.

  Blight introduces small faults (mutants) into your source code and runs your
  test suite to see if the tests catch the change. Mutants that are caught are
  "killed"; those that slip through have "survived", exposing gaps in test
  coverage.

  ## Usage

      mix blight

  ## Programmatic API

      config = Blight.Config.load()
      results = Blight.Runner.run(config)
      Blight.Reporter.report(results)
  """

  @doc """
  Runs mutation testing with the given config (or defaults) and returns results.
  """
  @spec run(Blight.Config.t()) :: Blight.Runner.results()
  def run(config \\ Blight.Config.load()) do
    Blight.Runner.run(config)
  end

  @doc """
  Returns all available mutation operators.
  """
  @spec operators() :: [module()]
  def operators do
    [
      Blight.Operators.Arithmetic,
      Blight.Operators.Relational,
      Blight.Operators.Logical,
      Blight.Operators.PipeRemoval,
      Blight.Operators.PatternMatch,
      Blight.Operators.Literal,
      Blight.Operators.StatementDeletion,
      Blight.Operators.Conditional
    ]
  end
end
