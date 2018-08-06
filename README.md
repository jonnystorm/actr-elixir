# Actr

[![pipeline status](https://gitlab.com/jonnystorm/actr-elixir/badges/master/pipeline.svg)](https://gitlab.com/jonnystorm/actr-elixir/commits/master)

Macros for more concise GenServers

## Why?

Sometimes I just want to write one definition and see all
my GenServer functionality in a single 24-line page.
Sometimes I just want to see my public API signature and my
private API signature side by side. Sometimes I'm just lazy.

## Usage

Mind you, even the trival example below outputs warnings
about function clauses not being grouped properly. I plan to
later collect all the clauses into different module
attributes, then output the contents of each group.

Alternatively, I could just apply the given functions inside
a single `handle_call` or `handle_cast`, but then the
default GenServer implementations will never be called.

```elixir
defmodule TestServer do
  use Actr

  require Logger

  # Define public API
  defcast update(new_value)
      when is_binary(new_value),
  fn
    # Define private API
    ({:update, "magic"}, state) ->
      {:noreply, %{state|value: "Huzzah!"}}

    # Define private API
    ({:update, new_value}, state)
        when is_binary(new_value)
    ->
      Logger.info "You didn't say the magic word"

      {:noreply, %{state|value: new_value}}
  end

  # Define public API
  defcast notify, fn
    # Define private API
    (:notify, state) ->
      Logger.info "Got notification"

      {:noreply, state}
  end

  # Define public API
  defcall get(:status), fn
    # Define private API
    ({:get, :status}, _from, state) ->
      {:reply, {:ok, state.value}, state}
  end

  # Define public API
  defcall status, fn
    # Define private API
    (:status, _from, state) ->
      {:reply, {:ok, state.value}, state}
  end

  # No `definfo` macro, because what would be the point?
  #
  @impl true
  def handle_info({:snap, from}, state) do
    send(from, "Snap!")

    {:noreply, state}
  end

  # Define public API
  deflink start_link(initial \\ "stuff"), fn
    # Define private API
    [arg] ->
        {:ok, %{value: arg}}
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

