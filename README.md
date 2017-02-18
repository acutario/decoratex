# Decoratex

[![Hex.pm](https://img.shields.io/hexpm/dt/trans.svg?maxAge=2592000&style=flat-square)](https://hex.pm/packages/trans)

Decoratex allow you to decorate your struct models by adding virtual attributes and load data when you need, keeping the model structure.

## Requirements

- Ecto 2.0 or higher

## What does this package do?

  Maybe you was in some situations where you need some related data of a model that is not straight stored with it's attributes and it requires a complex logic to calculate that can't be easly solved with a query. Maybe you will need this data in multiple points of the instace life cicle and you want the data available in a standar way instead of use an external module function each time you need the value.

  In this cases, this is waht decoratex can do for you:

  * Add virtual fields to the model schema to let you use your model like the same struct type with these new fields.

  * Provide a function to load data in all or some of these fields whenever you want.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  Add `decoratex` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:decoratex, "~> 0.1.0"}]
    end
    ```

## Usage

First of all, add `use Decoratex` to your models. Then you can set de decorate fields with `decorations` and `decorate_field` functions:

```elixir
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
```

The decorations definition needs to be placed before schema definition, and then, you should add `add_decortios` inside the schema block. This will add the virtual fields to your model.

Finally, you can use the new `decorate` funciton of your model module to load the the fields that you want calculate with the function associated to the field.

```elixir
post = Post
|> Repo.get(1)
|> Repo.preload(:comments))

# Decorate all fields
|> Post.decorate

# Or decorate one fields
|> Post.decorate(:happy_comments_count)

# Or decorate some fields
|> Post.decorate([:happy_comments_count, ...])

post.happy_comments_count
```
