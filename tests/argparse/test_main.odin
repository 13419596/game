// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_argparse

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
import "core:runtime"
import "core:testing"
import "game:argparse"
import tc "tests:common"

main :: proc() {
  t_inst := testing.T{}
  t := &t_inst
  console_logger := log.create_console_logger()
  defer log.destroy_file_logger(&console_logger)
  multi_logger := log.create_multi_logger(console_logger)
  defer log.destroy_multi_logger(&multi_logger)
  context.logger = multi_logger

  tracking_allocator := mem.Tracking_Allocator{}
  mem.tracking_allocator_init(&tracking_allocator, context.allocator)
  defer mem.tracking_allocator_destroy(&tracking_allocator)
  context.allocator = mem.tracking_allocator(&tracking_allocator)

  tests := []proc(_: ^testing.T){
    test_ArgumentOther,
    test_ArgumentFlags,
    test_ArgumentNumTokens,
    test_ArgumentOption,
    test_ArgParse_Keyword,
    test_ArgumentParser,
  }
  for test, idx in tests {
    test(t)
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
  }
  tc.report(t)
  tc.expect(
    t,
    len(tracking_allocator.allocation_map) == 0,
    fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
  )
}
