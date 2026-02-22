defmodule Blight.SourceMutator do
  @moduledoc """
  Applies mutations to source code using line-based text replacement.

  Since Elixir AST round-tripping (`Code.string_to_quoted` -> `Macro.to_string`)
  does not preserve exact formatting, we use line-based replacement instead:
  read the source file, replace the content at the target line, and write back.
  """

  @doc """
  Applies a mutant's change to the given source string, returning the mutated source.

  Replaces the first occurrence of `mutant.original` on `mutant.line` with
  `mutant.mutated`. If the original text is not found on the exact line,
  falls back to scanning nearby lines.
  """
  @spec apply_mutant(String.t(), Blight.Mutant.t()) :: {:ok, String.t()} | {:error, String.t()}
  def apply_mutant(source, %Blight.Mutant{} = mutant) do
    lines = String.split(source, "\n")
    line_idx = mutant.line - 1

    cond do
      line_idx >= 0 and line_idx < length(lines) ->
        line_content = Enum.at(lines, line_idx)

        if String.contains?(line_content, mutant.original) do
          new_line = String.replace(line_content, mutant.original, mutant.mutated, global: false)
          new_lines = List.replace_at(lines, line_idx, new_line)
          {:ok, Enum.join(new_lines, "\n")}
        else
          # Try nearby lines (AST line numbers can be slightly off)
          case find_nearby_line(lines, line_idx, mutant.original, 3) do
            {:ok, actual_idx} ->
              line_content = Enum.at(lines, actual_idx)

              new_line =
                String.replace(line_content, mutant.original, mutant.mutated, global: false)

              new_lines = List.replace_at(lines, actual_idx, new_line)
              {:ok, Enum.join(new_lines, "\n")}

            :error ->
              {:error, "Could not find '#{mutant.original}' near line #{mutant.line} in source"}
          end
        end

      true ->
        {:error, "Line #{mutant.line} out of range (source has #{length(lines)} lines)"}
    end
  end

  @doc """
  Applies a mutant to a file on disk, returning the original content for restoration.
  """
  @spec apply_to_file(Blight.Mutant.t()) :: {:ok, String.t()} | {:error, String.t()}
  def apply_to_file(%Blight.Mutant{file: file} = mutant) do
    case File.read(file) do
      {:ok, original_content} ->
        case apply_mutant(original_content, mutant) do
          {:ok, mutated_content} ->
            File.write!(file, mutated_content)
            {:ok, original_content}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, "Failed to read #{file}: #{inspect(reason)}"}
    end
  end

  @doc """
  Restores a file to its original content.
  """
  @spec restore_file(String.t(), String.t()) :: :ok
  def restore_file(file, original_content) do
    File.write!(file, original_content)
    :ok
  end

  defp find_nearby_line(lines, center_idx, target, radius) do
    range_start = max(0, center_idx - radius)
    range_end = min(length(lines) - 1, center_idx + radius)

    result =
      range_start..range_end
      |> Enum.find(fn idx ->
        idx != center_idx and String.contains?(Enum.at(lines, idx), target)
      end)

    case result do
      nil -> :error
      idx -> {:ok, idx}
    end
  end
end
