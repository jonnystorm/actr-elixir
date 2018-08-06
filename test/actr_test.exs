defmodule ActrTest do
  use ExUnit.Case, async: false
  doctest Actr

  require Logger

  defmodule TestServer do
    use Actr

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

    def handle_info({:snap, from}, state) do
      _ = send(from, "Snap!")

      {:noreply, state}
    end

    deflink start_link, fn _args ->
      {:ok, %{value: "stuff"}}
    end
  end


  setup do
    {:ok, pid} = TestServer.start_link

    {:ok, pid: pid}
  end

  test "It calls! It casts!", %{pid: pid} do
    assert TestServer.get(pid, :status)
      == {:ok, "stuff"}

    :ok = TestServer.update(pid, "things")

    assert TestServer.get(pid, :status)
      == {:ok, "things"}
  end
end
