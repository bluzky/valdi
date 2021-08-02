defmodule ValdiTest do
  use ExUnit.Case
  doctest Valdi

  test "greets the world" do
    assert Valdi.hello() == :world
  end
end
