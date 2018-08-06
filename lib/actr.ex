defmodule Actr do
  defmacro __using__(_opts) do
    quote do
      use GenServer
      import Actr
    end
  end

  defp explode_fun(fun) do
    { :fn, _, [
        {:->, _, [args, body]},
      ]
    } = fun

    {args, body}
  end

  defmacro deflink(sig, fun) do
    {[args], body} =
      explode_fun fun

    init =
      quote do
        @impl true
        def init(unquote(args)) do
          unquote(body)
        end
      end

    case sig do
      {name, _, [arg]} ->
        quote do
          unquote(init)

          def unquote(name)(unquote(arg)) do
            GenServer.start_link(__MODULE__, unquote(arg))
          end
        end

      name ->
        quote do
          unquote(init)

          def unquote(name) do
            GenServer.start_link(__MODULE__, [])
          end
        end
    end
  end

  defmacro defcall({:when, _, [sig, conds]}, fun) do
    {name, _, [term]} = sig
 
    {[msg, from, state], body} =
      explode_fun fun

    quote do
      @impl true
      def handle_call(
        unquote(msg),
        unquote(from),
        unquote(state)
      ) do
        unquote(body)
      end

      unquote(
        { :def, [], [
            { :when, [], [
                {name, [], [{:pid, [], nil}, term]},
                conds
              ]
            },
            [ { :do,
                { {:., [], [
                      {:__aliases__, [alias: false], [:GenServer]},
                      :call
                    ]
                  },
                  [],
                  [ {:pid, [], nil},
                    {:update, {:new_value, [], nil}},
                  ]
                }
              }
            ],
          ]
        }
      )
    end
  end

  defmacro defcall(sig, fun) do
    {name, _, args} = sig

    {[msg, from, state], body} =
      explode_fun fun

    case args do
      [] ->
        quote do
          @impl true
          def handle_call(
            unquote(msg),
            unquote(from),
            unquote(state)
          ) do
            unquote(body)
          end

          def unquote(name)(pid) do
            GenServer.call(pid, unquote(name))
          end
        end

      [term] ->
        quote do
          @impl true
          def handle_call(
            unquote(msg),
            unquote(from),
            unquote(state)
          ) do
            unquote(body)
          end

          def unquote(name)(pid, unquote(term)) do
            GenServer.call pid,
              {unquote(name), unquote(term)}
          end
        end
    end
  end

  defmacro defcast({:when, _, [sig, conds]}, fun) do
    {name, _, [term]} = sig

    {[msg, state], body} =
      explode_fun fun

    quote do
      @impl true
      def handle_cast(
        unquote(msg),
        unquote(state)
      ) do
        unquote(body)
      end

      unquote(
        { :def, [], [
            { :when, [], [
                {name, [], [{:pid, [], nil}, term]},
                conds
              ]
            },
            [ { :do,
                { {:., [], [
                      {:__aliases__, [alias: false], [:GenServer]},
                      :cast
                    ]
                  },
                  [],
                  [ {:pid, [], nil},
                    {:update, {:new_value, [], nil}},
                  ]
                }
              }
            ],
          ]
        }
      )
    end
  end

  defmacro defcast(sig, fun) do
    {name, _, args} = sig

    {[msg, state], body} =
      explode_fun fun

    case args do
      [] ->
        quote do
          @impl true
          def handle_cast(
            unquote(msg),
            unquote(state)
          ) do
            unquote(body)
          end

          def unquote(name)(pid) do
            GenServer.cast(pid, unquote(name))
          end
        end

      [term] ->
        quote do
          @impl true
          def handle_cast(
            unquote(msg),
            unquote(state)
          ) do
            unquote(body)
          end

          def unquote(name)(pid, unquote(term)) do
            GenServer.cast pid,
              {unquote(name), unquote(term)}
          end
        end
    end
  end
end

