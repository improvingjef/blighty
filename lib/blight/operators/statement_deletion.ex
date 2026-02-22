defmodule Blight.Operators.StatementDeletion do
  @moduledoc """
  Removes expressions from function body blocks.

  For a block with multiple statements, each statement (except the last)
  is removed one at a time to produce mutants.
  """

  @behaviour Blight.Operator

  @impl true
  def name, do: "StatementDeletion"

  @impl true
  def mutate(ast, file) do
    {_ast, mutants} =
      Macro.prewalk(ast, [], fn
        {:__block__, meta, statements} = node, acc when is_list(statements) ->
          line = Keyword.get(meta, :line, 0)

          new_mutants =
            if length(statements) > 1 do
              # Remove each statement except the last (last is the return value)
              statements
              |> Enum.with_index()
              |> Enum.filter(fn {_stmt, i} -> i < length(statements) - 1 end)
              |> Enum.map(fn {stmt, i} ->
                _remaining = List.delete_at(statements, i)

                %Blight.Mutant{
                  file: file,
                  line: extract_line(stmt, line),
                  original: Macro.to_string(stmt),
                  mutated: "(statement removed)",
                  operator: name(),
                  description: "removed statement #{i + 1} from block",
                  status: :pending
                }
              end)
            else
              []
            end

          {node, acc ++ new_mutants}

        node, acc ->
          {node, acc}
      end)

    mutants
  end

  defp extract_line({_, meta, _}, default) when is_list(meta) do
    Keyword.get(meta, :line, default)
  end

  defp extract_line(_, default), do: default
end
