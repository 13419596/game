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
test_ArgumentNumTokens :: proc(t: ^testing.T) {
  test_parseNargs(t)
}

/////////////////////////////////////////////////////////

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
