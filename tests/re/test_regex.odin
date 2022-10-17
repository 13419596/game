// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_re

import "core:log"
import "core:runtime"
import "core:testing"
import tc "tests:common"
import "game:glog"

main :: proc() {
  using glog
  t := testing.T{}
  console_logger := log.create_console_logger()
  defer log.destroy_file_logger(&console_logger)
  multi_logger := log.create_multi_logger(console_logger)
  defer log.destroy_multi_logger(&multi_logger)
  context.logger = multi_logger

  test_shorthand(&t)
  test_parse(&t)
  test_match_token(&t)
  test_pattern_to_infix(&t)
  test_infix_to_postfix(&t, true)
  log.debugf("---------------------------------------------------------")
  test_token_nfa(&t, true)
  tc.report(&t)
}
