defmodule Decoratex do
  @moduledoc """
  Decoratex provides an easy way to add calculated data to your Ecto model structs.

  You have to configure the name and type of these attributes and the function
  to calculate and load data when you need to decorate your model.

  The function for each field will receibe just the current model instance as param.

  ## What does this package do?

  Maybe you were in some situations where you need some related data of a model
  that is not straight stored with it's attributes and it requires complex logic
  to calculate their value, which can't be easly solved with a query. Maybe you
  will need this data in multiple points of the instace life cicle and you want
  the data available in a standard way instead of using an external module
  function each time you need it's value.

  In this cases, this is what decoratex can do for you:

  * Add virtual fields to the model schema to let you use your model like
  the same struct type with these new fields.

  * Provide a function to load data in all or some of these fields
  whenever you want.

  ## Usage

  1. Add `use Decoratex.Schema` to your models.
  2. Set the decorate fields inside a block of `decorations` function.
  3. Declare each field with `decorate_field name, type, function, options`.
      * Name of the virtual field.
      * Type of the virtual field.
      * Function to calculate the value of the virtual field. Always receives a struct model as first param.
      * Default options for the function (arity 2) in case you need to use diferent options in each decoration.
  4. Add `decorations()` inside schema definition.
  5. Use `Decoratex.perform` function with your model.

  ## Usage examples

  Imagine that you have a blog application (with posts and comments) and you
  need on each post the count of comments with positive and negative content
  that is decided by an external natural lenguage analisys service on the fly.

      defmodule Post do
        use Ecto.Schema
        use Decoratex.Schema

        decorations do
          decorate_field :happy_comments_count, :integer, &PostHelper.count_happy_comments/1
          decorate_field :troll_comments_count, :integer, &PostHelper.count_troll_comments/1
          ...
        end

        schema "posts" do
          has_many :comments, Comment, on_delete: :delete_all

          field :title, :string
          field :body, :string

          timestamps()
          decorations()
        end
      end

  Then, you can load your post with the needed data:

      post = Post
      |> Repo.get(1)
      |> Repo.preload(:comments))

  Decorate it as you need:

      # Decorate all fields
      |> Decoratex.perform

      # Decorate one field with an atom
      |> Decoratex.perform(:happy_comments_count)

      # Decorate some fields with a list
      |> Decoratex.perform([:happy_comments_count, ...])

      # Decorate all fields except one with except key and an atom
      |> Decoratex.perform(except: :happy_comments_count)

      # Decorate all fields except some with except key and a list
      |> Decoratex.perform(except: [:happy_comments_count, ...])

  And use ´post.happy_comments_count´ wherever you want as regular post
  attribute in another methods, pattern matching, decoding as JSON...

  **NOTE:** the fields decoration needs to be defined before de schema

  ### Decorate with options

  When you need to send some options to the decoration functions, you can define a function with arity 2, and set a default value in declaration. The default options value is mandatory for default decorations:

      ```
      decorate_field :mention_comments_count, :integer, &PostHelper.count_mention_comments/2, ""
      ```

  Then, you can pass the options value when the struct is decorated

      ```
      |> Decoratex.perform(count_mention_comments: user.nickname)
      ```

  You can use a keyword list for a complex logic, but you need to care about how to manage options in the decoration function (always with arity/2), and the default options in the configurtion.

      ```
      decorate_field :censured_comments, {:array, Comment}, &PostHelper.censured_comments/2, pattern: "frack", replace: "*"
      ```

      ```
      |> Decoratex.perform(censured_comments: [pattern: list_of_words, replace: "*"])
      ```

  And you can mix simple and decorations with options with a list:

      ```
      |> Decoratex.perform([:happy_comments_count, censured_comments: [pattern: list_of_words, replace: "*"]])
      ```

  ## Reflection

  Any decorated module will generate the `__decorate__` function that can be
  used for runtime introspection of the decorations:

  * `__decoration__(field)` - Returns the decorations of a field in format `%{type: type, function: function, options: options}`;
  * `__decorations__()` - Returns all decorations of a field in format `[{field, %{type: type, function: function, options: options}}, ...]`;

  """

  @doc """
  Decorate function adds the ability to a model for load the decorate fields
  to it self.

  You can load all configured fields, load just one with an atom or some
  with a list.

  This functions just call the configured function to each field passing
  the model structure it self and it store the result in the virtual field.
  """
  @spec perform(nil) :: nil
  def perform(nil), do: nil

  @spec perform(struct) :: struct
  def perform(%module{} = element) do
    module.__decorations__ |> Enum.reduce(element, &decorate/2)
  end

  @spec perform(nil, any) :: nil
  def perform(nil, _), do: nil

  @spec perform(struct, except: atom) :: struct
  def perform(element, except: name) when is_atom(name),
    do: perform(element, except: [name])

  @spec perform(struct, atom) :: struct
  def perform(element, name) when is_atom(name), do: perform(element, [name])

  @spec perform(struct, except: list(atom)) :: struct
  def perform(%module{} = element, except: exceptions) when is_list(exceptions) do
    names = module.__decorations__ |> Enum.map(fn {name, _decoration} -> name end)
    perform(element, names -- exceptions)
  end

  @spec perform(struct, list) :: struct
  def perform(%module{} = element, names) when is_list(names) do
    names
    |> Stream.map(&(process_decoration(module, &1)))
    |> Enum.reduce(element, &decorate/2)
  end

  @spec process_decoration(atom, atom) :: tuple
  defp process_decoration(module, field) when is_atom(field) do
    {field, module.__decoration__(field)}
  end

  @spec process_decoration(atom, tuple) :: tuple
  defp process_decoration(module, {field, options}) do
    {field, Map.put(module.__decoration__(field), :options, options)}
  end

  @spec decorate(tuple, struct) :: struct
  defp decorate({name, %{function: function, options: options}}, element) do
    decorate(element, name, function, options)
  end

  @spec decorate(tuple, struct) :: struct
  defp decorate({name, %{function: function}}, element) do
    decorate(element, name, function)
  end

  @spec decorate(struct, atom, (... -> any), any) :: struct
  defp decorate(element, name, function, options) do
    %{element | name => function.(element, options)}
  end

  @spec decorate(struct, atom, (... -> any)) :: struct
  defp decorate(element, name, function) do
    %{element | name => function.(element)}
  end
end
