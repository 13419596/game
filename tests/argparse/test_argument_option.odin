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
  test_isShortFlag(t)
  test_isLongFlag(t)
  test_isPositionalFlag(t)
  test_getFlagType(t)
  test_makeArgumentOption(t)
  test_getDestFromFlags(t)
  test_getUsageString(t)
  test_replaceRunes(t)
  test_getHelpCache(t)
  test_parseNargs(t)
}

@(test)
test_isShortFlag :: proc(t: ^testing.T) {
  using argparse
  tc.expect(t, !_isShortFlag(""))
  tc.expect(t, !_isShortFlag("-"))
  tc.expect(t, !_isShortFlag("--"))
  tc.expect(t, _isShortFlag("-a"))
  tc.expect(t, !_isShortFlag("--a"))
  tc.expect(t, !_isShortFlag("-a-"))
  tc.expect(t, !_isShortFlag("--ab"))
  tc.expect(t, !_isShortFlag("a"))
  tc.expect(t, !_isShortFlag("ab"))
}

@(test)
test_isLongFlag :: proc(t: ^testing.T) {
  using argparse
  tc.expect(t, !_isLongFlag(""))
  tc.expect(t, !_isLongFlag("-"))
  tc.expect(t, !_isLongFlag("--"))
  tc.expect(t, !_isLongFlag("-a"))
  tc.expect(t, _isLongFlag("--a"))
  tc.expect(t, _isLongFlag("-a-"))
  tc.expect(t, _isLongFlag("--ab"))
  tc.expect(t, !_isLongFlag("a"))
  tc.expect(t, !_isLongFlag("ab"))
}
@(test)
test_isPositionalFlag :: proc(t: ^testing.T) {
  using argparse
  tc.expect(t, !_isPositionalFlag(""))
  tc.expect(t, !_isPositionalFlag("-"))
  tc.expect(t, !_isPositionalFlag("--"))
  tc.expect(t, !_isPositionalFlag("---"))
  tc.expect(t, !_isPositionalFlag("-a"))
  tc.expect(t, !_isPositionalFlag("--a"))
  tc.expect(t, !_isPositionalFlag("--ab"))
  tc.expect(t, _isPositionalFlag("a"))
  tc.expect(t, _isPositionalFlag("ab"))
}
@(test)
test_getFlagType :: proc(t: ^testing.T) {
  using argparse
  tc.expect(t, _getFlagType("") == .Invalid)
  tc.expect(t, _getFlagType("-") == .Invalid)
  tc.expect(t, _getFlagType("--") == .Invalid)
  tc.expect(t, _getFlagType("---") == .Invalid)
  tc.expect(t, _getFlagType("-a") == .Short)
  tc.expect(t, _getFlagType("-a-") == .Long)
  tc.expect(t, _getFlagType("--a") == .Long)
  tc.expect(t, _getFlagType("--ab") == .Long)
  tc.expect(t, _getFlagType("a") == .Positional)
  tc.expect(t, _getFlagType("ab") == .Positional)
}

/////////////////////////////////////////////////////////

@(test)
test_makeArgumentOption :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      ao, ok := makeArgumentOption(
        flags = []string{"-v", "--verbose"},
        action = ArgumentAction.StoreTrue,
        required = true,
        help = "Make program more verbose",
        allocator = alloc,
      )
      tc.expect(t, ok)
      tc.expect(t, len(ao.flags) != 0)
      tc.expect(t, len(ao.dest) != 0)
      tc.expect(t, ao.dest == "verbose")
      tc.expect(t, len(ao.help) != 0)
      usage := (&ao)
      deleteArgumentOption(&ao)
      tc.expect(t, len(ao.flags) == 0)
      tc.expect(t, len(ao.dest) == 0)
      tc.expect(t, len(ao.help) == 0)
      tc.expect(t, ao._cache_usage == nil)
    }
    {
      ao, ok := makeArgumentOption(
        flags = []string{},
        action = ArgumentAction.StoreTrue,
        required = true,
        help = "Make program more verbose",
        allocator = alloc,
      )
      tc.expect(t, !ok)
    }
    {
      ao, ok := makeArgumentOption(
        flags = []string{"-"},
        action = ArgumentAction.StoreTrue,
        required = true,
        help = "Make program more verbose",
        allocator = alloc,
      )
      tc.expect(t, !ok)
    }
    {
      ao, ok := makeArgumentOption(
        flags = []string{"--"},
        action = ArgumentAction.StoreTrue,
        required = true,
        help = "Make program more verbose",
        allocator = alloc,
      )
      tc.expect(t, !ok)
    }
    {
      ao, ok := makeArgumentOption(
        flags = []string{"---"},
        action = ArgumentAction.StoreTrue,
        required = true,
        help = "Make program more verbose",
        allocator = alloc,
      )
      tc.expect(t, !ok)
    }
    {
      for action in ArgumentAction {
        expected_ok := action == ArgumentAction.Store
        ao, ok := makeArgumentOption(flags = []string{"abc"}, action = action, required = true, help = "Make program more verbose", allocator = alloc)
        tc.expect(t, ok == expected_ok)
        defer deleteArgumentOption(&ao)
      }
    }
    {
      // cannot have multiple positionals
      ao, ok := makeArgumentOption(
        flags = []string{"abc", "def"},
        action = ArgumentAction.StoreTrue,
        required = true,
        help = "Make program more verbose",
        allocator = alloc,
      )
      tc.expect(t, !ok)
    }
    {
      // cannot mix positional and keyword
      ao, ok := makeArgumentOption(
        flags = []string{"abc", "--def"},
        action = ArgumentAction.StoreTrue,
        required = true,
        help = "Make program more verbose",
        allocator = alloc,
      )
      tc.expect(t, !ok)
    }
    {
      // cannot mix positional and keyword
      ao, ok := makeArgumentOption(
        flags = []string{"abc", "-d"},
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
test_getDestFromFlags :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      out, ok := _getDestFromFlags(flags = {}, allocator = alloc)
      defer delete(out)
      tc.expect(t, !ok)
    }
    {
      out, ok := _getDestFromFlags(flags = {"--"}, allocator = alloc)
      defer delete(out)
      tc.expect(t, !ok)
    }
    {
      out, ok := _getDestFromFlags(flags = {"-l", "--long"}, allocator = alloc)
      defer delete(out)
      tc.expect(t, ok)
      tc.expect(t, out == "long")
    }
    {
      out, ok := _getDestFromFlags(flags = {"--long", "--other", "-s"}, allocator = alloc)
      defer delete(out)
      tc.expect(t, ok)
      tc.expect(t, out == "long")
    }
  }
}

@(test)
test_getUsageString :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator} // context.temp_allocator}
  for alloc in allocs {
    {
      ao, ok := makeArgumentOption(
        flags = []string{"-l"},
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
        flags = []string{"-l", "--long"},
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
      ao, ok := makeArgumentOption(flags = []string{"pos"}, action = ArgumentAction.Store, required = true, help = "help", allocator = alloc, nargs = 3)
      defer deleteArgumentOption(&ao)
      tc.expect(t, ok)
      usage := _getUsageString(&ao)
      expected_usage := "pos pos pos"
      tc.expect(t, usage == expected_usage, fmt.tprintf("Expected:\"%v\". Got:\"%v\"", expected_usage, usage))
    }
    {
      ao, ok := makeArgumentOption(flags = []string{"pos+"}, action = ArgumentAction.Store, help = "Make program more verbose", allocator = alloc, nargs = "+")
      defer deleteArgumentOption(&ao)
      tc.expect(t, ok)
      usage := _getUsageString(&ao)
      expected_usage := "pos+ [pos+ ...]"
      tc.expect(t, usage == expected_usage, fmt.tprintf("Num tokens:%v\nExpected:\"%v\". Got:\"%v\"", ao.num_tokens, expected_usage, usage))
    }
    {
      ao, ok := makeArgumentOption(flags = []string{"pos*"}, action = ArgumentAction.Store, help = "Make program more verbose", allocator = alloc, nargs = "*")
      expected_len := 1
      defer deleteArgumentOption(&ao)
      tc.expect(t, ok, "Expected to be okay")
      tc.expect(t, len(ao.flags) == expected_len, fmt.tprintf("Expected len %v. Got len(flags):%v", expected_len, len(ao.flags)))
      usage := _getUsageString(&ao)
      expected_usage := "[pos* ...]"
      tc.expect(t, usage == expected_usage, fmt.tprintf("Num tokens:%v\nExpected:\"%v\". Got:\"%v\"", ao.num_tokens, expected_usage, usage))
    }
    {
      ao, ok := makeArgumentOption(flags = []string{"pos?"}, action = ArgumentAction.Store, help = "Make program more verbose", allocator = alloc, nargs = "?")
      defer deleteArgumentOption(&ao)
      tc.expect(t, ok)
      usage1 := _getUsageString(&ao)
      expected_usage1 := "[pos?]"
      tc.expect(t, usage1 == expected_usage1, fmt.tprintf("Num tokens:%v\nExpected:\"%v\". Got:\"%v\"", ao.num_tokens, expected_usage1, usage1))
      ao.num_tokens.upper = 2
      expected_usage2 := "[pos? [pos?]]"
      _clearCache(&ao)
      usage2 := _getUsageString(&ao)
      tc.expect(t, usage2 == expected_usage2, fmt.tprintf("Num tokens:%v\nExpected:\"%v\". Got:\"%v\"", ao.num_tokens, expected_usage2, usage2))
    }
  }
}

@(test)
test_getHelpCache :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      ao, ok := makeArgumentOption(flags = []string{"-l"}, action = ArgumentAction.Store, required = true, help = "0123456789\n0123456789", allocator = alloc)
      defer deleteArgumentOption(&ao)
      tc.expect(t, ok)
      help_cache := _getHelpCache(&ao)
      expected_cache_help := "  -l L                  0123456789\n                        0123456789"
      tc.expect(
        t,
        expected_cache_help == help_cache,
        fmt.tprintf("Num tokens:%v\nExpected:\"\"\"\n%v\n\"\"\".\nGot:\"\"\"\n%v\n\"\"\"", ao.num_tokens, expected_cache_help, help_cache),
      )
    }
    {
      ao, ok := makeArgumentOption(
        flags = []string{"-l", "--long"},
        action = ArgumentAction.Store,
        required = true,
        help = "0123456789\n0123456789",
        allocator = alloc,
        nargs = 10,
      )
      defer deleteArgumentOption(&ao)
      tc.expect(t, ok)
      help_cache := _getHelpCache(&ao)
      expected_cache_help := "  -l LONG LONG LONG LONG LONG LONG LONG LONG LONG LONG, --long LONG LONG LONG LONG LONG LONG LONG LONG LONG LONG\n                        0123456789\n                        0123456789"
      tc.expect(t, expected_cache_help == help_cache, fmt.tprintf("\nExpected:\"\"\"\n%v\n\"\"\".\nGot:\"\"\"\n%v\n\"\"\"", expected_cache_help, help_cache))
    }
    {
      ao, ok := makeArgumentOption(flags = []string{"pos"}, action = ArgumentAction.Store, required = true, help = "help", allocator = alloc, nargs = 3)
      defer deleteArgumentOption(&ao)
      tc.expect(t, ok)
      help_cache := _getHelpCache(&ao)
      expected_cache_help := "  pos                   help"
      tc.expect(t, expected_cache_help == help_cache, fmt.tprintf("\nExpected:\"\"\"\n%v\n\"\"\".\nGot:\"\"\"\n%v\n\"\"\"", expected_cache_help, help_cache))
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

@(test)
test_parseNargs :: proc(t: ^testing.T) {
  using argparse
  {
    values := []string{"?", "*", "+", "asdf", "?d"}
    oks := []bool{true, true, true, false, false}
    for value, idx in values {
      lbub, ok := _parseNargs({}, value)
      tc.expect(t, ok == oks[idx])
    }
  }
  {
    for value in -3 ..= 3 {
      lbub, ok := _parseNargs({}, value)
      expected_ok := value >= 0
      tc.expect(t, ok == expected_ok)
    }
  }
  {
    for action in ArgumentAction {
      lbub, ok := _parseNargs(action, {})
      tc.expect(t, ok == true)
    }
  }
}
