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

  defp inject_argument(arg, head) do
    case head do
      {:when, meta1, [sig, conds]} ->
        {name, meta2, terms} = sig

        new_sig = {name, meta2, [arg|terms]}

        {:when, meta1, [new_sig, conds]}

      {name, meta, terms} ->
        {name, meta, [arg|terms]}
    end
  end

  defp make_private_def(type, fun) do
    exploded = explode_fun fun

    case type do
      :call ->
        {[msg, from, state], body} = exploded

        quote do
          @impl true
          def handle_call(
            unquote(msg),
            unquote(from),
            unquote(state)
          ) do
            unquote(body)
          end
        end

      :cast ->
        {[msg, state], body} = exploded

        quote do
          @impl true
          def handle_cast(
            unquote(msg),
            unquote(state)
          ) do
            unquote(body)
          end
        end
    end
  end

  defp make_public_def(type, head) do
    pid = {:pid, [], nil}
    sig =
      with {:when, _, [sig, _]} <- head,
        do: sig

    new_head = inject_argument(pid, head)
    new_arg  =
      case sig do
        {name, _,    []} -> name
        {name, _, [arg]} -> {name, arg}
      end

    quote do
      def unquote(new_head) do
        apply(
          GenServer,
          unquote(type),
          [ unquote(pid),
            unquote(new_arg),
          ]
        )
      end
    end
  end

  defp make_defs(type, head, fun)
      when type in [:call, :cast]
  do
    quote do
      unquote(make_private_def(type, fun))

      unquote(make_public_def(type, head))
    end
  end

  defmacro defcall(head, fun),
    do: make_defs(:call, head, fun)

  defmacro defcast(head, fun),
    do: make_defs(:cast, head, fun)
end

