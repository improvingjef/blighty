defmodule Blight.SourceMutatorTest do
  use ExUnit.Case, async: true

  alias Blight.SourceMutator
  alias Blight.Mutant

  @sample_source """
  defmodule Calculator do
    def add(a, b) do
      a + b
    end

    def compare(a, b) do
      a > b
    end
  end
  """

  describe "apply_mutant/2" do
    test "replaces operator on the correct line" do
      mutant = %Mutant{
        file: "test.ex",
        line: 3,
        original: "a + b",
        mutated: "a - b",
        operator: "Arithmetic",
        description: "replaced + with -",
        status: :pending
      }

      assert {:ok, result} = SourceMutator.apply_mutant(@sample_source, mutant)
      lines = String.split(result, "\n")
      assert Enum.at(lines, 2) =~ "a - b"
    end

    test "preserves other lines" do
      mutant = %Mutant{
        file: "test.ex",
        line: 3,
        original: "a + b",
        mutated: "a - b",
        operator: "Arithmetic",
        description: "replaced + with -",
        status: :pending
      }

      {:ok, result} = SourceMutator.apply_mutant(@sample_source, mutant)
      lines = String.split(result, "\n")

      # Line 1 should be unchanged
      assert Enum.at(lines, 0) =~ "defmodule Calculator do"
      # Line 7 should be unchanged
      assert Enum.at(lines, 6) =~ "a > b"
    end

    test "returns error when original text not found" do
      mutant = %Mutant{
        file: "test.ex",
        line: 3,
        original: "nonexistent code",
        mutated: "replacement",
        operator: "Test",
        description: "test",
        status: :pending
      }

      assert {:error, msg} = SourceMutator.apply_mutant(@sample_source, mutant)
      assert msg =~ "Could not find"
    end

    test "returns error for out-of-range line" do
      mutant = %Mutant{
        file: "test.ex",
        line: 999,
        original: "a + b",
        mutated: "a - b",
        operator: "Arithmetic",
        description: "test",
        status: :pending
      }

      assert {:error, msg} = SourceMutator.apply_mutant(@sample_source, mutant)
      assert msg =~ "out of range"
    end

    test "finds text on nearby lines when exact line is off" do
      mutant = %Mutant{
        file: "test.ex",
        line: 4,
        original: "a + b",
        mutated: "a - b",
        operator: "Arithmetic",
        description: "replaced + with -",
        status: :pending
      }

      # Line 4 doesn't have "a + b" but line 3 does, within radius
      assert {:ok, result} = SourceMutator.apply_mutant(@sample_source, mutant)
      assert result =~ "a - b"
    end

    test "handles single-line source" do
      source = "x + y"

      mutant = %Mutant{
        file: "test.ex",
        line: 1,
        original: "x + y",
        mutated: "x - y",
        operator: "Arithmetic",
        description: "test",
        status: :pending
      }

      assert {:ok, "x - y"} = SourceMutator.apply_mutant(source, mutant)
    end
  end
end
