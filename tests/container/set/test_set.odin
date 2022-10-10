// Tests "game:container/set"
// Must be run with `-collection:tests=` flag
package test_set

import "core:fmt"
import "core:io"
import "core:os"
import "core:testing"
import "core:sort"
import rand "core:math/rand"
import tc "tests:common"
import container_set "game:container/set"

num_monte :: 30

main :: proc() {
  t := testing.T{}
  run_all(&t)
  tc.report(&t)
}

@(test)
run_all :: proc(t: ^testing.T) {
  tests := [?]proc(_: ^testing.T){
    test_set_construction,
    test_set_basic,
    test_set_comparison,
    test_set_union,
    test_set_intersection,
    test_set_difference,
    test_set_symmetric_difference,
    test_set_unique_util,
  }
  for test in tests {
    test(t)
  }
}
