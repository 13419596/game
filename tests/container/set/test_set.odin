// Tests "game:container/set"
// Must be run with `-collection:tests=` flag
package test_set

import "core:fmt"
import "core:io"
import "core:log"
import rand "core:math/rand"
import "core:mem"
import "core:os"
import "core:runtime"
import "core:sort"
import "core:testing"
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
  console_logger := log.create_console_logger()
  defer log.destroy_file_logger(&console_logger)
  multi_logger := log.create_multi_logger(console_logger)
  defer log.destroy_multi_logger(&multi_logger)
  context.logger = multi_logger

  tracking_allocator := mem.Tracking_Allocator{}
  mem.tracking_allocator_init(&tracking_allocator, context.allocator)
  defer mem.tracking_allocator_destroy(&tracking_allocator)
  context.allocator = mem.tracking_allocator(&tracking_allocator)
  {
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
      tc.expect(
        t,
        len(tracking_allocator.allocation_map) == 0,
        fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
      )
    }
  }
  tc.expect(
    t,
    len(tracking_allocator.allocation_map) == 0,
    fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
  )
}
