// Tests "game:container/set"
// Must be run with `-collection:tests=` flag
package test_set

import "core:fmt"
import "core:io"
import rand "core:math/rand"
import "core:mem"
import "core:os"
import "core:runtime"
import "core:sort"
import "core:testing"
import tc "tests:common"
import container_set "game:container/set"

@(test)
test_set_unique_util :: proc(t: ^testing.T) {
  tests := [?]proc(_: ^testing.T){test_getUnique}
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    tracking_allocator := mem.Tracking_Allocator{}
    mem.tracking_allocator_init(&tracking_allocator, alloc)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    {
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
}

@(test, private = "file")
test_getUnique :: proc(t: ^testing.T) {
  using container_set
  {
    // test empty
    arr := [?]int{}
    expected := [?]int{}
    {
      // slice
      result := getUnique(arr[:])
      defer delete(result)
      tc.expect(t, areSortedListsEqual(result[:], expected[:]))
    }
    {
      // array
      result := getUnique(arr)
      defer delete(result)
      tc.expect(t, areSortedListsEqual(result[:], expected[:]))
    }
  }
  {
    // test repeated
    arr := [?]int{1, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 1, 2, 1, 2, 1, 3}
    expected := [?]int{1, 2, 3}
    {
      // slice
      result := getUnique(arr[:])
      defer delete(result)
      tc.expect(t, areSortedListsEqual(result[:], expected[:]))
    }
    {
      // array
      result := getUnique(arr)
      defer delete(result)
      tc.expect(t, areSortedListsEqual(result[:], expected[:]))
    }
  }
}
