defmodule DecoratexTest do
  use ExUnit.Case
  doctest Decoratex

  setup do
    test_model = %TestModel{}
    {:ok, test_model: test_model}
  end

  test "decorate all fields", %{test_model: test_model} do
    decorated_model = test_model
    |> TestModel.decorate
    assert decorated_model.module_name == TestModel.module_name(test_model)
    assert decorated_model.module_length == TestModel.module_length(test_model)
  end

  test "decorate one field", %{test_model: test_model} do
    decorated_model = test_model
    |> TestModel.decorate(:module_name)
    assert decorated_model.module_name == TestModel.module_name(test_model)
    assert decorated_model.module_length == nil
  end

  test "decorate other field", %{test_model: test_model} do
    decorated_model = test_model
    |> TestModel.decorate(:module_length)
    assert decorated_model.module_name == nil
    assert decorated_model.module_length == TestModel.module_length(test_model)
  end

  test "decorate a list of fields", %{test_model: test_model} do
    decorated_model = test_model
    |> TestModel.decorate([:module_name, :module_length])
    assert decorated_model.module_name == TestModel.module_name(test_model)
    assert decorated_model.module_length == TestModel.module_length(test_model)
  end
end