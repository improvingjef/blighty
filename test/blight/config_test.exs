defmodule Blight.ConfigTest do
  use ExUnit.Case, async: true

  alias Blight.Config

  describe "load/1" do
    test "returns default config with no overrides" do
      config = Config.load()

      assert config.include == ["lib/**/*.ex"]
      assert config.exclude == []
      assert config.test_command == "mix test"
      assert config.timeout_multiplier == 3.0
      assert config.parallelism > 0
      assert is_list(config.operators)
      assert length(config.operators) > 0
    end

    test "applies overrides" do
      config = Config.load(include: ["src/**/*.ex"], timeout_multiplier: 5.0)

      assert config.include == ["src/**/*.ex"]
      assert config.timeout_multiplier == 5.0
    end

    test "resolves operator atoms to modules" do
      config = Config.load(operators: [:arithmetic, :relational])

      assert config.operators == [
               Blight.Operators.Arithmetic,
               Blight.Operators.Relational
             ]
    end

    test "keeps module operators as-is" do
      config = Config.load(operators: [Blight.Operators.Arithmetic])

      assert config.operators == [Blight.Operators.Arithmetic]
    end

    test "all default operators are valid modules" do
      config = Config.load()

      Enum.each(config.operators, fn op ->
        Code.ensure_loaded!(op)

        assert function_exported?(op, :name, 0),
               "#{inspect(op)} does not implement name/0"

        assert function_exported?(op, :mutate, 2),
               "#{inspect(op)} does not implement mutate/2"
      end)
    end
  end

  describe "source_files/1" do
    test "returns empty list when no files match" do
      config = %Config{include: ["nonexistent_dir/**/*.ex"], exclude: []}
      assert Config.source_files(config) == []
    end

    test "respects exclude patterns" do
      config = %Config{
        include: ["lib/**/*.ex"],
        exclude: ["lib/**/*.ex"]
      }

      assert Config.source_files(config) == []
    end
  end
end
