defmodule Blight.Mutant do
  @moduledoc """
  Represents a single mutation applied to source code.

  A mutant captures what was changed, where, and the result of running
  the test suite against it.
  """

  @type status :: :pending | :killed | :survived | :timeout | :error

  @type t :: %__MODULE__{
          file: String.t(),
          line: pos_integer(),
          original: String.t(),
          mutated: String.t(),
          operator: String.t(),
          description: String.t(),
          status: status()
        }

  defstruct [
    :file,
    :line,
    :original,
    :mutated,
    :operator,
    :description,
    status: :pending
  ]

  @doc """
  Returns true if the mutant was killed (test suite caught the mutation).
  """
  @spec killed?(t()) :: boolean()
  def killed?(%__MODULE__{status: :killed}), do: true
  def killed?(%__MODULE__{}), do: false

  @doc """
  Returns true if the mutant survived (test suite did NOT catch the mutation).
  """
  @spec survived?(t()) :: boolean()
  def survived?(%__MODULE__{status: :survived}), do: true
  def survived?(%__MODULE__{}), do: false
end
