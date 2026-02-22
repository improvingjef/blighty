defmodule Blight.Reporter do
  @moduledoc """
  Console reporter with ANSI colors for mutation testing results.
  """

  @doc """
  Prints the initial banner and mutant count.
  """
  @spec start(non_neg_integer()) :: :ok
  def start(total) do
    IO.puts("")
    IO.puts(IO.ANSI.bright() <> "  Blighty - Mutation Testing" <> IO.ANSI.reset())

    IO.puts(
      IO.ANSI.faint() <>
        "  That which doesn't kill you makes you stronger." <> IO.ANSI.reset()
    )

    IO.puts("")
    IO.puts("  Found #{total} mutant(s) to test.")
    IO.puts("")
    :ok
  end

  @doc """
  Prints progress for a single mutant result.
  """
  @spec progress(Blight.Mutant.t()) :: :ok
  def progress(%Blight.Mutant{} = mutant) do
    status_str = format_status(mutant.status)
    location = "#{mutant.file}:#{mutant.line}"
    IO.puts("  #{status_str}  #{location}  #{mutant.operator}: #{mutant.description}")
    :ok
  end

  @doc """
  Prints the final summary report.
  """
  @spec summary(Blight.Runner.results()) :: :ok
  def summary(results) do
    IO.puts("")
    IO.puts("  " <> String.duplicate("\u2500", 50))
    IO.puts("")

    IO.puts(
      "  Results: #{results.total} mutants, " <>
        "#{results.killed} killed, " <>
        "#{results.survived} survived, " <>
        "#{results.timeout} timeout, " <>
        "#{results.errored} errors"
    )

    score_color =
      cond do
        results.score >= 80.0 -> IO.ANSI.green()
        results.score >= 60.0 -> IO.ANSI.yellow()
        true -> IO.ANSI.red()
      end

    IO.puts("  Mutation score: #{score_color}#{Float.round(results.score, 1)}%#{IO.ANSI.reset()}")

    duration_s = results.duration_ms / 1000.0
    IO.puts("  Duration: #{Float.round(duration_s, 1)}s")

    IO.puts("")
    IO.puts("  " <> String.duplicate("\u2500", 50))

    # Show surviving mutants
    survivors = Enum.filter(results.mutants, &(&1.status == :survived))

    if survivors != [] do
      IO.puts("")

      IO.puts(IO.ANSI.red() <> IO.ANSI.bright() <> "  Surviving mutants:" <> IO.ANSI.reset())

      IO.puts("")

      Enum.each(survivors, fn mutant ->
        IO.puts("    #{mutant.file}:#{mutant.line}")
        IO.puts("    #{mutant.operator}: #{mutant.description}")
        IO.puts("    Original: #{mutant.original}")
        IO.puts("    Mutated:  #{mutant.mutated}")
        IO.puts("")
      end)
    end

    :ok
  end

  defp format_status(:killed) do
    IO.ANSI.green() <> "[KILLED]" <> IO.ANSI.reset() <> "   "
  end

  defp format_status(:survived) do
    IO.ANSI.red() <> "[SURVIVED]" <> IO.ANSI.reset() <> " "
  end

  defp format_status(:timeout) do
    IO.ANSI.yellow() <> "[TIMEOUT]" <> IO.ANSI.reset() <> "  "
  end

  defp format_status(:error) do
    IO.ANSI.magenta() <> "[ERROR]" <> IO.ANSI.reset() <> "    "
  end

  defp format_status(:pending) do
    IO.ANSI.faint() <> "[PENDING]" <> IO.ANSI.reset() <> "  "
  end
end
