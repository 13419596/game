// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_regex

import "core:testing"
import tc "tests:common"

main :: proc() {
  t := testing.T{}
  tests := [?]proc(_: ^testing.T){runInfixToPostixTests}
  for test in tests {
    test(&t)
  }
  tc.report(&t)
}
