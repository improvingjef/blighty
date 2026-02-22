defmodule Blight.Operators.Literal do
  @moduledoc """
  Mutates literal values:
  - `true` <-> `false`
  - integers: `n` -> `n + 1` and `n` -> `0`
  - strings: `"foo"` -> `""`
  - atoms (non-special): `:foo` -> `:blight_mutant`
  """

  @behaviour Blight.Operator

  @impl true
  def name, do: "Literal"

  @impl true
  def mutate(ast, file) do
    {_ast, mutants} =
      Macro.prewalk(ast, [], fn
        # Boolean literals
        {bool, meta, context} = node, acc
        when is_atom(bool) and bool in [true, false] and is_atom(context) ->
          line = Keyword.get(meta, :line, 0)
          replacement = !bool

          mutant = %Blight.Mutant{
            file: file,
            line: line,
            original: "#{bool}",
            mutated: "#{replacement}",
            operator: name(),
            description: "replaced #{bool} with #{replacement}",
            status: :pending
          }

          {node, [mutant | acc]}

        # Integer literals in AST (they appear as raw integers)
        node, acc when is_integer(node) and node != 0 ->
          mutants = [
            %Blight.Mutant{
              file: file,
              line: 0,
              original: "#{node}",
              mutated: "#{node + 1}",
              operator: name(),
              description: "replaced #{node} with #{node + 1}",
              status: :pending
            },
            %Blight.Mutant{
              file: file,
              line: 0,
              original: "#{node}",
              mutated: "0",
              operator: name(),
              description: "replaced #{node} with 0",
              status: :pending
            }
          ]

          {node, mutants ++ acc}

        node, acc when is_integer(node) and node == 0 ->
          mutant = %Blight.Mutant{
            file: file,
            line: 0,
            original: "0",
            mutated: "1",
            operator: name(),
            description: "replaced 0 with 1",
            status: :pending
          }

          {node, [mutant | acc]}

        # String literals
        node, acc when is_binary(node) and node != "" ->
          mutant = %Blight.Mutant{
            file: file,
            line: 0,
            original: inspect(node),
            mutated: ~s(""),
            operator: name(),
            description: "replaced string with empty string",
            status: :pending
          }

          {node, [mutant | acc]}

        node, acc ->
          {node, acc}
      end)

    Enum.reverse(mutants)
  end
end
