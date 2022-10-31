// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_argparse

import "core:fmt"
import "core:runtime"
import "core:testing"
import "game:argparse"
import tc "tests:common"


@(test)
test_ArgumentOther :: proc(t: ^testing.T) {
  test_normalizePrefix(t)
  test_runesFromString(t)
  test_stringFromRunes(t)
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
      tc.expect(t, expected == output, fmt.tprintf("\nExpected:%q\n     Out:%q", expected, output))
      defer delete(output, alloc)
    }
    {
      input := "-/a/b---"
      expected := "--a/b---"
      output := _normalizePrefix(s = input, old = "-/", replacement = '-', allocator = alloc)
      tc.expect(t, expected == output, fmt.tprintf("\nExpected:%q\n     Out:%q", expected, output))
      defer delete(output, alloc)
    }
    {
      input := "-/a/b---"
      expected := "//a/b---"
      output := _normalizePrefix(s = input, old = "-/", replacement = '/', allocator = alloc)
      tc.expect(t, expected == output, fmt.tprintf("\nExpected:%q\n     Out:%q", expected, output))
      defer delete(output, alloc)
    }
  }
}

@(test)
test_runesFromString :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      input := "rün"
      expected := []rune{'r', 'ü', 'n'}
      output := _runesFromString(input[:], alloc)
      tc.expect(t, isequal_slice(expected, output), fmt.tprintf("\nExpected:%q\n     Out:%q", expected, output))
      defer delete(output, alloc)
    }
    {
      input := ""
      expected := []rune{}
      output := _runesFromString(input[:], alloc)
      tc.expect(t, isequal_slice(expected, output), fmt.tprintf("\nExpected:%q\n     Out:%q", expected, output))
      defer delete(output, alloc)
    }
  }
}

@(test)
test_stringFromRunes :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      input := []rune{'r', 'ü', 'n'}
      expected := "rün"
      output := _stringFromRunes(input[:], alloc)
      tc.expect(t, expected == output, fmt.tprintf("\nExpected:%q\n     Out:%q", expected, output))
      defer delete(output, alloc)
    }
    {
      input := []rune{}
      expected := ""
      output := _stringFromRunes(input[:], alloc)
      tc.expect(t, expected == output, fmt.tprintf("\nExpected:%q\n     Out:%q", expected, output))
      defer delete(output, alloc)
    }
  }
}
