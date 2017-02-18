defmodule TestModel do
  use Ecto.Schema
  use Decoratex
  import Ecto.Changeset

  decorations do
    decorate_field :module_name, :string, &TestModel.module_name/1
    decorate_field :module_length, :integer, &TestModel.module_length/1
  end

  schema "test_models" do
    add_decorations
  end

  def module_name(element) do
    to_string(element.__struct__)
  end

  def module_length(element) do
    String.length(module_name(element))
  end
end
