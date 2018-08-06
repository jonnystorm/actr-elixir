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
      send(from, "Snap!")

      {:noreply, state}
    end

    deflink start_link(initial \\ "stuff"), fn
      [arg] ->
        {:ok, %{value: arg}}
    end
  end


  setup do
    {:ok, pid} = TestServer.start_link

    {:ok, pid: pid}
  end

  test "It calls! It casts!", %{pid: pid}
  do
    assert TestServer.get(pid, :status)
      == {:ok, "stuff"}

    :ok = TestServer.update(pid, "things")

    assert TestServer.get(pid, :status)
      == {:ok, "things"}
  end

  test "It passes args to init!" do
    initial_value = "test"

    {:ok, pid} =
      TestServer.start_link(initial_value)

    assert TestServer.get(pid, :status)
      == {:ok, initial_value}
  end

  test "An unmatched public API clause raises", %{pid: pid}
  do
    assert_raise FunctionClauseError, fn ->
      TestServer.get(pid, :blarg)
    end
  end

  test "An unmatched internal API clause exits", %{pid: pid}
  do
    Process.flag(:trap_exit, true)

    send(pid, :blarg)

    assert_receive {:EXIT, ^pid, {:function_clause, _}}
  end
end
