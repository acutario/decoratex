defmodule Decoratex do
  @moduledoc """
  This module allows to add calculated data to your Ecto model structs in an
  easy way.

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

      or

      # Decorate one fields
      |> Post.decorate(:happy_comments_count)

      or

      # Decorate some fields
      |> Post.decorate([:happy_comments_count, ...])

  And use ´post.happy_comments_count´ wherever you want as regular post attrbute
  in another methods, when decoding as JSON...

  **NOTE:** the fields decoration needs to be defined before de schema

  """

  defmacro __using__(_opts) do
    quote do
      import Decoratex

      @decorations []

      @doc """
      Decorate function adds the ability to a model for load the decorate fields
      to it self.

      You can load all configured fields, load just one with an atom or some
      with a list.

      This functions just call the configured function to each field passing
      the model structure it self and it store the result in the virtual field.
      """
      @spec decorate(struct()) :: struct()
      def decorate(element) do
        element.__struct__.__decorations__
        |> Enum.reduce(element, &do_decorate/2)
      end

      @spec decorate(struct(), atom()) :: struct()
      def decorate(element, name) when is_atom(name), do: decorate(element, [name])

      @spec decorate(struct(), list(atom())) :: struct()
      def decorate(element, names) when is_list(names) do
        element.__struct__.__decorations__
        |> Stream.filter(fn(%{name: name}) -> Enum.member?(names, name) end)
        |> Enum.reduce(element, &do_decorate/2)
      end

      defp do_decorate(%{name: name, function: function}, element) do
        do_decorate(element, name, function)
      end

      defp do_decorate(element, name, function) do
        %{element | name => function.(element)}
      end
    end
  end

  defmacro decorations(do: block) do
    quote do
      unquote(block)
      def __decorations__, do: @decorations
    end
  end

  defmacro decorate_field(name, type, function) do
    quote do
      @decorations [%{name: unquote(name), type: unquote(type), function: unquote(function)} | @decorations]
    end
  end

  defmacro add_decorations do
    quote do
      Enum.each(@decorations, fn(%{name: name, type: type}) ->
        field(name, type, virtual: true)
      end)
    end
  end
end
