# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

**Setup:**
```bash
mix deps.get              # Install dependencies
```

**Testing:**
```bash
mix test                  # Run all tests
mix test test/valdi_test.exs  # Run specific test file
mix coveralls             # Run tests with coverage
mix coveralls.html        # Generate HTML coverage report
```

**Code Quality:**
```bash
mix format                # Format code according to .formatter.exs
mix docs                  # Generate documentation
```

**Build:**
```bash
mix compile               # Compile the project
```

## Project Architecture

**Valdi** is an Elixir data validation library that provides comprehensive validation functions for different data types and structures.

### Core Module Structure

The main validation logic is contained in a single module `Valdi` (lib/valdi.ex) with these key functions:

- **Main validation functions:**
  - `validate/2` - Main validation function that accepts value and list of validators
  - `validate_list/2` - Validates each item in a list against given validators
  - `validate_map/2` - Validates map values against a validation specification

- **Individual validators:**
  - `validate_type/2` - Type checking (supports built-in types, structs, arrays)
  - `validate_required/2` - Required field validation
  - `validate_number/2` - Number range validation (min/max/equal_to/greater_than/less_than)
  - `validate_decimal/2` - Decimal number validation using Decimal library
  - `validate_length/2` - Length validation for strings, lists, maps, tuples
  - `validate_format/2` - Regex pattern matching for strings (also accessible via `pattern` alias)
  - `validate_inclusion/2` & `validate_exclusion/2` - Value inclusion/exclusion in enumerables
  - `validate_each_item/2` - Applies validation to each array element

### Validation Flow

1. `validate/2` calls `prepare_validator/1` to prioritize validators (required → type → others)
2. `do_validate/3` processes validators sequentially, stopping at first error
3. Individual validator functions return `:ok` or `{:error, message}`
4. For list/map validation, errors include indexes/keys for failed items

### Supported Types

Built-in types: `:boolean`, `:integer`, `:float`, `:number`, `:string`/`:binary`, `:tuple`, `:array`/`:list`, `:atom`, `:function`, `:map`, `:keyword`, `:decimal`, `:date`, `:time`, `:datetime`, `:naive_datetime`, `:utc_datetime`

Extended types: struct modules (e.g., `User`), `{:array, type}` for typed arrays

### Testing

The test suite in test/valdi_test.exs provides comprehensive coverage with parameterized tests for different validation scenarios. Tests use ExUnit with doctest for embedded examples.