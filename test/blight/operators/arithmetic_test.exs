defmodule Blight.Operators.ArithmeticTest do
  use ExUnit.Case, async: true

  alias Blight.Operators.Arithmetic

  @sample_source """
  defmodule Calculator do
    def add(a, b), do: a + b
    def subtract(a, b), do: a - b
    def multiply(a, b), do: a * b
    def divide(a, b), do: a / b
  end
  """

  describe "name/0" do
    test "returns the operator name" do
      assert Arithmetic.name() == "Arithmetic"
    end
  end

  describe "mutate/2" do
    test "generates mutants for + operator" do
      ast = Code.string_to_quoted!(@sample_source)
      mutants = Arithmetic.mutate(ast, "test.ex")

      plus_mutants = Enum.filter(mutants, &String.contains?(&1.description, "replaced +"))
      assert length(plus_mutants) == 2

      descriptions = Enum.map(plus_mutants, & &1.description)
      assert "replaced + with -" in descriptions
      assert "replaced + with *" in descriptions
    end

    test "generates mutants for - operator" do
      ast = Code.string_to_quoted!(@sample_source)
      mutants = Arithmetic.mutate(ast, "test.ex")

      minus_mutants = Enum.filter(mutants, &String.contains?(&1.description, "replaced -"))
      assert length(minus_mutants) == 2

      descriptions = Enum.map(minus_mutants, & &1.description)
      assert "replaced - with +" in descriptions
      assert "replaced - with *" in descriptions
    end

    test "generates mutants for * operator" do
      ast = Code.string_to_quoted!(@sample_source)
      mutants = Arithmetic.mutate(ast, "test.ex")

      mult_mutants = Enum.filter(mutants, &String.contains?(&1.description, "replaced *"))
      assert length(mult_mutants) == 2

      descriptions = Enum.map(mult_mutants, & &1.description)
      assert "replaced * with /" in descriptions
      assert "replaced * with +" in descriptions
    end

    test "generates mutants for / operator" do
      ast = Code.string_to_quoted!(@sample_source)
      mutants = Arithmetic.mutate(ast, "test.ex")

      div_mutants = Enum.filter(mutants, &String.contains?(&1.description, "replaced /"))
      assert length(div_mutants) == 2

      descriptions = Enum.map(div_mutants, & &1.description)
      assert "replaced / with *" in descriptions
      assert "replaced / with -" in descriptions
    end

    test "sets file and line on mutants" do
      ast = Code.string_to_quoted!(@sample_source)
      mutants = Arithmetic.mutate(ast, "calculator.ex")

      Enum.each(mutants, fn mutant ->
        assert mutant.file == "calculator.ex"
        assert mutant.line > 0
        assert mutant.status == :pending
        assert mutant.operator == "Arithmetic"
      end)
    end

    test "returns empty list for source with no arithmetic operators" do
      source = """
      defmodule NoMath do
        def greet(name), do: "Hello, " <> name
      end
      """

      ast = Code.string_to_quoted!(source)
      assert Arithmetic.mutate(ast, "test.ex") == []
    end
  end
end
