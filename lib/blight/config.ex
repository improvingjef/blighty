defmodule Blight.Config do
  @moduledoc """
  Configuration for Blight mutation testing.

  Configuration is loaded from (in order of precedence):
  1. Explicit options passed to `load/1`
  2. `.blighty.exs` file in the project root
  3. The `:blighty` key in `mix.exs` project config
  4. Defaults
  """

  @type t :: %__MODULE__{
          include: [String.t()],
          exclude: [String.t()],
          operators: [module()],
          test_command: String.t(),
          timeout_multiplier: float(),
          parallelism: pos_integer()
        }

  @default_include ["lib/**/*.ex"]
  @default_exclude []
  @default_test_command "mix test"
  @default_timeout_multiplier 3.0

  defstruct include: @default_include,
            exclude: @default_exclude,
            operators: [],
            test_command: @default_test_command,
            timeout_multiplier: @default_timeout_multiplier,
            parallelism: 1

  @doc """
  Loads configuration by merging defaults, mix.exs :blighty key,
  .blighty.exs file, and any explicit overrides.
  """
  @spec load(keyword()) :: t()
  def load(overrides \\ []) do
    defaults = %{
      include: @default_include,
      exclude: @default_exclude,
      operators: resolve_operators(nil),
      test_command: @default_test_command,
      timeout_multiplier: @default_timeout_multiplier,
      parallelism: System.schedulers_online()
    }

    mix_config = load_from_mix()
    file_config = load_from_file()
    override_map = Map.new(overrides)

    merged =
      defaults
      |> Map.merge(mix_config)
      |> Map.merge(file_config)
      |> Map.merge(override_map)

    # Resolve operator atoms to modules if needed
    merged = Map.update!(merged, :operators, &resolve_operators/1)

    struct!(__MODULE__, merged)
  end

  defp load_from_mix do
    if function_exported?(Mix.Project, :config, 0) do
      Mix.Project.config()
      |> Keyword.get(:blighty, [])
      |> Map.new()
    else
      %{}
    end
  rescue
    _ -> %{}
  end

  defp load_from_file do
    path = Path.join(File.cwd!(), ".blighty.exs")

    if File.exists?(path) do
      {config, _bindings} = Code.eval_file(path)

      case config do
        %{} = map -> map
        list when is_list(list) -> Map.new(list)
        _ -> %{}
      end
    else
      %{}
    end
  rescue
    _ -> %{}
  end

  @operator_mapping %{
    arithmetic: Blight.Operators.Arithmetic,
    relational: Blight.Operators.Relational,
    logical: Blight.Operators.Logical,
    pipe_removal: Blight.Operators.PipeRemoval,
    pattern_match: Blight.Operators.PatternMatch,
    literal: Blight.Operators.Literal,
    statement_deletion: Blight.Operators.StatementDeletion,
    conditional: Blight.Operators.Conditional
  }

  defp resolve_operators(nil), do: Blight.operators()
  defp resolve_operators([]), do: Blight.operators()

  defp resolve_operators(operators) when is_list(operators) do
    Enum.map(operators, fn
      atom when is_atom(atom) and not is_nil(atom) ->
        Map.get(@operator_mapping, atom, atom)

      other ->
        other
    end)
  end

  @doc """
  Returns the list of source files matching the include/exclude globs.
  """
  @spec source_files(t()) :: [String.t()]
  def source_files(%__MODULE__{include: include, exclude: exclude}) do
    included =
      include
      |> Enum.flat_map(&Path.wildcard/1)
      |> Enum.uniq()

    excluded =
      exclude
      |> Enum.flat_map(&Path.wildcard/1)
      |> MapSet.new()

    included
    |> Enum.reject(&MapSet.member?(excluded, &1))
    |> Enum.sort()
  end
end
