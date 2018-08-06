# Actr

Macros for more concise GenServers

## Why?

Sometimes I just want to write one definition and see all
my GenServer functionality in a single 24-line page.
Sometimes I just want to see my public API signature and my
private API signature side by side. Sometimes I'm just lazy.

## Usage

```elixir
defmodule Test do
  use Actr

  require Logger

  defcast update(new_value)
      when is_binary(new_value),
  fn
    ({_, new_value}, state) ->
      {:noreply, %{state|value: new_value}}
  end

  defcall get(:status), fn
    (_, _from, state) ->
      {:reply, {:ok, state.value}, state}
  end

  # No macro `definfo`, because what would be the point?
  #
  def handle_info({:snap, from}, state) do
    _ = send from, "Snap!"

    {:noreply, state}
  end

  deflink start_link, fn _args ->
    {:ok, %{value: "stuff"}}
  end
end

```

## Installation

```elixir
def deps do
  [ { :actr_ex,
      git: "https://gitlab.com/jonnystorm/actr-elixir.git"
    },
  ]
end
```

