defmodule Decoratex.Schema do
  @moduledoc """
  This module add the macro functions for the module schemas to add the decorate
  fields definitions.

  The macro decorations/1 accepts a block with decorate_fields definitions,
  and decorations/0 add the virtual fields in the ecto schema to keep the values
  of decoration functions.

    decorations do
      decorate_field :field_name, :type, &decoration_method/1
      ...
    end

    schema "my_schemas" do
      ...
      decorations()
    end
  """

  alias Decoratex.Schema

  @doc false
  defmacro __using__(_) do
    quote do
      import Decoratex.Schema, only: [decorations: 0, decorations: 1]
    end
  end

  @doc false
  defmacro decorations(do: block) do
    quote do
      Module.register_attribute(__MODULE__, :decorations, accumulate: true)

      try do
        import Decoratex.Schema, only: [decorate_field: 3, decorate_field: 4]
        unquote(block)
      after
        :ok
      end

      decorations = Enum.reverse(@decorations)

      Module.eval_quoted(__ENV__, [
        Schema.__decorations__(decorations)
      ])
    end
  end

  @doc false
  defmacro decorations do
    quote do
      Enum.each(@decorations, fn {name, %{type: type}} ->
        field(name, type, virtual: true)
      end)
    end
  end

  @doc false
  defmacro decorate_field(name, type, function, options \\ nil) do
    quote do
      Schema.__decorate_field__(
        __MODULE__,
        unquote(name),
        unquote(type),
        unquote(function),
        unquote(options)
      )
    end
  end

  @doc false
  def __decorations__(decorations) do
    decorations_quoted =
      Enum.map(decorations, fn {name, decoration} ->
        quote do
          def __decoration__(unquote(name)), do: unquote(Macro.escape(decoration))
        end
      end)

    quote do
      unquote(decorations_quoted)
      def __decoration__(_), do: nil
      def __decorations__, do: unquote(Macro.escape(decorations))
    end
  end

  @doc false
  def __decorate_field__(module, name, type, function, options) do
    decoration =
      case :erlang.fun_info(function)[:arity] do
        1 -> %{type: type, function: function}
        2 -> %{type: type, function: function, options: options}
        _ -> raise "Fields can only be decorated with functions of arity 1 or 2"
      end

    Module.put_attribute(module, :decorations, {name, decoration})
  end
end
