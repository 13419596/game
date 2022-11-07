// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_argparse

import "core:fmt"
import "core:log"
import "core:testing"
import "game:argparse"
import tc "tests:common"

@(private = "file")
PREFIX_RUNE := '+'

@(test)
test_ArgumentFlags :: proc(t: ^testing.T) {
  test_isShortFlag(t)
  test_isLongFlag(t)
  test_isPositionalFlag(t)
  test_getFlagType(t)
  test_getDestFromFlags(t)
}

@(test)
test_isShortFlag :: proc(t: ^testing.T) {
  using argparse
  tc.expect(t, !_isShortFlag("", PREFIX_RUNE))
  tc.expect(t, !_isShortFlag("+", PREFIX_RUNE))
  tc.expect(t, !_isShortFlag("++", PREFIX_RUNE))
  tc.expect(t, _isShortFlag("+a", PREFIX_RUNE))
  tc.expect(t, !_isShortFlag("++a", PREFIX_RUNE))
  tc.expect(t, _isShortFlag("+a-", PREFIX_RUNE))
  tc.expect(t, !_isShortFlag("++ab", PREFIX_RUNE))
  tc.expect(t, !_isShortFlag("a", PREFIX_RUNE))
  tc.expect(t, !_isShortFlag("ab", PREFIX_RUNE))
}

@(test)
test_isLongFlag :: proc(t: ^testing.T) {
  using argparse
  tc.expect(t, !_isLongFlag("", PREFIX_RUNE))
  tc.expect(t, !_isLongFlag("+", PREFIX_RUNE))
  tc.expect(t, !_isLongFlag("++", PREFIX_RUNE))
  tc.expect(t, !_isLongFlag("+a", PREFIX_RUNE))
  tc.expect(t, _isLongFlag("++a", PREFIX_RUNE))
  tc.expect(t, !_isLongFlag("+a-", PREFIX_RUNE))
  tc.expect(t, _isLongFlag("++ab", PREFIX_RUNE))
  tc.expect(t, !_isLongFlag("a", PREFIX_RUNE))
  tc.expect(t, !_isLongFlag("ab", PREFIX_RUNE))
}
@(test)
test_isPositionalFlag :: proc(t: ^testing.T) {
  using argparse
  tc.expect(t, !_isPositionalFlag("", PREFIX_RUNE))
  tc.expect(t, !_isPositionalFlag("+", PREFIX_RUNE))
  tc.expect(t, !_isPositionalFlag("++", PREFIX_RUNE))
  tc.expect(t, !_isPositionalFlag("++-", PREFIX_RUNE))
  tc.expect(t, !_isPositionalFlag("+a", PREFIX_RUNE))
  tc.expect(t, !_isPositionalFlag("++a", PREFIX_RUNE))
  tc.expect(t, !_isPositionalFlag("++ab", PREFIX_RUNE))
  tc.expect(t, _isPositionalFlag("a", PREFIX_RUNE))
  tc.expect(t, _isPositionalFlag("ab", PREFIX_RUNE))
}
@(test)
test_getFlagType :: proc(t: ^testing.T) {
  using argparse
  tc.expect(t, _getFlagType("", PREFIX_RUNE) == .Invalid)
  tc.expect(t, _getFlagType("+", PREFIX_RUNE) == .Invalid)
  tc.expect(t, _getFlagType("++", PREFIX_RUNE) == .Invalid)
  tc.expect(t, _getFlagType("+++", PREFIX_RUNE) == .Invalid) // passes, but this might not be correct - TODO(revisit)
  tc.expect(t, _getFlagType("++-", PREFIX_RUNE) == .Long)
  tc.expect(t, _getFlagType("+a", PREFIX_RUNE) == .Short)
  tc.expect(t, _getFlagType("+a-", PREFIX_RUNE) == .Short)
  tc.expect(t, _getFlagType("+ab", PREFIX_RUNE) == .Short)
  tc.expect(t, _getFlagType("++a", PREFIX_RUNE) == .Long)
  tc.expect(t, _getFlagType("++ab", PREFIX_RUNE) == .Long)
  tc.expect(t, _getFlagType("a", PREFIX_RUNE) == .Positional)
  tc.expect(t, _getFlagType("ab", PREFIX_RUNE) == .Positional)
}

/////////////////////////////////////////////////////////

@(test)
test_getDestFromFlags :: proc(t: ^testing.T) {
  using argparse
  {
    out, ok := _getDestFromFlags(flags = {}, prefix = PREFIX_RUNE)
    tc.expect(t, !ok)
  }
  {
    out, ok := _getDestFromFlags(flags = {"++"}, prefix = PREFIX_RUNE)
    tc.expect(t, !ok)
  }
  {
    out, ok := _getDestFromFlags(flags = {"+l", "++long"}, prefix = PREFIX_RUNE)
    tc.expect(t, ok)
    tc.expect(t, out == "long")
  }
  {
    out, ok := _getDestFromFlags(flags = {"++long", "++other", "+s"}, prefix = PREFIX_RUNE)
    tc.expect(t, ok)
    tc.expect(t, out == "long")
  }
}

//////////////////////////////////////
