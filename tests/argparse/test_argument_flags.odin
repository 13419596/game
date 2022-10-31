// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_argparse

import "core:fmt"
import "core:log"
import "core:testing"
import "game:argparse"
import tc "tests:common"

@(test)
test_ArgumentFlags :: proc(t: ^testing.T) {
  test_isShortFlag(t)
  test_isLongFlag(t)
  test_isPositionalFlag(t)
  test_getFlagType(t)
  test_getDestFromFlags(t)
  test_getShortFlagParts(t)
}

@(test)
test_isShortFlag :: proc(t: ^testing.T) {
  using argparse
  tc.expect(t, !_isShortFlag(""))
  tc.expect(t, !_isShortFlag("-"))
  tc.expect(t, !_isShortFlag("--"))
  tc.expect(t, _isShortFlag("-a"))
  tc.expect(t, !_isShortFlag("--a"))
  tc.expect(t, _isShortFlag("-a-"))
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
  tc.expect(t, !_isLongFlag("-a-"))
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
  tc.expect(t, _getFlagType("-a-") == .Short)
  tc.expect(t, _getFlagType("-ab") == .Short)
  tc.expect(t, _getFlagType("--a") == .Long)
  tc.expect(t, _getFlagType("--ab") == .Long)
  tc.expect(t, _getFlagType("a") == .Positional)
  tc.expect(t, _getFlagType("ab") == .Positional)
}

/////////////////////////////////////////////////////////

@(test)
test_getDestFromFlags :: proc(t: ^testing.T) {
  using argparse
  {
    out, ok := _getDestFromFlags(flags = {})
    tc.expect(t, !ok)
  }
  {
    out, ok := _getDestFromFlags(flags = {"--"})
    tc.expect(t, !ok)
  }
  {
    out, ok := _getDestFromFlags(flags = {"-l", "--long"})
    tc.expect(t, ok)
    tc.expect(t, out == "long")
  }
  {
    out, ok := _getDestFromFlags(flags = {"--long", "--other", "-s"})
    tc.expect(t, ok)
    tc.expect(t, out == "long")
  }
}

//////////////////////////////////////

@(test)
test_getShortFlagParts :: proc(t: ^testing.T) {
  using argparse
  {
    input := "-ab"
    expected := _ShortFlagParts {
      arg                 = input,
      flag_with_prefix    = "-a",
      flag_without_prefix = "a",
      tail                = "b",
    }
    output := _getShortFlagParts(input, '-')
    tc.expect(t, expected == output, fmt.tprintf("\nExpected:%v\n     Got:%v", expected, output))
  }
  {
    input := "-ä0123456789"
    expected := _ShortFlagParts {
      arg                 = input,
      flag_with_prefix    = "-ä",
      flag_without_prefix = "ä",
      tail                = "0123456789",
    }
    output := _getShortFlagParts(input, '-')
    tc.expect(t, expected == output, fmt.tprintf("\nExpected:%v\n     Got:%v", expected, output))
  }
}
