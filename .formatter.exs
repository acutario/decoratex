locals_without_parens = [
  # Schema
  decorate_field: 3,
  decorate_field: 4,
  add_fileds: 0
]

[
  inputs: [
    "lib/**/*.{ex,exs}",
    "test/**/*.{ex,exs}",
    "mix.exs"
  ],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]