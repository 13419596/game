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
  test_makeArgumentOption(t)
}

@(test)
test_makeArgumentOption :: proc(t: ^testing.T) {
  using argparse
  ao := makeArgumentOption(
    option_strings = []string{"-v", "--verbose"},
    action = ArgumentAction.StoreTrue,
    required = true,
    help = "Make program more verbose",
  )
  tc.expect(t, len(ao.option_strings) != 0)
  tc.expect(t, len(ao.help) != 0)
  deleteArgumentOption(&ao)
  tc.expect(t, len(ao.option_strings) == 0)
  tc.expect(t, len(ao.help) == 0)
}
