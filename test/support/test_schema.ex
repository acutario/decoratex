defmodule TestSchema do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      use Decoratex.Schema
    end
  end
end
