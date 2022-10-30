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
  test_normalizePrefix(t)
}

//////////////////////////////////////

@(test)
test_normalizePrefix :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      input := "-/a/b"
      expected := "--a/b"
      output := _normalizePrefix(s = input, old = []rune{'-', '/'}, replacement = '-', allocator = alloc)
      tc.expect(t, expected == output, fmt.tprintf("\nExpected:\"%v\"\n     Out:\"%v\"", expected, output))
      defer delete(output, alloc)
    }
    {
      input := "-/a/b---"
      expected := "--a/b---"
      output := _normalizePrefix(s = input, old = "-/", replacement = '-', allocator = alloc)
      tc.expect(t, expected == output, fmt.tprintf("\nExpected:\"%v\"\n     Out:\"%v\"", expected, output))
      defer delete(output, alloc)
    }
    {
      input := "-/a/b---"
      expected := "//a/b---"
      output := _normalizePrefix(s = input, old = "-/", replacement = '/', allocator = alloc)
      tc.expect(t, expected == output, fmt.tprintf("\nExpected:\"%v\"\n     Out:\"%v\"", expected, output))
      defer delete(output, alloc)
    }
  }
}
