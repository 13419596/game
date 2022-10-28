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
test_ArgumentOther :: proc(t: ^testing.T) {
  test_replaceRunes(t)
}

//////////////////////////////////////

@(test)
test_replaceRunes :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      input := "--a/b"
      expected := "--a-b"
      output := _replaceRunes(input, {'-', '/'}, '-', alloc)
      defer delete(output)
    }
  }
}
