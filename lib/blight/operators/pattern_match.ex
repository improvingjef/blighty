defmodule Blight.Operators.PatternMatch do
  @moduledoc """
  Simplifies pattern matches and removes guard clauses.

  - `{:ok, value}` in function heads / case clauses -> `_`
  - Removes `when guard` from function definitions
  """

  @behaviour Blight.Operator

  @impl true
  def name, do: "PatternMatch"

  @impl true
  def mutate(ast, file) do
    guard_mutants = find_guard_removals(ast, file)
    pattern_mutants = find_pattern_simplifications(ast, file)
    guard_mutants ++ pattern_mutants
  end

  defp find_guard_removals(ast, file) do
    {_ast, mutants} =
      Macro.prewalk(ast, [], fn
        {:when, meta, _args} = node, acc ->
          line = Keyword.get(meta, :line, 0)

          mutant = %Blight.Mutant{
            file: file,
            line: line,
            original: Macro.to_string(node),
            mutated: "(guard removed)",
            operator: name(),
            description: "removed guard clause",
            status: :pending
          }

          {node, [mutant | acc]}

        node, acc ->
          {node, acc}
      end)

    Enum.reverse(mutants)
  end

  defp find_pattern_simplifications(ast, file) do
    {_ast, mutants} =
      Macro.prewalk(ast, [], fn
        {:{}, meta, _elements} = node, acc ->
          line = Keyword.get(meta, :line, 0)

          mutant = %Blight.Mutant{
            file: file,
            line: line,
            original: Macro.to_string(node),
            mutated: "_",
            operator: name(),
            description: "simplified tuple pattern to wildcard",
            status: :pending
          }

          {node, [mutant | acc]}

        {a, b} = node, acc when not is_atom(a) or a not in [:__block__, :do, :|>] ->
          # Two-element tuple that looks like a pattern
          meta_line = extract_line({a, b})

          if meta_line > 0 do
            mutant = %Blight.Mutant{
              file: file,
              line: meta_line,
              original: Macro.to_string(node),
              mutated: "_",
              operator: name(),
              description: "simplified tuple pattern to wildcard",
              status: :pending
            }

            {node, [mutant | acc]}
          else
            {node, acc}
          end

        node, acc ->
          {node, acc}
      end)

    Enum.reverse(mutants)
  end

  defp extract_line({_a, b}) when is_list(b), do: Keyword.get(b, :line, 0)

  defp extract_line({a, _b}) do
    case a do
      {_, meta, _} when is_list(meta) -> Keyword.get(meta, :line, 0)
      _ -> 0
    end
  end
end
