// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_argparse

import "core:fmt"
import "core:log"
import "core:runtime"
import "core:testing"
import "game:argparse"
import tc "tests:common"

@(test)
test_ArgumentOption :: proc(t: ^testing.T) {
  test_isShortOption(t)
  test_isLongOption(t)
  test_isPositionalOption(t)
  test_getOptionType(t)
  test_makeArgumentOption(t)
  test_getDestFromOptions(t)
  test_getUsageString(t)
  test_replaceRunes(t)
  test_getHelpCache(t)
}

@(test)
test_isShortOption :: proc(t: ^testing.T) {
  using argparse
  tc.expect(t, !_isShortOption(""))
  tc.expect(t, !_isShortOption("-"))
  tc.expect(t, !_isShortOption("--"))
  tc.expect(t, _isShortOption("-a"))
  tc.expect(t, !_isShortOption("--a"))
  tc.expect(t, !_isShortOption("--ab"))
  tc.expect(t, !_isShortOption("a"))
  tc.expect(t, !_isShortOption("ab"))
}

@(test)
test_isLongOption :: proc(t: ^testing.T) {
  using argparse
  tc.expect(t, !_isLongOption(""))
  tc.expect(t, !_isLongOption("-"))
  tc.expect(t, !_isLongOption("--"))
  tc.expect(t, !_isLongOption("-a"))
  tc.expect(t, _isLongOption("--a"))
  tc.expect(t, _isLongOption("--ab"))
  tc.expect(t, !_isLongOption("a"))
  tc.expect(t, !_isLongOption("ab"))
}
@(test)
test_isPositionalOption :: proc(t: ^testing.T) {
  using argparse
  tc.expect(t, !_isPositionalOption(""))
  tc.expect(t, !_isPositionalOption("-"))
  tc.expect(t, !_isPositionalOption("--"))
  tc.expect(t, !_isPositionalOption("---"))
  tc.expect(t, !_isPositionalOption("-a"))
  tc.expect(t, !_isPositionalOption("--a"))
  tc.expect(t, !_isPositionalOption("--ab"))
  tc.expect(t, _isPositionalOption("a"))
  tc.expect(t, _isPositionalOption("ab"))
}
@(test)
test_getOptionType :: proc(t: ^testing.T) {
  using argparse
  tc.expect(t, _getOptionType("") == .Invalid)
  tc.expect(t, _getOptionType("-") == .Invalid)
  tc.expect(t, _getOptionType("--") == .Invalid)
  tc.expect(t, _getOptionType("---") == .Invalid)
  tc.expect(t, _getOptionType("-a") == .Short)
  tc.expect(t, _getOptionType("-a-") == .Long)
  tc.expect(t, _getOptionType("--a") == .Long)
  tc.expect(t, _getOptionType("--ab") == .Long)
  tc.expect(t, _getOptionType("a") == .Positional)
  tc.expect(t, _getOptionType("ab") == .Positional)
}

/////////////////////////////////////////////////////////

@(test)
test_makeArgumentOption :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      ao, ok := makeArgumentOption(
        option_strings = []string{"-v", "--verbose"},
        action = ArgumentAction.StoreTrue,
        required = true,
        help = "Make program more verbose",
        allocator = alloc,
      )
      tc.expect(t, ok)
      tc.expect(t, len(ao.option_strings) != 0)
      tc.expect(t, len(ao.dest) != 0)
      tc.expect(t, ao.dest == "verbose")
      tc.expect(t, len(ao.help) != 0)
      usage := (&ao)
      deleteArgumentOption(&ao)
      tc.expect(t, len(ao.option_strings) == 0)
      tc.expect(t, len(ao.dest) == 0)
      tc.expect(t, len(ao.help) == 0)
      tc.expect(t, ao._cache_usage == nil)
    }
    {
      ao, ok := makeArgumentOption(
        option_strings = []string{},
        action = ArgumentAction.StoreTrue,
        required = true,
        help = "Make program more verbose",
        allocator = alloc,
      )
      tc.expect(t, !ok)
    }
    {
      ao, ok := makeArgumentOption(
        option_strings = []string{"-"},
        action = ArgumentAction.StoreTrue,
        required = true,
        help = "Make program more verbose",
        allocator = alloc,
      )
      tc.expect(t, !ok)
    }
    {
      ao, ok := makeArgumentOption(
        option_strings = []string{"--"},
        action = ArgumentAction.StoreTrue,
        required = true,
        help = "Make program more verbose",
        allocator = alloc,
      )
      tc.expect(t, !ok)
    }
    {
      ao, ok := makeArgumentOption(
        option_strings = []string{"---"},
        action = ArgumentAction.StoreTrue,
        required = true,
        help = "Make program more verbose",
        allocator = alloc,
      )
      tc.expect(t, !ok)
    }
    {
      ao, ok := makeArgumentOption(
        option_strings = []string{"abc"},
        action = ArgumentAction.StoreTrue,
        required = true,
        help = "Make program more verbose",
        allocator = alloc,
      )
      tc.expect(t, ok)
    }
    {
      ao, ok := makeArgumentOption(
        option_strings = []string{"abc", "def"},
        action = ArgumentAction.StoreTrue,
        required = true,
        help = "Make program more verbose",
        allocator = alloc,
      )
      tc.expect(t, !ok)
    }
    {
      ao, ok := makeArgumentOption(
        option_strings = []string{"abc", "--def"},
        action = ArgumentAction.StoreTrue,
        required = true,
        help = "Make program more verbose",
        allocator = alloc,
      )
      tc.expect(t, !ok)
    }
    {
      ao, ok := makeArgumentOption(
        option_strings = []string{"abc", "-d"},
        action = ArgumentAction.StoreTrue,
        required = true,
        help = "Make program more verbose",
        allocator = alloc,
      )
      tc.expect(t, !ok)
    }
  }
}

@(test)
test_getDestFromOptions :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      out, ok := _getDestFromOptions(options = {}, allocator = alloc)
      defer delete(out)
      tc.expect(t, !ok)
    }
    {
      out, ok := _getDestFromOptions(options = {"--"}, allocator = alloc)
      defer delete(out)
      tc.expect(t, !ok)
    }
    {
      out, ok := _getDestFromOptions(options = {"-l", "--long"}, allocator = alloc)
      defer delete(out)
      tc.expect(t, ok)
      tc.expect(t, out == "long")
    }
    {
      out, ok := _getDestFromOptions(options = {"--long", "--other", "-s"}, allocator = alloc)
      defer delete(out)
      tc.expect(t, ok)
      tc.expect(t, out == "long")
    }
  }
}

@(test)
test_getUsageString :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      ao, ok := makeArgumentOption(
        option_strings = []string{"-l"},
        action = ArgumentAction.Store,
        required = false,
        help = "Make program more verbose",
        allocator = alloc,
      )
      defer deleteArgumentOption(&ao)
      tc.expect(t, ok)
      usage := _getUsageString(&ao)
      expected_usage := "[-l L]"
      tc.expect(t, usage == expected_usage, fmt.tprintf("Expected:\"%v\". Got:\"%v\"", expected_usage, usage))
    }
    {
      ao, ok := makeArgumentOption(
        option_strings = []string{"-l", "--long"},
        action = ArgumentAction.Store,
        required = true,
        help = "0123456789\n0123456789",
        allocator = alloc,
        nargs = 10,
      )
      defer deleteArgumentOption(&ao)
      tc.expect(t, ok)
      usage := _getUsageString(&ao)
      expected_usage := "-l LONG LONG LONG LONG LONG LONG LONG LONG LONG LONG"
      tc.expect(t, usage == expected_usage, fmt.tprintf("Expected:\"%v\". Got:\"%v\"", expected_usage, usage))
    }
    {
      ao, ok := makeArgumentOption(
        option_strings = []string{"pos"},
        action = ArgumentAction.Store,
        required = true,
        help = "help",
        allocator = alloc,
        nargs = 3,
      )
      defer deleteArgumentOption(&ao)
      tc.expect(t, ok)
      usage := _getUsageString(&ao)
      expected_usage := "pos pos pos"
      tc.expect(t, usage == expected_usage, fmt.tprintf("Expected:\"%v\". Got:\"%v\"", expected_usage, usage))
    }
  }
}

@(test)
test_getHelpCache :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      ao, ok := makeArgumentOption(
        option_strings = []string{"-l"},
        action = ArgumentAction.Store,
        required = true,
        help = "0123456789\n0123456789",
        allocator = alloc,
      )
      defer deleteArgumentOption(&ao)
      tc.expect(t, ok)
      help_cache := _getHelpCache(&ao)
      expected_help_cache := "  -l L                  0123456789\n                        0123456789"
      tc.expect(t, expected_help_cache == help_cache, fmt.tprintf("\nExpected:\"\"\"\n%v\n\"\"\".\nGot:\"\"\"\n%v\n\"\"\"", expected_help_cache, help_cache))
    }
    {
      ao, ok := makeArgumentOption(
        option_strings = []string{"-l", "--long"},
        action = ArgumentAction.Store,
        required = true,
        help = "0123456789\n0123456789",
        allocator = alloc,
        nargs = 10,
      )
      defer deleteArgumentOption(&ao)
      tc.expect(t, ok)
      help_cache := _getHelpCache(&ao)
      expected_help_cache := "  -l LONG LONG LONG LONG LONG LONG LONG LONG LONG LONG, --long LONG LONG LONG LONG LONG LONG LONG LONG LONG LONG\n                        0123456789\n                        0123456789"
      tc.expect(t, expected_help_cache == help_cache, fmt.tprintf("\nExpected:\"\"\"\n%v\n\"\"\".\nGot:\"\"\"\n%v\n\"\"\"", expected_help_cache, help_cache))
    }
    {
      ao, ok := makeArgumentOption(
        option_strings = []string{"pos"},
        action = ArgumentAction.Store,
        required = true,
        help = "help",
        allocator = alloc,
        nargs = 3,
      )
      defer deleteArgumentOption(&ao)
      tc.expect(t, ok)
      help_cache := _getHelpCache(&ao)
      expected_help_cache := "  pos                   help"
      tc.expect(t, expected_help_cache == help_cache, fmt.tprintf("\nExpected:\"\"\"\n%v\n\"\"\".\nGot:\"\"\"\n%v\n\"\"\"", expected_help_cache, help_cache))
    }
  }
}

//////////////////////////////////////


@(test)
test_replaceRunes :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      input := "--a/b"
      expected := "--a-b"
      output := _replaceRunes(input, {'-', '/'}, '-', alloc)
      defer delete(output)
    }
  }
}
