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

  1. Add `use Decoratex` to your models.
  2. Set the decorate fields inside a block of `decorations` function.
  3. Declare each field with `decorate_field name, type, function, options`.
      * Name of the virtual field.
      * Type of the virtual field.
      * Function to calculate the value of the virtual field. Always receives a struct model as first param.
      * Default options for the function (arity 2) in case you need to use diferent options in each decoration.
  4. Add `add_decorations` inside schema definition.
  5. Use `decorate` function of your model module.

  ## Usage examples

  Imagine that you have a blog application (with posts and comments) and you
  need on each post the count of comments with positive and negative content
  that is decided by an external natural lenguage analisys service on the fly.

      defmodule Post do
        use Ecto.Schema
        use Decoratex

        decorations do
          decorate_field :happy_comments_count, :integer, &PostHelper.count_happy_comments/1
          decorate_field :troll_comments_count, :integer, &PostHelper.count_troll_comments/1
          ...
        end

        schema "posts" do
          has_many :comments, Comment, on_delete: :delete_all

          field :title, :string
          field :body, :string

          add_decorations
        end
      end

  Then, you can load your post with the needed data:

      post = Post
      |> Repo.get(1)
      |> Repo.preload(:comments))

  Decorate it as you need:

      # Decorate all fields
      |> Post.decorate

      # Decorate one field with an atom
      |> Post.decorate(:happy_comments_count)

      # Decorate some fields with a list
      |> Post.decorate([:happy_comments_count, ...])

      # Decorate all fields except one with except key and an atom
      |> Post.decorate(except: :happy_comments_count)

      # Decorate all fields except some with except key and a list
      |> Post.decorate(except: [:happy_comments_count, ...])

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
      |> Post.decorate(count_mention_comments: user.nickname)
      ```

  You can use a keyword list for a complex logic, but you need to care about how to manage options in the decoration function (always with arity/2), and the default options in the configurtion.

      ```
      decorate_field :censured_comments, {:array, Comment}, &PostHelper.censured_comments/2, pattern: "frack", replace: "*"
      ```

      ```
      |> Post.decorate(censured_comments: [pattern: list_of_words, replace: "*"])
      ```

  And you can mix simple and decorations with options with a list:

      ```
      |> Post.decorate([:happy_comments_count, censured_comments: [pattern: list_of_words, replace: "*"]])
      ```

  """

  defmacro __using__(_opts) do
    quote do
      import Decoratex
    end
  end

  defmacro decorations(do: block) do
    quote do
      @decorations %{}
      unquote(block)
      def __decorations__, do: @decorations

      @doc """
      Decorate function adds the ability to a model for load the decorate fields
      to it self.

      You can load all configured fields, load just one with an atom or some
      with a list.

      This functions just call the configured function to each field passing
      the model structure it self and it store the result in the virtual field.
      """
      @spec decorate(nil) :: nil
      def decorate(nil), do: nil

      @spec decorate(struct) :: struct
      def decorate(element) do
        element.__struct__.__decorations__()
        |> Enum.reduce(element, &do_decorate/2)
      end

      @spec decorate(nil, any) :: nil
      def decorate(nil, _), do: nil

      @spec decorate(struct, except: atom) :: struct
      def decorate(element, except: name) when is_atom(name),
        do: decorate(element, except: [name])

      @spec decorate(struct, atom) :: struct
      def decorate(element, name) when is_atom(name), do: decorate(element, [name])

      @spec decorate(struct, except: list(atom)) :: struct
      def decorate(element, except: names) when is_list(names) do
        decorate(element, Map.keys(element.__struct__.__decorations__()) -- names)
      end

      @spec decorate(struct, list) :: struct
      def decorate(element, names) when is_list(names) do
        names
        |> Stream.map(&process_decoration/1)
        |> Enum.reduce(element, &do_decorate/2)
      end

      @spec process_decoration(atom) :: tuple
      defp process_decoration(field) when is_atom(field) do
        {field, __decorations__()[field]}
      end

      @spec process_decoration(tuple) :: tuple
      defp process_decoration({field, options}) do
        {field, Map.put(__decorations__()[field], :options, options)}
      end

      @spec do_decorate(tuple, struct) :: struct
      defp do_decorate({name, %{function: function, options: options}}, element) do
        do_decorate(element, name, function, options)
      end

      @spec do_decorate(tuple, struct) :: struct
      defp do_decorate({name, %{function: function}}, element) do
        do_decorate(element, name, function)
      end

      @spec do_decorate(struct, atom, (... -> any), any) :: struct
      defp do_decorate(element, name, function, options) do
        %{element | name => function.(element, options)}
      end

      @spec do_decorate(struct, atom, (... -> any)) :: struct
      defp do_decorate(element, name, function) do
        %{element | name => function.(element)}
      end
    end
  end

  defmacro decorate_field(name, type, function, options \\ nil) do
    quote do
      decoration =
        case :erlang.fun_info(unquote(function))[:arity] do
          1 -> %{type: unquote(type), function: unquote(function)}
          2 -> %{type: unquote(type), function: unquote(function), options: unquote(options)}
          _ -> raise "Fields only can be decotarated with functions with arity 1 or 2"
        end

      @decorations Map.put(@decorations, unquote(name), decoration)
    end
  end

  defmacro add_decorations do
    quote do
      Enum.each(@decorations, fn {name, %{type: type}} ->
        field(name, type, virtual: true)
      end)
    end
  end
end
