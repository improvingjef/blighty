# blighty

**Mutation testing for Elixir.**

*That which doesn't kill you makes you stronger.*

Blighty introduces small faults (mutants) into your Elixir source code, then runs your test suite against each mutant. If your tests catch the change, the mutant is **killed**. If the tests still pass, the mutant **survived** — exposing a gap in your test coverage.

Sibling project to [blight](https://github.com/improvingjef/blight) (Dart/Flutter).

## Installation

Add `blighty` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:blighty, "~> 0.1.0", only: :test, runtime: false}
  ]
end
```

## Usage

```bash
mix blight
```

### Options

```
--include     Glob patterns for source files to mutate (default: "lib/**/*.ex")
--exclude     Glob patterns to exclude
--operators   Comma-separated list of operators to apply
--parallel    Number of parallel workers (default: number of schedulers)
```

### Example Output

```
$ mix blight

  Blighty - Mutation Testing
  That which doesn't kill you makes you stronger.

  Mutating lib/my_app/calculator.ex ...

  [KILLED]    lib/my_app/calculator.ex:12  Arithmetic: replaced + with -
  [KILLED]    lib/my_app/calculator.ex:12  Arithmetic: replaced + with *
  [SURVIVED]  lib/my_app/calculator.ex:18  Relational: replaced > with >=
  [KILLED]    lib/my_app/calculator.ex:24  Logical: replaced && with ||
  [KILLED]    lib/my_app/calculator.ex:30  PipeRemoval: removed pipe step
  [TIMEOUT]   lib/my_app/calculator.ex:35  Conditional: negated if condition

  ──────────────────────────────────────────────────
  Results: 6 mutants, 4 killed, 1 survived, 1 timeout
  Mutation score: 83.3%
  ──────────────────────────────────────────────────

  Surviving mutants:

    lib/my_app/calculator.ex:18
    Relational: replaced > with >=
    Consider adding a boundary test case.
```

## Mutation Operators

| Operator           | Description                                      |
|--------------------|--------------------------------------------------|
| Arithmetic         | `+` <-> `-`, `*` <-> `/`                         |
| Relational         | `>` <-> `>=`, `<` <-> `<=`, `==` <-> `!=`, `===` <-> `!==` |
| Logical            | `and` <-> `or`, `&&` <-> `\|\|`                    |
| PipeRemoval        | Removes steps from pipe chains                   |
| PatternMatch       | Simplifies pattern matches, removes guards       |
| Literal            | `true` <-> `false`, `n` -> `0`, strings -> `""` |
| StatementDeletion  | Removes expressions from function bodies         |
| Conditional        | Negates conditions in `if`/`unless`/`cond`       |

## Configuration

Configure via the `:blighty` key in `mix.exs`:

```elixir
def project do
  [
    # ... other config
    blighty: [
      include: ["lib/**/*.ex"],
      exclude: ["lib/my_app_web/**/*.ex"],
      operators: [:arithmetic, :relational, :logical],
      test_command: "mix test",
      timeout_multiplier: 3.0,
      parallelism: 4
    ]
  ]
end
```

Or create a `.blighty.exs` file in the project root:

```elixir
%{
  include: ["lib/**/*.ex"],
  exclude: ["lib/my_app_web/**/*.ex"],
  operators: [:arithmetic, :relational, :logical],
  test_command: "mix test",
  timeout_multiplier: 3.0,
  parallelism: 4
}
```

## How It Works

1. **Parse** — Blighty reads your source files and parses them into Elixir AST using `Code.string_to_quoted/2`.
2. **Mutate** — Each mutation operator walks the AST with `Macro.prewalk/2` to find mutation opportunities.
3. **Test** — For each mutant, Blighty writes the modified source, runs your test suite, and records the result.
4. **Report** — Results are displayed with ANSI colors showing killed, survived, and timed-out mutants.

## License

MIT
