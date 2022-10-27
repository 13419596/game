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
test_ArgumentParser :: proc(t: ^testing.T) {
  test_makeArgumentParser(t)
}

@(test)
test_makeArgumentParser :: proc(t: ^testing.T) {
  using argparse
  ap := makeArgumentParser(prog = "prog", description = "desc", epilog = "epilog")
  tc.expect(t, len(ap.prog) != 0)
  tc.expect(t, len(ap.description) != 0)
  tc.expect(t, len(ap.epilog) != 0)
  tc.expect(t, len(ap.options) == 0)
  deleteArgumentParser(&ap)
  tc.expect(t, len(ap.prog) == 0)
  tc.expect(t, len(ap.description) == 0)
  tc.expect(t, len(ap.epilog) == 0)
  tc.expect(t, len(ap.options) == 0)
}
