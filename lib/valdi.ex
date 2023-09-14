defmodule Valdi do
  @moduledoc """
  Some helpers function to do validate data
  - Validate type
  - validate inclusion/exclusion
  - validate length for string and enumerable types
  - validate number
  - validate string format/pattern
  - validate custom function
  - validate required (not nil) or not
  - validate decimal

  Each of these validations can be used separatedly

  ```elixir
  iex> Valdi.validate_type(10, :integer)
  :ok
  iex> Valdi.validate_type(10, :string)
  {:error, "is not a string"}
  iex> Valdi.validate_number(9, [min: 10, max: 20])
  {:error, "must be greater than or equal to 10"}
  ```

  Or you can combine multiple condition at one
  ```elixir
  iex> Valdi.validate(10, type: :integer, number: [min: 10, max: 20])
  :ok
  iex> Valdi.validate("email@g.c", type: :string, format: ~r/.+@.+\.[a-z]{2,10}/)
  {:error, "does not match format"}
  ```
  """
  require Decimal

  @type error :: {:error, String.t()}

  @doc """
  Validate value against list of validations.

  ```elixir
  iex> Valdi.validate("email@g.c", type: :string, format: ~r/.+@.+\.[a-z]{2,10}/)
  {:error, "does not match format"}
  ```

  **All supported validations**:
  - `type`: validate datatype
  - `format`: check if binary value matched given regex
  - `number`: validate number value
  - `length`: validate length of supported types. See `validate_length/2` for more details.
  - `in`: validate inclusion
  - `not_in`: validate exclusion
  - `func`: custom validation function follows spec `func(any()):: :ok | {:error, message::String.t()}`
  - `each`: validate each item in list with given validator. Supports all above validator
  """
  @spec validate(any(), keyword()) :: :ok | error
  def validate(value, validators) do
    validators = sort_validator(validators)
    do_validate(value, validators, :ok)
  end

  @doc """
  Validate list value aganst validator and return error if any item is not valid.
  In case of error `{:error, errors}`, `errors` is list of error detail for all error item includes `[index, message]`

  ```elixir
  iex> Valdi.validate_list([1,2,3], type: :integer, number: [min: 2])
  {:error, [[0, "must be greater than or equal to 2"]]}
  ```
  """

  @spec validate_list(list(), keyword()) :: :ok | {:error, list()}
  def validate_list(items, validators) do
    validators = sort_validator(validators)

    items
    |> Enum.with_index()
    |> Enum.reduce({:ok, []}, fn {value, index}, {status, acc} ->
      case do_validate(value, validators, :ok) do
        :ok -> {status, acc}
        {:error, message} -> {:error, [[index, message] | acc]}
      end
    end)
    |> case do
      {:ok, _} -> :ok
      {:error, errors} -> {:error, Enum.reverse(errors)}
    end
  end

  @doc """
  Validate map value with given map specification.
  Validation spec is a map

  `validate_map` use the key from validation to extract value from input data map and then validate value against the validators for that key.

  In case of error, the error detail is a map of error for each key.

  ```elixir
  iex> validation_spec = %{
  ...>  email: [type: :string, required: true],
  ...>  password: [type: :string, length: [min: 8]],
  ...>  age: [type: :integer, number: [min: 16, max: 60]]
  ...>  }
  iex> Valdi.validate_map(%{name: "dzung", password: "123456", email: "ddd@example.com", age: 28}, validation_spec)
  {:error, %{password: "length must be greater than or equal to 8"}}
  ```
  """
  @spec validate_map(map(), map()) :: :ok | {:error, map()}
  def validate_map(data, validations_spec) do
    validations_spec
    |> Enum.reduce({:ok, []}, fn {key, validators}, {status, acc} ->
      validators = sort_validator(validators)

      case do_validate(Map.get(data, key), validators, :ok) do
        :ok -> {status, acc}
        {:error, message} -> {:error, [{key, message} | acc]}
      end
    end)
    |> case do
      {:ok, _} -> :ok
      {:error, messages} -> {:error, Enum.into(messages, %{})}
    end
  end

  # prioritize checking
  # `required` -> `type` -> others
  defp sort_validator(validators) do
    {required, validators} = Keyword.pop(validators, :required, false)
    {type, validators} = Keyword.pop(validators, :type, :any)
    validators = [{:type, type} | validators]
    [{:required, required} | validators]
  end

  defp do_validate(_, [], acc), do: acc

  defp do_validate(value, [h | t] = _validators, acc) do
    case do_validate(value, h) do
      :ok -> do_validate(value, t, acc)
      error -> error
    end
  end

  # validate required need to check nil
  defp do_validate(value, {:required = validator, opts}),
    do: get_validator(validator).(value, opts)

  # other validation is skipped if value is nil
  defp do_validate(nil, _), do: :ok
  defp do_validate(value, {:func, func}), do: func.(value)

  defp do_validate(value, {validator, opts}) do
    case get_validator(validator) do
      {:error, _} = err -> err
      validate_func -> validate_func.(value, opts)
    end
  end

  defp get_validator(:type), do: &validate_type/2
  defp get_validator(:required), do: &validate_required/2
  defp get_validator(:format), do: &validate_format/2
  defp get_validator(:number), do: &validate_number/2
  defp get_validator(:length), do: &validate_length/2
  defp get_validator(:in), do: &validate_inclusion/2
  defp get_validator(:not_in), do: &validate_exclusion/2
  defp get_validator(:each), do: &validate_each_item/2
  defp get_validator(:decimal), do: &validate_decimal/2

  defp get_validator(name), do: {:error, "validate_#{name} is not support"}

  @doc """
  Validate embed types
  """
  def validate_embed(value, embed_type)

  def validate_embed(value, {:embed, mod, params}) when is_map(value) do
    mod.validate(value, params)
  end

  def validate_embed(value, {:array, {:embed, _, _} = type}) when is_list(value) do
    array(value, &validate_embed(&1, type), true)
  end

  def validate_embed(_, _) do
    {:error, "is invalid"}
  end

  @doc """
  Validate data types.

  ```elixir
  iex> Valdi.validate_type("a string", :string)
  :ok
  iex> Valdi.validate_type("a string", :number)
  {:error, "is not a number"}
  ```

  Support built-in types:
  - `boolean`
  - `integer`
  - `float`
  - `number` (integer or float)
  - `string` | `binary`
  - `tuple`
  - `map`
  - `array`
  - `atom`
  - `function`
  - `keyword`

  It can also check extend types
  - `struct` Ex: `User`
  - `{:array, type}` : array of type
  """

  def validate_type(value, :boolean) when is_boolean(value), do: :ok
  def validate_type(value, :integer) when is_integer(value), do: :ok
  def validate_type(value, :float) when is_float(value), do: :ok
  def validate_type(value, :number) when is_number(value), do: :ok
  def validate_type(value, :string) when is_binary(value), do: :ok
  def validate_type(value, :binary) when is_binary(value), do: :ok
  def validate_type(value, :tuple) when is_tuple(value), do: :ok
  def validate_type(value, :array) when is_list(value), do: :ok
  def validate_type(value, :list) when is_list(value), do: :ok
  def validate_type(value, :atom) when is_atom(value), do: :ok
  def validate_type(value, :function) when is_function(value), do: :ok
  def validate_type(value, :map) when is_map(value), do: :ok
  def validate_type(%Decimal{} = _value, :decimal), do: :ok
  def validate_type(_value, :any), do: :ok

  def validate_type(value, {:array, type}) when is_list(value) do
    case array(value, &validate_type(&1, type)) do
      :ok -> :ok
      _ -> {:error, "is invalid"}
    end
  end

  def validate_type([] = _check_item, :keyword), do: :ok
  def validate_type([{atom, _} | _] = _check_item, :keyword) when is_atom(atom), do: :ok
  # def validate_type(value, struct_name) when is_struct(value, struct_name), do: :ok
  def validate_type(%{__struct__: struct}, struct_name) when struct == struct_name, do: :ok
  def validate_type(_, type) when is_tuple(type), do: {:error, "is not an array"}
  def validate_type(_, type), do: {:error, "is not a #{type}"}

  # loop and validate element in array using `validate_func`
  defp array(data, validate_func, return_data \\ false, acc \\ [])

  defp array([], _, return_data, acc) do
    if return_data do
      {:ok, Enum.reverse(acc)}
    else
      :ok
    end
  end

  defp array([h | t], validate_func, return_data, acc) do
    case validate_func.(h) do
      :ok ->
        array(t, validate_func, return_data, [h | acc])

      {:ok, data} ->
        array(t, validate_func, return_data, [data | acc])

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Validate value if value is not nil. This function can receive a function to dynamicall calculate required or not.

  ```elixir
  iex> Valdi.validate_required(nil, true)
  {:error, "is required"}
  iex> Valdi.validate_required(1, true)
  :ok
  iex> Valdi.validate_required(nil, false)
  :ok
  iex> Valdi.validate_required(nil, fn -> 2 == 2 end)
  {:error, "is required"}
  ```
  """

  def validate_required(value, func) when is_function(func, 0),
    do: validate_required(value, func.())

  def validate_required(nil, true), do: {:error, "is required"}
  def validate_required(_, _), do: :ok

  @doc """
  Validate number value

  ```elixir
  iex> Valdi.validate_number(12, min: 10, max: 12)
  :ok
  iex> Valdi.validate_number(12, min: 15)
  {:error, "must be greater than or equal to 15"}
  ```

  Support conditions
  - `equal_to`
  - `greater_than_or_equal_to` | `min`
  - `greater_than`
  - `less_than`
  - `less_than_or_equal_to` | `max`

      validate_number(x, [min: 10, max: 20])
  """
  @spec validate_number(integer() | float(), keyword()) :: :ok | error
  def validate_number(value, checks) when is_list(checks) do
    if is_number(value) do
      checks
      |> Enum.reduce(:ok, fn
        check, :ok ->
          validate_number(value, check)

        _, error ->
          error
      end)
    else
      {:error, "must be a number"}
    end
  end

  def validate_number(number, {:equal_to, check_value}) do
    if number == check_value do
      :ok
    else
      {:error, "must be equal to #{check_value}"}
    end
  end

  def validate_number(number, {:greater_than, check_value}) do
    if number > check_value do
      :ok
    else
      {:error, "must be greater than #{check_value}"}
    end
  end

  def validate_number(number, {:greater_than_or_equal_to, check_value}) do
    if number >= check_value do
      :ok
    else
      {:error, "must be greater than or equal to #{check_value}"}
    end
  end

  def validate_number(number, {:min, check_value}) do
    validate_number(number, {:greater_than_or_equal_to, check_value})
  end

  def validate_number(number, {:less_than, check_value}) do
    if number < check_value do
      :ok
    else
      {:error, "must be less than #{check_value}"}
    end
  end

  def validate_number(number, {:less_than_or_equal_to, check_value}) do
    if number <= check_value do
      :ok
    else
      {:error, "must be less than or equal to #{check_value}"}
    end
  end

  def validate_number(number, {:max, check_value}) do
    validate_number(number, {:less_than_or_equal_to, check_value})
  end

  def validate_number(_number, {check, _check_value}) do
    {:error, "unknown check '#{check}'"}
  end

  @doc """
  Check if length of value match given conditions. Length condions are the same with `validate_number/2`

  ```elixir
  iex> Valdi.validate_length([1], min: 2)
  {:error, "length must be greater than or equal to 2"}
  iex> Valdi.validate_length("hello", equal_to: 5)
  :ok
  ```

  **Supported types**
  - `list`
  - `map`
  - `tuple`
  - `keyword`
  - `string`
  """
  @type support_length_types :: String.t() | map() | list() | tuple()
  @spec validate_length(support_length_types, keyword()) :: :ok | error
  def validate_length(value, checks) do
    with length when is_integer(length) <- get_length(value),
         :ok <- validate_number(length, checks) do
      :ok
    else
      {:error, :wrong_type} ->
        {:error, "length check supports only lists, binaries, maps and tuples"}

      {:error, msg} ->
        {:error, "length #{msg}"}
    end
  end

  @spec get_length(any) :: pos_integer() | {:error, :wrong_type}
  defp get_length(param) when is_list(param), do: length(param)
  defp get_length(param) when is_binary(param), do: String.length(param)
  defp get_length(param) when is_map(param), do: param |> Map.keys() |> get_length()
  defp get_length(param) when is_tuple(param), do: tuple_size(param)
  defp get_length(_param), do: {:error, :wrong_type}

  @doc """
  Checks whether a string match the given regex.

  ```elixir
  iex> Valdi.validate_format("year: 2001", ~r/year:\\s\\d{4}/)
  :ok
  iex> Valdi.validate_format("hello", ~r/\d+/)
  {:error, "does not match format"}
  ```
  """
  @spec validate_format(String.t(), Regex.t()) ::
          :ok | error
  def validate_format(value, check) when is_binary(value) do
    if Regex.match?(check, value), do: :ok, else: {:error, "does not match format"}
  end

  def validate_format(_value, _check) do
    {:error, "format check only support string"}
  end

  @doc """
  Check if value is included in the given enumerable.

  ```elixir
  iex> Valdi.validate_inclusion(1, [1, 2])
  :ok
  iex> Valdi.validate_inclusion(1, {1, 2})
  {:error, "given condition does not implement protocol Enumerable"}
  iex> Valdi.validate_inclusion(1, %{a: 1, b: 2})
  {:error, "not be in the inclusion list"}
  iex> Valdi.validate_inclusion({:a, 1}, %{a: 1, b: 2})
  :ok
  ```
  """
  def validate_inclusion(value, enum) do
    if Enumerable.impl_for(enum) do
      if Enum.member?(enum, value) do
        :ok
      else
        {:error, "not be in the inclusion list"}
      end
    else
      {:error, "given condition does not implement protocol Enumerable"}
    end
  end

  @doc """
  Check if value is **not** included in the given enumerable. Similar to `validate_inclusion/2`
  """
  def validate_exclusion(value, enum) do
    if Enumerable.impl_for(enum) do
      if Enum.member?(enum, value) do
        {:error, "must not be in the exclusion list"}
      else
        :ok
      end
    else
      {:error, "given condition does not implement protocol Enumerable"}
    end
  end

  @doc """
  Apply validation for each array item
  """
  def validate_each_item(list, validations) do
    if is_list(list) do
      validate_list(list, validations)
    else
      {:error, "each validation only support array type"}
    end
  end

  @spec validate_decimal(Decimal.t(), keyword()) :: :ok | error()
  def validate_decimal(value, checks) when is_list(checks) do
    if Decimal.is_decimal(value) do
      Enum.reduce(checks, :ok, fn
         check, :ok ->
          validate_decimal(value, check)
          _, error ->
            error
      end)
    else
      {:error, "must be a decimal"}
    end
  end


  def validate_decimal(decimal, {:equal_to, %Decimal{} = check_value}) do
    if Decimal.eq?(decimal, check_value) do
      :ok
    else
      {:error, "must be equal to #{check_value}"}
    end
  end

  def validate_decimal(decimal, {:greater_than, %Decimal{} = check_value}) do
    if Decimal.gt?(decimal, check_value) do
      :ok
    else
      {:error, "must be greater than #{check_value}"}
    end
  end

  def validate_decimal(decimal, {:greater_than_or_equal_to, %Decimal{} = check_value}) do
    if Decimal.gt?(decimal, check_value) or Decimal.eq?(decimal, check_value) do
      :ok
    else
      {:error, "must be greater than or equal to #{check_value}"}
    end
  end

  def validate_decimal(decimal, {:min, check_value}) do
    validate_decimal(decimal, {:greater_than_or_equal_to, check_value})
  end

  def validate_decimal(decimal, {:less_than, %Decimal{} = check_value}) do
    if Decimal.lt?(decimal, check_value) do
      :ok
    else
      {:error, "must be lesser than #{check_value}"}
    end
  end

  def validate_decimal(decimal, {:less_than_or_equal_to, %Decimal{} = check_value}) do
    if Decimal.lt?(decimal, check_value) or Decimal.eq?(decimal, check_value) do
      :ok
    else
      {:error, "must be lesser than or equal to #{check_value}"}
    end
  end

  def validate_decimal(decimal, {:max, %Decimal{} = check_value}) do
    validate_decimal(decimal, {:less_than_or_equal_to, check_value})
  end

  def validate_decimal(_decimal, {check, %Decimal{} = _check_value}) do
    {:error, "unknown check '#{check}'"}
  end

  def validate_decimal(_decimal, {_check, check_value}) do
    {:error, "#{check_value} must be a decimal"}
  end

end
