# Copyright © 2018 Jonathan Storm <jds@idio.link> This work
# is free. You can redistribute it and/or modify it under
# the terms of the Do What The Fuck You Want To Public
# License, Version 2, as published by Sam Hocevar. See the
# COPYING.WTFPL file for more details.

defmodule Actr do
  defmacro __using__(_opts) do
    quote do
      use GenServer
      import Actr
    end
  end

  defp explode_fun(fun) do
    {:fn, _, clauses} = fun

    Enum.map clauses, fn clause ->
      {:->, _, [args, body]} = clause

      {args, body}
    end
  end

  defp inject_name_into_fun_sig(name, sig) do
    case sig do
      [{:when, meta, args_conds}] ->
        condition = List.last args_conds
        args = List.delete_at(args_conds, -1)

        wrapped = {name, [], args}

        {:when, meta, [wrapped, condition]}

      args ->
        {name, [], args}
    end
  end

  defp strip_block({:__block__, _, block}),
    do: block

  defmacro deflink(sig, fun) do
    inits =
      Enum.flat_map explode_fun(fun), fn {args, body} ->
        named =
          inject_name_into_fun_sig(:init, args)

        quote do
          @impl true
          def unquote(named) do
            unquote(body)
          end
        end |> strip_block
      end

    case sig do
      {name, _, [arg]} ->
        arg_name =
          with {:\\, _, [arg_name, _]} <- arg,
            do: arg_name

        quote do
          unquote({:__block__, [], inits})

          def unquote(name)(unquote(arg)) do
            GenServer.start_link(
              __MODULE__,
              [unquote(arg_name)]
            )
          end
        end

      name ->
        quote do
          unquote({:__block__, [], inits})

          def unquote(name) do
            GenServer.start_link(__MODULE__, [])
          end
        end
    end
  end

  defp inject_argument(arg, head) do
    unhd =
      fn
        (h, t) when is_list(t) ->
          [h|t]

        (h, nil) ->
          [h]
      end

    case head do
      {:when, meta1, [sig, conds]} ->
        {name, meta2, term} = sig

        new_sig = {name, meta2, unhd.(arg, term)}

        {:when, meta1, [new_sig, conds]}

      {name, meta, term} ->
        {name, meta, unhd.(arg, term)}
    end
  end

  defp make_private_def(type, args, body) do
    name =
      case type do
        :call -> :handle_call
        :cast -> :handle_cast
      end

    named =
      inject_name_into_fun_sig(name, args)

    quote do
      @impl true
      def unquote(named) do
        unquote(body)
      end
    end |> strip_block
  end

  defp make_public_def(type, head) do
    pid = {:pid, [], nil}
    sig =
      with {:when, _, [sig, _]} <- head,
        do: sig

    new_head = inject_argument(pid, head)
    new_arg  =
      case sig do
        {name, _,   nil} -> name
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
    privates =
      Enum.flat_map explode_fun(fun), fn {args, body} ->
        make_private_def(type, args, body)
      end

    quote do
      unquote({:__block__, [], privates})

      unquote(make_public_def(type, head))
    end |> strip_block
  end

  defmacro defcall(head, fun),
    do: make_defs(:call, head, fun)

  defmacro defcast(head, fun),
    do: make_defs(:cast, head, fun)
end

