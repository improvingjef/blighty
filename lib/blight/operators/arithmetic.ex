defmodule Blight.Operators.Arithmetic do
  @moduledoc """
  Mutates arithmetic operators: `+` <-> `-`, `*` <-> `/`.
  """

  @behaviour Blight.Operator

  @mutations %{
    :+ => [:-, :*],
    :- => [:+, :*],
    :* => [:/, :+],
    :/ => [:*, :-]
  }

  @impl true
  def name, do: "Arithmetic"

  @impl true
  def mutate(ast, file) do
    {_ast, mutants} =
      Macro.prewalk(ast, [], fn
        {op, meta, [left, right]} = node, acc when is_map_key(@mutations, op) ->
          line = Keyword.get(meta, :line, 0)

          new_mutants =
            @mutations[op]
            |> Enum.map(fn replacement ->
              %Blight.Mutant{
                file: file,
                line: line,
                original: Macro.to_string(node),
                mutated: Macro.to_string({replacement, meta, [left, right]}),
                operator: name(),
                description: "replaced #{op} with #{replacement}",
                status: :pending
              }
            end)

          {node, acc ++ new_mutants}

        node, acc ->
          {node, acc}
      end)

    mutants
  end
end
