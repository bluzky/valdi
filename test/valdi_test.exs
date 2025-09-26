defmodule ValdiTest.User do
  defstruct name: nil, email: nil

  def dumb(_), do: nil
end

defmodule ValdiTest do
  use ExUnit.Case
  doctest Valdi

  alias ValdiTest.User

  @type_checks [
    [:string, "Bluz", :ok],
    [:string, 10, :error],
    [:integer, 10, :ok],
    [:integer, 10.0, :error],
    [:float, 10.1, :ok],
    [:float, 10, :error],
    [:number, 10.1, :ok],
    [:number, 10, :ok],
    [:number, "123", :error],
    [:tuple, {1, 2}, :ok],
    [:tupple, [1, 2], :error],
    [:map, %{name: "Bluz"}, :ok],
    [:map, %{"name" => "Bluz"}, :ok],
    [:map, [], :error],
    [:array, [1, 2, 3], :ok],
    [:array, 10, :error],
    [:atom, :hihi, :ok],
    [:atom, "string", :error],
    [:function, &User.dumb/1, :ok],
    [:function, "not func", :error],
    [:keyword, [limit: 12], :ok],
    [:keyword, [1, 2], :error],
    [User, %User{email: ""}, :ok],
    [User, %{}, :error],
    [{:array, User}, [%User{email: ""}], :ok],
    [{:array, User}, [], :ok],
    [{:array, User}, %{}, :error],
    [:decimal, Decimal.new("1.0"), :ok],
    [:decimal, "1.0", :error],
    [:decimal, 1.0, :error],
    [:date, ~D[2023-10-11], :ok],
    [:date, "1.0", :error],
    [:datetime, ~U[2023-10-11 09:00:00Z], :ok],
    [:datetime, "1.0", :error],
    [:naive_datetime, ~N[2023-10-11 09:10:00], :ok],
    [:naive_datetime, "1.0", :error],
    [:time, ~T[09:10:00], :ok],
    [:time, "1.0", :error]
  ]

  test "validate type" do
    @type_checks
    |> Enum.each(fn [type, value, expect] ->
      rs = Valdi.validate(value, type: type)

      if expect == :ok do
        assert :ok = rs
      else
        assert {:error, _} = rs
      end
    end)
  end

  test "validate list with invalid item type" do
    assert {:error, "is invalid"} = Valdi.validate(["hi", 10, 13], type: {:array, :string})
  end

  test "validate required=true with not nil should ok" do
    assert :ok = Valdi.validate("a string", type: :string, required: true)
  end

  test "validate required=true with nil should error" do
    assert {:error, "is required"} = Valdi.validate(nil, type: :string, required: true)
  end

  test "validate inclusion with valid value should ok" do
    assert :ok = Valdi.validate("ok", type: :string, in: ~w(ok error))
  end

  test "validate inclusion with invalid value should error" do
    assert {:error, "not be in the inclusion list"} =
             Valdi.validate("hello", type: :string, in: ~w(ok error))
  end

  test "validate enum with valid value should ok" do
    assert :ok = Valdi.validate("ok", type: :string, enum: ~w(ok error))
  end

  test "validate enum with invalid value should error" do
    assert {:error, "not be in the inclusion list"} =
             Valdi.validate("hello", type: :string, enum: ~w(ok error))
  end

  test "validate exclusion with valid value should ok" do
    assert :ok = Valdi.validate("hello", type: :string, not_in: ~w(ok error))
  end

  test "validate exclusion with invalid value should error" do
    assert {:error, "must not be in the exclusion list"} =
             Valdi.validate("ok", type: :string, not_in: ~w(ok error))
  end

  test "validate format with match string should ok" do
    assert :ok = Valdi.validate("year: 1999", type: :string, format: ~r/year:\s\d{4}/)
  end

  test "validate format with not match string should error" do
    assert {:error, "does not match format"} =
             Valdi.validate("", type: :string, format: ~r/year:\s\d{4}/)
  end

  test "validate format with number should error" do
    assert {:error, "format check only support string"} =
             Valdi.validate(10, type: :integer, format: ~r/year:\s\d{4}/)
  end

  test "validate pattern with match string should ok" do
    assert :ok = Valdi.validate("year: 1999", type: :string, pattern: ~r/year:\s\d{4}/)
  end

  test "validate pattern with not match string should error" do
    assert {:error, "does not match format"} =
             Valdi.validate("", type: :string, pattern: ~r/year:\s\d{4}/)
  end

  test "validate pattern with number should error" do
    assert {:error, "format check only support string"} =
             Valdi.validate(10, type: :integer, pattern: ~r/year:\s\d{4}/)
  end

  test "validate format with string pattern should ok" do
    assert :ok = Valdi.validate("hello world", type: :string, format: "h.*d")
  end

  test "validate format with string pattern not match should error" do
    assert {:error, "does not match format"} =
             Valdi.validate("hello", type: :string, format: "\\d+")
  end

  test "validate format with invalid string pattern should error" do
    assert {:error, "invalid regex pattern"} =
             Valdi.validate("hello", type: :string, format: "[")
  end

  test "validate pattern with string pattern should ok" do
    assert :ok = Valdi.validate("test123", type: :string, pattern: "test\\d+")
  end

  @number_tests [
    [:equal_to, 10, 10, :ok],
    [:equal_to, 10, 11, :error],
    [:greater_than_or_equal_to, 10, 10, :ok],
    [:greater_than_or_equal_to, 10, 11, :ok],
    [:greater_than_or_equal_to, 10, 9, :error],
    [:min, 10, 10, :ok],
    [:min, 10, 11, :ok],
    [:min, 10, 9, :error],
    [:greater_than, 10, 11, :ok],
    [:greater_than, 10, 10, :error],
    [:greater_than, 10, 9, :error],
    [:less_than, 10, 9, :ok],
    [:less_than, 10, 10, :error],
    [:less_than, 10, 11, :error],
    [:less_than_or_equal_to, 10, 9, :ok],
    [:less_than_or_equal_to, 10, 10, :ok],
    [:less_than_or_equal_to, 10, 11, :error],
    [:max, 10, 9, :ok],
    [:max, 10, 10, :ok],
    [:max, 10, 11, :error]
  ]
  test "validate number" do
    for [condition, value, actual_value, expect] <- @number_tests do
      rs = Valdi.validate(actual_value, type: :integer, number: [{condition, value}])

      if expect == :ok do
        assert :ok = rs
      else
        assert {:error, _} = rs
      end
    end
  end

  test "validate number with string should error" do
    assert {:error, "must be a number"} =
             Valdi.validate("magic", type: :string, number: [min: 10])
  end

  @length_tests [
    [:equal_to, 10, "1231231234", :ok],
    [:equal_to, 10, "12312312345", :error],
    [:greater_than_or_equal_to, 10, "1231231234", :ok],
    [:greater_than_or_equal_to, 10, "12312312345", :ok],
    [:greater_than_or_equal_to, 10, "123123123", :error],
    [:min, 10, "1231231234", :ok],
    [:min, 10, "12312312345", :ok],
    [:min, 10, "123123123", :error],
    [:greater_than, 10, "12312312345", :ok],
    [:greater_than, 10, "1231231234", :error],
    [:greater_than, 10, "123123123", :error],
    [:less_than, 10, "123123123", :ok],
    [:less_than, 10, "1231231234", :error],
    [:less_than, 10, "12312312345", :error],
    [:less_than_or_equal_to, 10, "123123123", :ok],
    [:less_than_or_equal_to, 10, "1231231234", :ok],
    [:less_than_or_equal_to, 10, "12312312345", :error],
    [:max, 10, "123123123", :ok],
    [:max, 10, "1231231234", :ok],
    [:max, 10, "12312312345", :error]
  ]

  test "validate length" do
    for [condition, value, actual_value, expect] <- @length_tests do
      rs = Valdi.validate(actual_value, type: :string, length: [{condition, value}])

      if expect == :ok do
        assert :ok = rs
      else
        assert {:error, _} = rs
      end
    end
  end

  @length_type_tests [
    [:array, 1, [1, 2], :ok],
    [:map, 1, %{a: 1, b: 2}, :ok],
    [:tuple, 1, {1, 2}, :ok]
  ]
  test "validate length with other types" do
    for [type, value, actual_value, expect] <- @length_type_tests do
      rs = Valdi.validate(actual_value, type: type, length: [{:greater_than, value}])

      if expect == :ok do
        assert :ok = rs
      else
        assert {:error, _} = rs
      end
    end
  end

  test "validate length for number should error" do
    {:error, "length check supports only lists, binaries, maps and tuples"} =
      Valdi.validate(10, type: :number, length: [{:greater_than, 10}])
  end

  def validate_email(value) do
    if Regex.match?(~r/[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/, value) do
      :ok
    else
      {:error, "not a valid email"}
    end
  end

  test "validate with custom function ok with good value" do
    assert :ok =
             Valdi.validate(
               "blue@hmail.com",
               type: :string,
               func: &validate_email/1
             )
  end

  test "validate with custom function error with bad value" do
    assert {:error, "not a valid email"} =
             Valdi.validate(
               "blue@hmail",
               type: :string,
               func: &validate_email/1
             )
  end

  test "validate map with valid data" do
    assert :ok =
             Valdi.validate_map(
               %{email: "blue@hmail.com"},
               %{email: [type: :string, func: &validate_email/1]}
             )
  end

  test "validate map with invalid data" do
    assert {:error, %{email: "not a valid email"}} =
             Valdi.validate_map(
               %{email: "blue@hmail"},
               %{email: [type: :string, func: &validate_email/1]}
             )
  end

  test "validate list with valid data" do
    assert :ok = Valdi.validate_list([10, 12], type: :integer, number: [min: 10])
  end

  test "validate list with invalid data" do
    assert {:error, [[0, "is not a number"], [1, "must be greater than or equal to 11"]]} =
             Valdi.validate_list(["hi", 10, 13], type: :number, number: [min: 11])
  end

  test "validate each for list data any item error" do
    assert {:error, [[1, "must be greater than or equal to 11"]]} =
             Valdi.validate([12, 10, 13], type: {:array, :number}, each: [number: [min: 11]])
  end

  test "validate each for list data success" do
    assert :ok = Valdi.validate([8, 10, 9], type: {:array, :number}, each: [number: [max: 11]])
  end

  @decimal_tests [
    [:equal_to, Decimal.new("10.0"), Decimal.new("10.0"), :ok],
    [:equal_to, Decimal.new("10.0"), Decimal.new("11.0"), :error],
    [:greater_than_or_equal_to, Decimal.new("10.0"), Decimal.new("10.0"), :ok],
    [:greater_than_or_equal_to, Decimal.new("10.0"), Decimal.new("11.0"), :ok],
    [:greater_than_or_equal_to, Decimal.new("10.0"), Decimal.new("9.0"), :error],
    [:min, Decimal.new("10.0"), Decimal.new("10.0"), :ok],
    [:min, Decimal.new("10.0"), Decimal.new("11.0"), :ok],
    [:min, Decimal.new("10.0"), Decimal.new("0.0"), :error],
    [:greater_than, Decimal.new("10.0"), Decimal.new("11.0"), :ok],
    [:greater_than, Decimal.new("10.0"), Decimal.new("10.0"), :error],
    [:greater_than, Decimal.new("10.0"), Decimal.new("9.0"), :error],
    [:less_than, Decimal.new("10.0"), Decimal.new("9.0"), :ok],
    [:less_than, Decimal.new("10.0"), Decimal.new("10.0"), :error],
    [:less_than, Decimal.new("10.0"), Decimal.new("11.0"), :error],
    [:less_than_or_equal_to, Decimal.new("10.0"), Decimal.new("9.0"), :ok],
    [:less_than_or_equal_to, Decimal.new("10.0"), Decimal.new("10.0"), :ok],
    [:less_than_or_equal_to, Decimal.new("10.0"), Decimal.new("11.0"), :error],
    [:max, Decimal.new("10.0"), Decimal.new("9.0"), :ok],
    [:max, Decimal.new("10.0"), Decimal.new("10.0"), :ok],
    [:max, Decimal.new("10.0"), Decimal.new("11.0"), :error],
    [:unknown_check, Decimal.new("10.0"), Decimal.new("11.0"), :error],
    [:min, 11, Decimal.new("11.0"), :error]
  ]
  test "validate decimal" do
    for [condition, value, actual_value, expect] <- @decimal_tests do
      rs = Valdi.validate(actual_value, type: :decimal, decimal: [{condition, value}])

      if expect == :ok do
        assert :ok = rs
      else
        assert {:error, _} = rs
      end
    end
  end
end
