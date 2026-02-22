defmodule Blight.Runner do
  @moduledoc """
  Orchestrates the mutation testing process.

  1. Loads config and finds source files
  2. Parses each file to AST
  3. Applies operators to generate mutants
  4. For each mutant: writes mutated file, runs tests, collects result, restores original
  5. Returns all mutant results
  """

  require Logger

  @type results :: %{
          mutants: [Blight.Mutant.t()],
          killed: non_neg_integer(),
          survived: non_neg_integer(),
          timeout: non_neg_integer(),
          errored: non_neg_integer(),
          total: non_neg_integer(),
          score: float(),
          duration_ms: non_neg_integer()
        }

  @doc """
  Runs mutation testing with the given configuration.
  """
  @spec run(Blight.Config.t()) :: results()
  def run(%Blight.Config{} = config) do
    start_time = System.monotonic_time(:millisecond)

    # First, get a baseline: do the tests pass without any mutations?
    base_timeout_ms = measure_baseline(config)

    timeout_ms = round(base_timeout_ms * config.timeout_multiplier)

    files = Blight.Config.source_files(config)
    mutants = generate_mutants(files, config.operators)

    Blight.Reporter.start(length(mutants))

    results =
      mutants
      |> Enum.map(fn mutant ->
        result = test_mutant(mutant, config.test_command, timeout_ms)
        Blight.Reporter.progress(result)
        result
      end)

    end_time = System.monotonic_time(:millisecond)

    compile_results(results, end_time - start_time)
  end

  @doc """
  Generates mutants for the given files using the given operators, without
  running any tests. Useful for previewing what mutations would be made.
  """
  @spec generate_mutants([String.t()], [module()]) :: [Blight.Mutant.t()]
  def generate_mutants(files, operators) do
    Enum.flat_map(files, fn file ->
      case File.read(file) do
        {:ok, source} ->
          case Code.string_to_quoted(source, file: file, columns: true) do
            {:ok, ast} ->
              Enum.flat_map(operators, fn operator ->
                operator.mutate(ast, file)
              end)

            {:error, _} ->
              Logger.warning("Blight: failed to parse #{file}, skipping")
              []
          end

        {:error, _} ->
          Logger.warning("Blight: failed to read #{file}, skipping")
          []
      end
    end)
  end

  defp measure_baseline(config) do
    start = System.monotonic_time(:millisecond)

    case run_tests(config.test_command, 120_000) do
      :passed ->
        elapsed = System.monotonic_time(:millisecond) - start
        max(elapsed, 5_000)

      _other ->
        Logger.warning("Blight: baseline test suite failed! Results may be unreliable.")
        30_000
    end
  end

  defp test_mutant(%Blight.Mutant{} = mutant, test_command, timeout_ms) do
    case Blight.SourceMutator.apply_to_file(mutant) do
      {:ok, original_content} ->
        result = run_tests(test_command, timeout_ms)
        Blight.SourceMutator.restore_file(mutant.file, original_content)

        status =
          case result do
            :passed -> :survived
            :failed -> :killed
            :timeout -> :timeout
            :error -> :error
          end

        %{mutant | status: status}

      {:error, reason} ->
        Logger.warning("Blight: could not apply mutant: #{reason}")
        %{mutant | status: :error}
    end
  end

  defp run_tests(test_command, timeout_ms) do
    [cmd | args] = String.split(test_command)

    task =
      Task.async(fn ->
        case System.cmd(cmd, args, stderr_to_stdout: true, env: [{"MIX_ENV", "test"}]) do
          {_output, 0} -> :passed
          {_output, _code} -> :failed
        end
      end)

    case Task.yield(task, timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> result
      nil -> :timeout
    end
  rescue
    _ -> :error
  end

  defp compile_results(mutants, duration_ms) do
    killed = Enum.count(mutants, &(&1.status == :killed))
    survived = Enum.count(mutants, &(&1.status == :survived))
    timeout = Enum.count(mutants, &(&1.status == :timeout))
    errored = Enum.count(mutants, &(&1.status == :error))
    total = length(mutants)

    score =
      if total > 0 do
        (killed + timeout) / total * 100.0
      else
        100.0
      end

    %{
      mutants: mutants,
      killed: killed,
      survived: survived,
      timeout: timeout,
      errored: errored,
      total: total,
      score: score,
      duration_ms: duration_ms
    }
  end
end
