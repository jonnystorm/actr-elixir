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

  # Define public API
  defcast update(new_value)
      when is_binary(new_value),
  fn
    # Define private API
    ({:update, new_value}, state) ->
      {:noreply, %{state|value: new_value}}
  end

  # Define public API
  defcall get(:status), fn
    # Define private API
    (:status, _from, state) ->
      {:reply, {:ok, state.value}, state}
  end

  # No macro `definfo`, because what would be the point?
  #
  def handle_info({:snap, from}, state) do
    send from, "Snap!"

    {:noreply, state}
  end

  # Define public API; define private API
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

