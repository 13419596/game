// Must be run with `-collection:tests=` flag
package test_util

import "core:fmt"
import "core:testing"
import gm "game:gmath"
import tc "tests:common"
import "core:intrinsics"

main :: proc() {
  t := testing.T{}
  run_all(&t)
  tc.report(&t)
}

@(test)
run_all :: proc(t: ^testing.T) {
  runTests_odin_workaround(t)
}
