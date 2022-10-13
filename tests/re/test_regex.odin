// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_re

import "core:testing"
import tc "tests:common"

main :: proc() {
  t := testing.T{}

  test_shorthand(&t)
  test_parse(&t)
  test_match_token(&t)
  test_pattern_to_infix(&t)
  test_infix_to_postfix(&t, true)
  test_token_nfa(&t, true)
  tc.report(&t)
}
