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

// Update == Union == Conjunction
@(test)
test_set_union :: proc(t: ^testing.T) {
  tests := [?]proc(_: ^testing.T){test_update, test_conjunction}
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
test_update :: proc(t: ^testing.T) {
  using container_set
  {
    set := makeSet(int)
    defer deleteSet(&set)
    {
      expected := [?]int{}
      arr := asArray(&set)
      defer delete(arr)
      tc.expect(t, areSortedListsEqual(arr[:], expected[:]))
    }
  }
  // update slice
  {
    set := makeSet(int)
    defer deleteSet(&set)
    expected := make([dynamic]int)
    defer delete(expected)
    for n in 0 ..< num_monte {
      {
        arr_before := asArray(&set)
        defer delete(arr_before)
        tc.expect(t, areSortedListsEqual(arr_before[:], expected[:]))
      }
      {
        update(&set, expected[:])
        arr_update_same := asArray(&set)
        defer delete(arr_update_same)
        tc.expect(t, areSortedListsEqual(arr_update_same[:], expected[:]))
      }
      {
        append(&expected, n)
        update(&set, expected[:])
        arr_update_new := asArray(&set)
        defer delete(arr_update_new)
        tc.expect(t, areSortedListsEqual(arr_update_new[:], expected[:]))
      }
      {
        update(&set, expected[:])
        arr_update_same := asArray(&set)
        defer delete(arr_update_same)
        tc.expect(t, areSortedListsEqual(arr_update_same[:], expected[:]))
      }
    }
  }
  // update sized array
  {
    {
      set := makeSet(int)
      defer deleteSet(&set)
      expected := [?]int{0, 1, 2}
      for n in 0 ..< 2 {
        update(&set, [?]int{0, 0, 1, 1, 2, 2})
        arr := asArray(&set)
        defer delete(arr)
        tc.expect(t, areSortedListsEqual(arr[:], expected[:]))
      }
    }
    {
      set := makeSet(int)
      defer deleteSet(&set)
      expected := [?]int{-1, 0, 1, 2, 99}
      for n in 0 ..< 2 {
        update(&set, [?]int{-1, 0, 0, 1, 1, 2, 2, 99, 99, 99})
        arr := asArray(&set)
        defer delete(arr)
        tc.expect(t, areSortedListsEqual(arr[:], expected[:]))
      }
    }
  }
  // update set
  {
    set := makeSet(int)
    defer deleteSet(&set)
    expected_arr := make([dynamic]int)
    defer delete(expected_arr)
    other_set := makeSet(int)
    defer deleteSet(&other_set)
    for n in 0 ..< num_monte {
      {
        arr_before := asArray(&set)
        defer delete(arr_before)
        tc.expect(t, areSortedListsEqual(arr_before[:], expected_arr[:]))
      }
      {
        update(&set, &other_set)
        arr_update_same := asArray(&set)
        defer delete(arr_update_same)
        tc.expect(t, areSortedListsEqual(arr_update_same[:], expected_arr[:]))
      }
      {
        append(&expected_arr, n)
        add(&other_set, n)
        update(&set, &other_set)
        arr_update_new := asArray(&set)
        defer delete(arr_update_new)
        tc.expect(t, areSortedListsEqual(arr_update_new[:], expected_arr[:]))
      }
      {
        update(&set, &other_set)
        arr_update_same := asArray(&set)
        defer delete(arr_update_same)
        tc.expect(t, areSortedListsEqual(arr_update_same[:], expected_arr[:]))
      }
    }
  }
}

////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////


@(test, private = "file")
test_conjunction :: proc(t: ^testing.T) {
  // Evaluates: lhs ∪ rhs
  using container_set
  empty_set := makeSet(int)
  defer deleteSet(&empty_set)
  empty_array := [?]int{}
  empty_slice := empty_array[:]
  array_A := [?]int{1, 2, 3}
  array_A1 := [?]int{2, 3}
  array_A1C := [?]int{1}
  slice_A := array_A[:]
  set_A := fromArray(array_A)
  defer deleteSet(&set_A)
  slice_A1 := array_A[1:]
  set_A1 := fromArray(slice_A1)
  defer deleteSet(&set_A1)
  slice_A1C := array_A[:1]
  set_A1C := fromArray(slice_A1C)
  defer deleteSet(&set_A1C)
  array_B := [?]int{4, 5, 6, 7}
  slice_B := array_B[:]
  set_B := fromArray(array_B)
  defer deleteSet(&set_B)
  set_AuB := copy(&set_A)
  defer deleteSet(&set_AuB)
  update(&set_AuB, &set_B)

  {
    // Set First Tests
    sets_to_test := [?]^Set(int){&empty_set, &set_A, &set_A1, &set_B}
    disjoint_set_pair := [?]^Set(int){&empty_set, &set_B, &set_B, &set_A}
    for pset, idx in sets_to_test {
      // unioning empty should result in same
      {
        tmp := conjunction(pset, &empty_set)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, pset))
      }
      {
        tmp := conjunction(pset, empty_slice)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, pset))
      }
      {
        tmp := conjunction(pset, empty_array)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, pset))
      }
      // unioning disjoint should union
      {
        tmp := conjunction(pset, disjoint_set_pair[idx])
        defer deleteSet(&tmp)
        expected := copy(pset)
        defer deleteSet(&expected)
        update(&expected, disjoint_set_pair[idx])
        tc.expect(t, isequal(&tmp, &expected))
      }
      {
        arr := asArray(disjoint_set_pair[idx])
        defer delete(arr)
        tmp := conjunction(pset, disjoint_set_pair[idx])
        defer deleteSet(&tmp)
        expected := copy(pset)
        defer deleteSet(&expected)
        update(&expected, disjoint_set_pair[idx])
        tc.expect(t, isequal(&tmp, &expected))
      }
      // unioning self should result in self
      {
        tmp := conjunction(pset, pset)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, pset))
      }
      {
        slice := asArray(pset)
        defer delete(slice)
        tmp := conjunction(pset, slice[:])
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, pset))
      }
    }
    {
      // sized self symdiff test
      tmp := conjunction(&set_A, array_A)
      defer deleteSet(&tmp)
      tc.expect(t, isequal(&tmp, array_A))
    }
    {
      // complementary subsets test
      {
        tmp := conjunction(&set_A, &set_A1)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &set_A))
      }
      {
        tmp := conjunction(&set_A, &set_A1C)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &set_A))
      }
    }
  }
  {
    // Slice First Tests
    slices_to_test := [?][]int{empty_slice, array_A[:], slice_A1, slice_B}
    disjoint_set_pair := [?]^Set(int){&empty_set, &set_B, &set_B, &set_A}
    for slice, idx in slices_to_test {
      // unioning empty should do nothing
      {
        tmp := conjunction(slice, &empty_set)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, slice))
      }
      {
        tmp := conjunction(slice, empty_slice)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, slice))
      }
      {
        tmp := conjunction(slice, empty_array)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, slice))
      }
      // unioning disjoint should union
      {
        tmp := conjunction(slice, disjoint_set_pair[idx])
        defer deleteSet(&tmp)
        expected := fromArray(slice)
        defer deleteSet(&expected)
        update(&expected, disjoint_set_pair[idx])
        tc.expect(t, isequal(&tmp, &expected))
      }
      {
        arr := asArray(disjoint_set_pair[idx])
        defer delete(arr)
        tmp := conjunction(slice, disjoint_set_pair[idx])
        defer deleteSet(&tmp)
        expected := fromArray(slice)
        defer deleteSet(&expected)
        update(&expected, disjoint_set_pair[idx])
        tc.expect(t, isequal(&tmp, &expected))
      }
      // unioning self should result in self
      {
        tmp := conjunction(slice, slice)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, slice))
      }
      {
        tmp := conjunction(slice, slice[:])
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, slice))
      }
    }
    {
      // sized self union test
      tmp := conjunction(&set_A, array_A)
      defer deleteSet(&tmp)
      tc.expect(t, isequal(&tmp, array_A))
    }
    {
      // complementary subsets test
      {
        tmp := conjunction(&set_A, &set_A1)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &set_A))
      }
      {
        tmp := conjunction(&set_A, &set_A1C)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &set_A))
      }
    }
  }
  {
    // fixed array first
    {
      // conjunction empty
      {
        tmp := conjunction(array_A, &empty_set)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
      {
        tmp := conjunction(array_A, empty_slice)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
      {
        tmp := conjunction(array_A, empty_array)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
    }
    {
      // conjunction self
      {
        tmp := conjunction(array_A, &set_A)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
      {
        tmp := conjunction(array_A, slice_A)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
      {
        tmp := conjunction(array_A, array_A)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
    }
    {
      // conjunction disjoint
      {
        tmp := conjunction(array_A, &set_B)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &set_AuB))
      }
      {
        tmp := conjunction(array_A, slice_B)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &set_AuB))
      }
      {
        tmp := conjunction(array_A, array_B)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &set_AuB))
      }
    }
    {
      // conjunction subset should result in whole set
      {
        tmp := conjunction(array_A, &set_A1)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
      {
        tmp := conjunction(array_A, slice_A1)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
      {
        tmp := conjunction(array_A, array_A1)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
    }
  }
}
