defmodule Mix.Tasks.Blight do
  @moduledoc """
  Runs mutation testing on your project.

  ## Usage

      mix blight [options]

  ## Options

    * `--include` - Glob pattern for files to include (can be repeated)
    * `--exclude` - Glob pattern for files to exclude (can be repeated)
    * `--operators` - Comma-separated list of operators to use
    * `--parallel` - Number of parallel test runners

  ## Examples

      mix blight
      mix blight --include "lib/my_app/core/**/*.ex"
      mix blight --exclude "lib/my_app_web/**/*.ex"
      mix blight --operators arithmetic,relational,logical
      mix blight --parallel 4
  """

  use Mix.Task

  @shortdoc "Run mutation testing"

  @switches [
    include: :keep,
    exclude: :keep,
    operators: :string,
    parallel: :integer
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} = OptionParser.parse(args, strict: @switches)

    overrides = build_overrides(opts)
    config = Blight.Config.load(overrides)
    results = Blight.Runner.run(config)
    Blight.Reporter.summary(results)

    if results.survived > 0 do
      Mix.raise(
        "Blighty: #{results.survived} mutant(s) survived (score: #{Float.round(results.score, 1)}%)"
      )
    end
  end

  defp build_overrides(opts) do
    overrides = []

    overrides =
      case Keyword.get_values(opts, :include) do
        [] -> overrides
        includes -> Keyword.put(overrides, :include, includes)
      end

    overrides =
      case Keyword.get_values(opts, :exclude) do
        [] -> overrides
        excludes -> Keyword.put(overrides, :exclude, excludes)
      end

    overrides =
      case Keyword.get(opts, :operators) do
        nil ->
          overrides

        operator_str ->
          operators =
            operator_str
            |> String.split(",")
            |> Enum.map(&String.trim/1)
            |> Enum.map(&String.to_atom/1)

          Keyword.put(overrides, :operators, operators)
      end

    overrides =
      case Keyword.get(opts, :parallel) do
        nil -> overrides
        n -> Keyword.put(overrides, :parallelism, n)
      end

    overrides
  end
end
