# Valdi

[![Build Status](https://github.com/bluzky/valdi/workflows/Elixir%20CI/badge.svg)](https://github.com/bluzky/valdi/actions) [![Coverage Status](https://coveralls.io/repos/github/bluzky/valdi/badge.svg?branch=main)](https://coveralls.io/github/bluzky/valdi?branch=main) [![Hex Version](https://img.shields.io/hexpm/v/valdi.svg)](https://hex.pm/packages/valdi) [![docs](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/valdi/)

**A comprehensive Elixir data validation library with flexible, composable validators**


## Installation

The package can be installed by adding `valdi` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:valdi, "~> 0.5.0"}
  ]
end
```

Document can be found at [https://hexdocs.pm/valdi](https://hexdocs.pm/valdi).

## Features

- ✅ **Type validation** - validate data types including numbers, strings, lists, maps, structs, and Decimal types
- ✅ **Constraint validation** - validate ranges, lengths, formats, and inclusion/exclusion
- ✅ **Flattened validators** - use convenient aliases like `min`, `max`, `min_length` without nesting
- ✅ **Pattern matching** - efficient validation dispatch using Elixir's pattern matching
- ✅ **Composable** - combine multiple validations in a single call
- ✅ **Backward compatible** - works with existing validation patterns
- ✅ **Conditional type checking** - skip type validation when not needed for better performance
- ✅ **List and map validation** - validate collections and structured data
- ✅ **Custom validators** - extend with your own validation functions
- ✅ **Flexible error handling** - option to ignore unknown validators

## Quick Start

### Basic Validation

```elixir
# Type validation
Valdi.validate("hello", type: :string)
#=> :ok

# Constraint validation without type checking (new!)
Valdi.validate("hello", min_length: 3, max_length: 10)
#=> :ok

# Combined validations
Valdi.validate(15, type: :integer, min: 10, max: 20, greater_than: 5)
#=> :ok
```

### Flattened Validators (New!)

Instead of nested syntax:
```elixir
# Old nested approach
Valdi.validate("test", type: :string, length: [min: 3, max: 10])
Valdi.validate(15, type: :integer, number: [min: 10, max: 20])
```

Use convenient flattened syntax:
```elixir
# New flattened approach
Valdi.validate("test", type: :string, min_length: 3, max_length: 10)
Valdi.validate(15, type: :integer, min: 10, max: 20)

# Mix both styles
Valdi.validate(15, min: 10, number: [max: 20])
```

### List Validation

```elixir
# Validate each item in a list
Valdi.validate_list([1, 2, 3], type: :integer, min: 0)
#=> :ok

# With errors showing item indexes
Valdi.validate_list([1, 2, 3], type: :integer, min: 2)
#=> {:error, [[0, "must be greater than or equal to 2"]]}
```

### Map Validation

```elixir
# Define validation schema
schema = %{
  name: [type: :string, required: true, min_length: 2],
  age: [type: :integer, min: 0, max: 150],
  email: [type: :string, format: ~r/.+@.+/]
}

# Validate map data
Valdi.validate_map(%{name: "John", age: 30, email: "john@example.com"}, schema)
#=> :ok

Valdi.validate_map(%{name: "J", age: 30}, schema)
#=> {:error, %{name: "length must be greater than or equal to 2"}}
```

### Individual Validators

Each validator can be used independently:

```elixir
Valdi.validate_type("hello", :string)
#=> :ok

Valdi.validate_number(15, min: 10, max: 20)
#=> :ok

Valdi.validate_length("hello", min: 3, max: 10)
#=> :ok

Valdi.validate_inclusion("red", ["red", "green", "blue"])
#=> :ok
```

## Available Validators

### Core Validators
- `type` - validate data type
- `required` - ensure value is not nil
- `format`/`pattern` - regex pattern matching
- `in`/`enum` - value inclusion validation
- `not_in` - value exclusion validation
- `func` - custom validation function

### Numeric Validators
- `number` - numeric constraints (nested syntax)
- `min` - minimum value (≥)
- `max` - maximum value (≤)
- `greater_than` - strictly greater than (>)
- `less_than` - strictly less than (<)

### Length Validators
- `length` - length constraints (nested syntax)
- `min_length` - minimum length
- `max_length` - maximum length
- `min_items` - minimum array items (alias for min_length)
- `max_items` - maximum array items (alias for max_length)

### Other Validators
- `each` - validate each item in arrays
- `decimal` - decimal validation (**deprecated**, use `number` instead)

### Supported Data Types

**Built-in types:**
- `:boolean`, `:integer`, `:float`, `:number` (int or float)
- `:string`, `:binary` (string is binary alias)
- `:tuple`, `:array`, `:list`, `:atom`, `:function`, `:map`
- `:date`, `:time`, `:datetime`, `:naive_datetime`, `:utc_datetime`
- `:keyword`, `:decimal`

**Extended types:**
- `{:array, type}` - typed arrays (e.g., `{:array, :string}`)
- `struct` modules (e.g., `User` for `%User{}` structs)

```elixir
# Type validation examples
Valdi.validate(["one", "two", "three"], type: {:array, :string})
#=> :ok

Valdi.validate(%User{name: "John"}, type: User)
#=> :ok

Valdi.validate(~D[2023-10-11], type: :date)
#=> :ok
```

## Options

- `ignore_unknown: true` - skip unknown validators instead of returning errors

```elixir
Valdi.validate("test", [type: :string, unknown_validator: :value], ignore_unknown: true)
#=> :ok
```

## Documentation

For detailed documentation, examples, and API reference, visit [https://hexdocs.pm/valdi](https://hexdocs.pm/valdi).
