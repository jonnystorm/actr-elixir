defmodule ActrTest do
  use ExUnit.Case, async: false
  doctest Actr

  defmodule TestServer do
    use Actr

    require Logger

    defcast update(new_value)
        when is_binary(new_value),
    fn
      ({:update, "magic"}, state) ->
        {:noreply, %{state|value: "Huzzah!"}}

      ({:update, new_value}, state)
          when is_binary(new_value)
      ->
        Logger.info "You didn't say the magic word"

        {:noreply, %{state|value: new_value}}
    end

    defcast notify, fn
      (:notify, state) ->
        Logger.info "Got notification"

        {:noreply, state}
    end

    defcall get(:status), fn
      ({:get, :status}, _from, state) ->
        {:reply, {:ok, state.value}, state}
    end

    defcall status, fn
      (:status, _from, state) ->
        {:reply, {:ok, state.value}, state}
    end

    @impl true
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

    assert TestServer.status(pid)
      == {:ok, "stuff"}

    :ok = TestServer.update(pid, "things")

    assert TestServer.get(pid, :status)
      == {:ok, "things"}

    assert TestServer.status(pid)
      == {:ok, "things"}
  end

  test "It handles multiple function clauses!", %{pid: pid}
  do
    :ok = TestServer.update(pid, "magic")

    assert TestServer.status(pid)
      == {:ok, "Huzzah!"}
  end

  test "It passes optional args to init!" do
    initial_value = "test"

    {:ok, pid} =
      TestServer.start_link(initial_value)

    assert TestServer.get(pid, :status)
      == {:ok, initial_value}
  end

  test "It passes required args to init!" do
    defmodule Test do
      use Actr

      deflink start_link(required), fn
        [arg] ->
          {:ok, arg}
      end
    end

    assert {:ok, _pid} = Test.start_link("test")
  end

  test "An unmatched public API clause raises", %{pid: pid}
  do
    assert_raise FunctionClauseError, fn ->
      TestServer.get(pid, :blarg)
    end
  end

  test "An unmatched private API clause exits", %{pid: pid}
  do
    Process.flag(:trap_exit, true)

    send(pid, :blarg)

    assert_receive {:EXIT, ^pid, {:function_clause, _}}
  end
end
