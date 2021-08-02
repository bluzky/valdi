# Valdi

**Data validation for Elixir**

## Installation

The package can be installed by adding `valdi` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:valdi, "~> 0.1.0"}
  ]
end
```

Document can be found at [https://hexdocs.pm/valdi](https://hexdocs.pm/valdi).

## Features
Some helpers function to do validate data
- Validate type
- validate inclusion/exclusion
- validate length for string and enumerable types
- validate number
- validate string format/pattern
- validate custom function
- validate allow_nil or not

## Usage

- Each of these validations can be used separatedly

```elixir
iex(2)>   Valdi.validate_type(10, :integer)
:ok
iex(3)>   Valdi.validate_type(10, :string)
{:error, "is not a string"}
iex(3)>   Valdi.validate_number(9, [min: 10, max: 20])
{:error, "must be greater than or equal to 10"}
```

- Or you can combine multiple condition at one

```elixir
iex(12)> Valdi.validate(10, type: :integer, number: [min: 10, max: 20])
:ok
iex(13)> Valdi.validate("email@g.c", type: :string, format: ~r/.+@.+\.[a-z]{2,10}/)
{:error, "format not matched"}
```

- You can validate list of value

```elixir
iex(51)> Valdi.validate_list([1,2,3], type: :integer, number: [min: 2])
{:error, [[0, "must be greater than or equal to 2"]]}
```

- And validate map data too
```elixir
iex(54)>  validation_spec = %{
...(54)>     email: [type: :string],
...(54)>     password: [type: :string, length: [min: 8]],
...(54)>     age: [type: :integer, number: [min: 16, max: 60]]
...(54)>   }
iex(56)> Valdi.validate_map(%{name: "dzung", password: "123456", emal: "ddd@example.com", age: 28}, validation_spec)
{:error, %{password: "length must be greater than or equal to 8"}}
```

## Supported validations
**Type validation for built-in types and collection:**

- `:boolean`
- `:integer`
- `:float`
- `:number`(int or float)
- `:string`, `:binary`(string is binary alias)
- `:tuple`
- `:array`, `:list`
- `:atom`
- `:function`
- `:map`
- `{:array, type}` array of item similar to Ecto.Schema 
- `:keyword`
- `struct` for example: `User`. it's the struct module name

```elixir
iex(11)> Valdi.validate(["one", "two", "three"],  type: {:array, :string})
:ok
iex(12)> Valdi.validate(["one", "two", "three"],  type: :array)
:ok
iex(13)> Valdi.validate(["one", "two", "three"],  type: :map)
{:error, "is not a map"}
iex(14)>
```

**Validate inclusion and exclusion**

```elixir
iex(15)> Valdi.validate("one", in: ~w(one two three))
:ok
iex(16)> Valdi.validate("five", in: ~w(one two three))
{:error, "not be in the inclusion list"}
iex(17)> Valdi.validate("five", not_in: ~w(one two three))
:ok
```

**Validate format/regex**

```elixir
iex(13)> Valdi.validate("email@g.c", type: :string, format: ~r/.+@.+\.[a-z]{2,10}/)
{:error, "format not matched"}
iex(18)> Valdi.validate("123", format: ~r/\d{3}/)
:ok
```

**Validate number**

Here are list of check condition on number value:
- `equal_to`
- `greater_than_or_equal_to` | `min`
- `greater_than`
- `less_than`
- `less_than_or_equal_to` | `max`

```elixir
iex(19)> Valdi.validate(12, number: [greater_than: 0, less_than: 20])
:ok
iex(20)> Valdi.validate(12, number: [min: 0, max: 10])
{:error, "must be less than or equal to 10"}
iex(21)> Valdi.validate(12, number: [equal_to: 10])
{:error, "must be equal to 10"}
iex(22)>
```

**Validate string and enumerable length**

Valdi supported check length for `map`, `list`, `binary`, `tuple`
All check conditions are the same with number validation

```elixir
iex(24)> Valdi.validate("mypassword", length: [min: 8, max: 16])
:ok
iex(25)> Valdi.validate([1, 2, 3], length: [min: 3])
:ok
iex(26)> Valdi.validate({"one", "two"}, length: [min: 3])
{:error, "length must be greater than or equal to 3"}
iex(27)> Valdi.validate(50, length: [min: 2])
{:error, "length check supports only lists, binaries, maps and tuples"}
```

**Custom validation function**

You can pass your validation function too. You function must follow spec:

```elixir
func(any()):: :ok | {:error, message::String.t()}
```

```elixir
iex(32)> Valdi.validate(12, func: fn val -> if is_binary(val), do: :ok, else: {:error, "not a string"} end)
{:error, "not a string"}
```
