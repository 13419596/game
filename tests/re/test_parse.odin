// Must be run with `-collection:tests=` flag
package test_re

import "core:fmt"
import "core:testing"
import re "game:re"
import tc "tests:common"

@(test)
test_parse :: proc(t: ^testing.T) {
  test_parseUnprefixedInt(t)
}

@(test)
test_parseUnprefixedInt :: proc(t: ^testing.T) {
  using re
  {
    str := "1f"
    value, ok := parseUnprefixedInt(str)
    tc.expect(t, ok)
    tc.expect(t, value == 1)
    n := 0
    value, ok = parseUnprefixedInt(str, &n)
    tc.expect(t, ok)
    tc.expect(t, value == 1)
    tc.expect(t, n == 1)
  }
  {
    str := "100f"
    value, ok := parseUnprefixedInt(str)
    tc.expect(t, ok)
    tc.expect(t, value == 100)
    n := 0
    value, ok = parseUnprefixedInt(str, &n)
    tc.expect(t, ok)
    tc.expect(t, value == 100)
    tc.expect(t, n == 3)
  }
  {
    str := "0f"
    value, ok := parseUnprefixedInt(str)
    tc.expect(t, ok)
    tc.expect(t, value == 0)
    n := 0
    value, ok = parseUnprefixedInt(str, &n)
    tc.expect(t, ok)
    tc.expect(t, value == 0)
    tc.expect(t, n == 1)
  }
  {
    invalid_patterns := [?]string{"", "f", "00", "0000"}
    for pattern in invalid_patterns {
      value, ok := parseUnprefixedInt(pattern)
      tc.expect(t, !ok)
      n: int
      value, ok = parseUnprefixedInt(pattern, &n)
      tc.expect(t, !ok)
    }
  }
}
