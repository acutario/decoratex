# Decoratex

[![Hex.pm](https://img.shields.io/hexpm/dt/decoratex.svg?maxAge=2592000&style=flat-square)](https://hex.pm/packages/decoratex)

Decoratex provides an easy way to add calculated data to your Ecto model structs.

## Requirements

- Ecto 2.0 or higher

## What does this package do?

  Maybe you have been in some situations where you need some related data of a model that is not straight stored with it's attributes and it requires a complex logic to calculate their value that can't be solved with a query. Maybe you will need this data in multiple points of the instace life cicle and you want the data available in a standard way instead of using an external module function each time you need it's value.

  In this cases, this is what decoratex can do for you:

  * Add virtual fields to the model schema to let you use your model like the same model struct with these new fields.

  * Provide a function to load data in all or some of these fields whenever you want.

## Installation

The package can be installed as simply as adding `decoratex` to your list of dependencies in `mix.exs`:

```elixir
  def deps do
    [{:decoratex, "~> 0.1.0"}]
  end
```

## Usage

First of all, add `use Decoratex` to your models. Then you can set the decorate fields with `decorations` and `decorate_field` functions:

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

The decorations definition needs to be placed before schema definition, and then, you should add `add_decorations` inside the schema block: this will automatically add the virtual fields to your model.

Finally, you can use the `decorate` funciton of your model module to populate the fields that you need with the function associated to them.

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
234
```
