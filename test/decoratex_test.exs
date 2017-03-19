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

  test "not decorate a field", %{test_model: test_model} do
    decorated_model = test_model
    |> TestModel.decorate(except: :module_name)
    assert decorated_model.module_name == nil
    assert decorated_model.module_length == TestModel.module_length(test_model)
  end

  test "not decorate a list of fields", %{test_model: test_model} do
    decorated_model = test_model
    |> TestModel.decorate(except: [:module_name, :module_length])
    assert decorated_model.module_name == nil
    assert decorated_model.module_length == nil
  end

  test "decorate a field with options", %{test_model: test_model} do
    text = "Test"
    decorated_model = test_model
    |> TestModel.decorate(module_contains: text)
    assert decorated_model.module_contains == TestModel.module_contains?(test_model, text)
  end

  test "decorate a field with keyword options", %{test_model: test_model} do
    pattern = "Test"
    replacement = "Spec"
    decorated_model = test_model
    |> TestModel.decorate(module_replace: [pattern: pattern, replacement: replacement])
    assert decorated_model.module_replace == TestModel.module_replace(test_model, [pattern: pattern, replacement: replacement])
  end

  test "decorate multiple fields with options", %{test_model: test_model} do
    text = "Test"
    pattern = "Test"
    replacement = "Spec"
    decorated_model = test_model
    |> TestModel.decorate(module_contains: text, module_replace: [pattern: pattern, replacement: replacement])
    assert decorated_model.module_replace == TestModel.module_replace(test_model, [pattern: pattern, replacement: replacement])
    assert decorated_model.module_contains == TestModel.module_contains?(test_model, text)
    assert decorated_model.module_name == nil
    assert decorated_model.module_length == nil
  end

  test "decorate multiple fields with and without options", %{test_model: test_model} do
    text = "Test"
    decorated_model = test_model
    |> TestModel.decorate([:module_name, module_contains: text])
    assert decorated_model.module_replace == nil
    assert decorated_model.module_contains == TestModel.module_contains?(test_model, text)
    assert decorated_model.module_name == TestModel.module_name(test_model)
    assert decorated_model.module_length == nil
  end
end