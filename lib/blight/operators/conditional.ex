defmodule Blight.Operators.Conditional do
  @moduledoc """
  Negates conditions in `if`, `unless`, `cond`, and `case` expressions.

  - `if condition` -> `if !condition`
  - `unless condition` -> `unless !condition` (equivalent to `if condition`)
  """

  @behaviour Blight.Operator

  @impl true
  def name, do: "Conditional"

  @impl true
  def mutate(ast, file) do
    {_ast, mutants} =
      Macro.prewalk(ast, [], fn
        {:if, meta, [condition | rest]} = node, acc ->
          line = Keyword.get(meta, :line, 0)

          mutant = %Blight.Mutant{
            file: file,
            line: line,
            original: Macro.to_string(node),
            mutated: Macro.to_string({:if, meta, [negate(condition) | rest]}),
            operator: name(),
            description: "negated if condition",
            status: :pending
          }

          {node, [mutant | acc]}

        {:unless, meta, [condition | rest]} = node, acc ->
          line = Keyword.get(meta, :line, 0)

          mutant = %Blight.Mutant{
            file: file,
            line: line,
            original: Macro.to_string(node),
            mutated: Macro.to_string({:unless, meta, [negate(condition) | rest]}),
            operator: name(),
            description: "negated unless condition",
            status: :pending
          }

          {node, [mutant | acc]}

        node, acc ->
          {node, acc}
      end)

    Enum.reverse(mutants)
  end

  defp negate(condition) do
    {:!, [], [condition]}
  end
end
