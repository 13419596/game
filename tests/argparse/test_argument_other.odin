// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_argparse

import "core:fmt"
import "core:mem"
import "core:runtime"
import "core:testing"
import "game:argparse"
import tc "tests:common"


@(test)
test_ArgumentOther :: proc(t: ^testing.T) {
  test_normalizePrefix(t)
  test_stringFromRunes(t)
  test_runesFromString(t)
}

//////////////////////////////////////

@(test)
test_normalizePrefix :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    tracking_allocator := mem.Tracking_Allocator{}
    mem.tracking_allocator_init(&tracking_allocator, alloc)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    {
      input := "-/a/b"
      expected := "--a/b"
      output := _normalizePrefix(s = input, old = []rune{'-', '/'}, replacement = '-', allocator = alloc)
      defer delete(output, alloc)
      tc.expect(t, expected == output, fmt.tprintf("\nExpected:%q\n     Out:%q", expected, output))
    }
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
    {
      input := "-/a/b---"
      expected := "--a/b---"
      output := _normalizePrefix(s = input, old = "-/", replacement = '-', allocator = alloc)
      defer delete(output, alloc)
      tc.expect(t, expected == output, fmt.tprintf("\nExpected:%q\n     Out:%q", expected, output))
    }
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
    {
      input := "-/a/b---"
      expected := "//a/b---"
      output := _normalizePrefix(s = input, old = "-/", replacement = '/', allocator = alloc)
      defer delete(output, alloc)
      tc.expect(t, expected == output, fmt.tprintf("\nExpected:%q\n     Out:%q", expected, output))
    }
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
  }
}

@(test)
test_runesFromString :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    tracking_allocator := mem.Tracking_Allocator{}
    mem.tracking_allocator_init(&tracking_allocator, alloc)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    {
      input := "rün"
      expected := []rune{'r', 'ü', 'n'}
      output := _runesFromString(input[:], alloc)
      defer delete(output)
      tc.expect(t, isequal_slice(expected, output[:]), fmt.tprintf("\nExpected:%q\n     Out:%q", expected, output))
    }
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
    {
      input := ""
      expected := []rune{}
      output := _runesFromString(input[:], alloc)
      defer delete(output)
      tc.expect(t, isequal_slice(expected, output[:]), fmt.tprintf("\nExpected:%q\n     Out:%q", expected, output))
    }
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
  }
}

@(test)
test_stringFromRunes :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    tracking_allocator := mem.Tracking_Allocator{}
    mem.tracking_allocator_init(&tracking_allocator, alloc)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    {
      input := []rune{'r', 'ü', 'n'}
      expected := "rün"
      output := _stringFromRunes(input[:], alloc)
      tc.expect(t, expected == output, fmt.tprintf("\nExpected:%q\n     Out:%q", expected, output))
      defer delete(output, alloc)
    }
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
    {
      input := []rune{}
      expected := ""
      output := _stringFromRunes(input[:], alloc)
      tc.expect(t, expected == output, fmt.tprintf("\nExpected:%q\n     Out:%q", expected, output))
      defer delete(output, alloc)
    }
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
  }
}
