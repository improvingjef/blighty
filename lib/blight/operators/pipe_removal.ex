defmodule Blight.Operators.PipeRemoval do
  @moduledoc """
  Removes steps from pipe operator chains.

  For `a |> b |> c`, generates mutants:
  - `a |> c` (remove middle step)
  - `a |> b` (remove last step)

  For `a |> b`, generates:
  - `a` (remove the pipe entirely)
  """

  @behaviour Blight.Operator

  @impl true
  def name, do: "PipeRemoval"

  @impl true
  def mutate(ast, file) do
    {_ast, mutants} =
      Macro.prewalk(ast, [], fn
        {:|>, meta, _args} = node, acc ->
          line = Keyword.get(meta, :line, 0)
          steps = collect_pipe_steps(node)

          new_mutants =
            if length(steps) >= 2 do
              generate_removals(steps, meta, file, line)
            else
              []
            end

          {node, acc ++ new_mutants}

        node, acc ->
          {node, acc}
      end)

    # Deduplicate: Macro.prewalk visits nested pipes too, producing duplicates
    mutants
    |> Enum.uniq_by(fn m -> {m.file, m.line, m.original, m.mutated} end)
  end

  defp collect_pipe_steps({:|>, _meta, [left, right]}) do
    collect_pipe_steps(left) ++ [right]
  end

  defp collect_pipe_steps(other), do: [other]

  defp generate_removals(steps, meta, file, line) do
    count = length(steps)

    if count == 2 do
      # a |> b -> just a
      original_str = steps |> build_pipe(meta) |> Macro.to_string()

      [
        %Blight.Mutant{
          file: file,
          line: line,
          original: original_str,
          mutated: Macro.to_string(hd(steps)),
          operator: name(),
          description: "removed pipe step",
          status: :pending
        }
      ]
    else
      # For 3+ steps, remove each intermediate step (indices 1..count-2)
      # and also remove the last step
      removals =
        for i <- 1..(count - 1) do
          remaining = List.delete_at(steps, i)
          original_str = steps |> build_pipe(meta) |> Macro.to_string()
          mutated_str = remaining |> build_pipe(meta) |> Macro.to_string()

          %Blight.Mutant{
            file: file,
            line: line,
            original: original_str,
            mutated: mutated_str,
            operator: name(),
            description: "removed pipe step #{i}",
            status: :pending
          }
        end

      removals
    end
  end

  defp build_pipe([single], _meta), do: single

  defp build_pipe([first | rest], meta) do
    Enum.reduce(rest, first, fn step, acc ->
      {:|>, meta, [acc, step]}
    end)
  end
end
