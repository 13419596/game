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
test_set_basic :: proc(t: ^testing.T) {
  tests := []proc(_: ^testing.T){
    test_reset,
    test_copy,
    test_asArray,
    test_fromArray,
    test_size,
    test_add,
    test_discard,
    test_pop,
    test_pop_safe,
    test_contains,
  }
  for test in tests {
    test(t)
  }
}

@(test, private = "file")
test_reset :: proc(t: ^testing.T) {
  using container_set
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    tracking_allocator := mem.Tracking_Allocator{}
    mem.tracking_allocator_init(&tracking_allocator, alloc)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    {
      set := makeSet(int)
      defer deleteSet(&set)
      tc.expect(t, len(set.set) == 0, "intial zero length")
      set.set[3] = 3
      tc.expect(t, len(set.set) != 0)
      reset(&set)
      tc.expect(t, len(set.set) == 0, "reset should set length back to zero.")
    }
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
  }
}

@(test, private = "file")
test_copy :: proc(t: ^testing.T) {
  using container_set
  using rand
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    tracking_allocator := mem.Tracking_Allocator{}
    mem.tracking_allocator_init(&tracking_allocator, alloc)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    {
      set1 := makeSet(int)
      defer deleteSet(&set1)
      set2 := makeSet(int)
      defer deleteSet(&set2)
      tc.expect(t, areMapsKeysEqual(&set1.set, &set2.set), "initial set innards should be equal")
    }
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
    {
      set1 := makeSet(int)
      defer deleteSet(&set1)
      set2 := copy(&set1)
      defer deleteSet(&set2)
      tc.expect(t, areMapsKeysEqual(&set1.set, &set2.set), "initial copied set innards should be equal")
    }
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
    {
      for monte in 0 ..< num_monte {
        set1 := randomSetInt()
        defer deleteSet(&set1)
        set2 := copy(&set1)
        defer deleteSet(&set2)
        tc.expect(t, areMapsKeysEqual(&set1.set, &set2.set))
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
test_asArray :: proc(t: ^testing.T) {
  using container_set
  using rand
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    tracking_allocator := mem.Tracking_Allocator{}
    mem.tracking_allocator_init(&tracking_allocator, alloc)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    {
      set := makeSet(int)
      defer deleteSet(&set)
      arr := asArray(&set)
      defer delete(arr)
      tc.expect(t, len(arr) == 0, "initial set should result in empty array")
    }
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
    {
      for n in 0 ..< num_monte {
        set := makeSet(int)
        defer deleteSet(&set)
        for i in 0 ..< n {
          set.set[i] = {}
        }
        arr := asArray(&set)
        defer delete(arr)
        tc.expect(t, len(arr) == n, "output array should have length n")
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
test_fromArray :: proc(t: ^testing.T) {
  using container_set
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    tracking_allocator := mem.Tracking_Allocator{}
    mem.tracking_allocator_init(&tracking_allocator, alloc)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    //from slice
    {
      for n in 0 ..< num_monte {
        expected := make([dynamic]int, 0, n)
        defer delete(expected)
        for i in 0 ..< n {
          append(&expected, i)
        }
        set := fromArray(expected[:])
        defer deleteSet(&set)
        arr := asArray(&set)
        defer delete(arr)
        tc.expect(t, areSortedListsEqual(arr[:], expected[:]))
      }
    }
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
    //from array
    {
      expected := [?]int{-1, 0, 1, 2, 99}
      set := fromArray([?]int{-1, 0, 1, 2, 99})
      defer deleteSet(&set)
      arr := asArray(&set)
      defer delete(arr)
      tc.expect(t, areSortedListsEqual(arr[:], expected[:]))
    }
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
  }
}


@(test, private = "file")
test_size :: proc(t: ^testing.T) {
  using container_set
  using rand
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    tracking_allocator := mem.Tracking_Allocator{}
    mem.tracking_allocator_init(&tracking_allocator, alloc)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    {
      set := makeSet(int)
      defer deleteSet(&set)
      tc.expect(t, size(&set) == 0, "initial set should result in empty array")
    }
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
    {
      for n in 0 ..< 10 {
        set := makeSet(int)
        defer deleteSet(&set)
        for i in 0 ..< n {
          tc.expect(t, size(&set) == i, "set length should equal i")
          set.set[i] = {}
          tc.expect(t, size(&set) == i + 1, "set length should equal i")
        }
        tc.expect(t, size(&set) == n, "set length should equal n")
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
test_add :: proc(t: ^testing.T) {
  using container_set
  using rand
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    tracking_allocator := mem.Tracking_Allocator{}
    mem.tracking_allocator_init(&tracking_allocator, alloc)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    {
      for n in 0 ..< 10 {
        set := makeSet(int)
        defer deleteSet(&set)
        for i in 0 ..< n {
          tc.expect(t, size(&set) == i, "set length should equal i")
          add(&set, i)
          tc.expect(t, size(&set) == i + 1, "set length should equal i")
          add(&set, i)
          tc.expect(t, size(&set) == i + 1, "set length should stay the same")
        }
        tc.expect(t, size(&set) == n, "set length should equal n")
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
test_discard :: proc(t: ^testing.T) {
  using container_set
  using rand
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    tracking_allocator := mem.Tracking_Allocator{}
    mem.tracking_allocator_init(&tracking_allocator, alloc)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    {
      for n in 0 ..< 10 {
        set := makeSet(int)
        defer deleteSet(&set)
        for i in 0 ..< n {
          tc.expect(t, size(&set) == 0, "set length should equal 0")
          add(&set, i)
          tc.expect(t, size(&set) == 1, "set length should equal 1")
          discard(&set, i)
          tc.expect(t, size(&set) == 0, "set length should equal 0")
          discard(&set, i)
          tc.expect(t, size(&set) == 0, "set length should equal 0 (discard doesn't fail on duplication)")
        }
        tc.expect(t, size(&set) == 0, "set length should equal 0")
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
test_pop :: proc(t: ^testing.T) {
  using container_set
  using rand
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    tracking_allocator := mem.Tracking_Allocator{}
    mem.tracking_allocator_init(&tracking_allocator, alloc)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    {
      for n in 0 ..< 10 {
        set := makeSet(int)
        defer deleteSet(&set)
        for i in 0 ..< n {
          tc.expect(t, size(&set) == 0, "set length should equal 0")
          add(&set, i)
          tc.expect(t, size(&set) == 1, "set length should equal 1")
          item := pop(&set)
          tc.expect(t, size(&set) == 0)
          tc.expect(t, item == i)
        }
        tc.expect(t, size(&set) == 0, "set length should equal 0")
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
test_pop_safe :: proc(t: ^testing.T) {
  using container_set
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    tracking_allocator := mem.Tracking_Allocator{}
    mem.tracking_allocator_init(&tracking_allocator, alloc)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    {
      for n in 0 ..< 10 {
        set := makeSet(int)
        defer deleteSet(&set)
        for i in 0 ..< n {
          tc.expect(t, size(&set) == 0, "set length should equal 0")
          add(&set, i)
          tc.expect(t, size(&set) == 1, "set length should equal 1")
          item, ok := pop_safe(&set)
          tc.expect(t, size(&set) == 0)
          tc.expect(t, item == i)
          tc.expect(t, ok)
          item, ok = pop_safe(&set)
          tc.expect(t, size(&set) == 0)
          tc.expect(t, item == {})
          tc.expect(t, !ok)
        }
        tc.expect(t, size(&set) == 0, "set length should equal 0")
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
test_contains :: proc(t: ^testing.T) {
  using container_set
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    tracking_allocator := mem.Tracking_Allocator{}
    mem.tracking_allocator_init(&tracking_allocator, alloc)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    {
      for n in 0 ..< num_monte {
        set := makeSet(int)
        defer deleteSet(&set)
        for i in 0 ..< num_monte {
          if i < n {
            add(&set, i)
          }
          expected := i < n
          result := contains(&set, i)
          tc.expect(t, expected == result)
        }
      }
    }
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
  }
}
