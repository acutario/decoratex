defmodule TestModel do
  @moduledoc false

  use TestSchema

  decorations do
    decorate_field :module_name, :string, &TestModel.module_name/1
    decorate_field :module_length, :integer, &TestModel.module_length/1
    decorate_field :module_contains, :boolean, &TestModel.module_contains?/2, ""

    decorate_field :module_replace, :boolean, &TestModel.module_replace/2,
      pattern: "Test",
      replacement: ""
  end

  schema "test_models" do
    add_decorations()
  end

  def module_name(element) do
    element.__struct__
    |> to_string
  end

  def module_length(element) do
    element
    |> module_name()
    |> String.length()
  end

  def module_contains?(element, text) do
    element
    |> module_name()
    |> String.contains?(text)
  end

  def module_replace(element, options) do
    element
    |> module_name()
    |> String.replace(
      Keyword.get(options, :pattern),
      Keyword.get(options, :replacement),
      Keyword.get(options, :options, [])
    )
  end
end
