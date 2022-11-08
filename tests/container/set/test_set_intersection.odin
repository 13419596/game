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
test_set_intersection :: proc(t: ^testing.T) {
  tests := [?]proc(_: ^testing.T){test_intersection_update, test_intersection}
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
test_intersection_update :: proc(t: ^testing.T) {
  // Evaluates: set &= other
  using container_set
  empty_set := makeSet(int)
  defer deleteSet(&empty_set)
  empty_array := [?]int{}
  empty_slice := empty_array[:]
  array_A := [?]int{1, 2, 3}
  set_A := fromArray(array_A)
  defer deleteSet(&set_A)
  set_A1 := fromArray(array_A[1:])
  defer deleteSet(&set_A1)
  set_A1C := fromArray(array_A[:1])
  defer deleteSet(&set_A1C)
  set_B := fromArray([?]int{4, 5, 6, 7})
  defer deleteSet(&set_B)

  sets_to_test := [?]^Set(int){&empty_set, &set_A, &set_A1, &set_B}
  disjoint_set_pair := [?]^Set(int){&empty_set, &set_B, &set_B, &set_A}
  for pset, idx in sets_to_test {
    // intersecting empty should end up as nothing
    {
      tmp := copy(pset)
      defer deleteSet(&tmp)
      intersection_update(&tmp, &empty_set)
      result := isequal(&tmp, &empty_set)
      if !result {
        fmt.printf("pset:%v tmp:%v empty:%v\n", pset, tmp, empty_set)
      }
      tc.expect(t, result)
    }
    {
      tmp := copy(pset)
      defer deleteSet(&tmp)
      intersection_update(&tmp, empty_slice)
      tc.expect(t, isequal(&tmp, &empty_set))
    }
    {
      tmp := copy(pset)
      defer deleteSet(&tmp)
      intersection_update(&tmp, empty_array)
      tc.expect(t, isequal(&tmp, &empty_set))
    }
    // intersecting disjoint should end up as nothing
    {
      tmp := copy(pset)
      defer deleteSet(&tmp)
      intersection_update(&tmp, disjoint_set_pair[idx])
      tc.expect(t, isequal(&tmp, &empty_set))
    }
    {
      tmp := copy(pset)
      defer deleteSet(&tmp)
      arr := asArray(disjoint_set_pair[idx])
      defer delete(arr)
      intersection_update(&tmp, arr[:])
      tc.expect(t, isequal(&tmp, &empty_set))
    }
    // intersecting self should do nothing
    {
      tmp := copy(pset)
      defer deleteSet(&tmp)
      intersection_update(&tmp, pset)
      tc.expect(t, isequal(&tmp, pset))
    }
    {
      tmp := copy(pset)
      defer deleteSet(&tmp)
      slice := asArray(&tmp)
      defer delete(slice)
      intersection_update(&tmp, slice[:])
      tc.expect(t, isequal(&tmp, pset))
    }
  }
  {
    // sized self intersection test
    tmp := copy(&set_A)
    defer deleteSet(&tmp)
    intersection_update(&tmp, array_A)
    tc.expect(t, isequal(&tmp, &set_A))
  }
  {
    // complementary subsets test
    {
      tmp := copy(&set_A)
      defer deleteSet(&tmp)
      intersection_update(&tmp, &set_A1)
      tc.expect(t, isequal(&tmp, &set_A1))
    }
    {
      tmp := copy(&set_A)
      defer deleteSet(&tmp)
      intersection_update(&tmp, &set_A1C)
      tc.expect(t, isequal(&tmp, &set_A1C))
    }
  }
}

////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////

@(test, private = "file")
test_intersection :: proc(t: ^testing.T) {
  // Evaluates: lhs ∩ rhs
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
      // intersecting empty should be empty
      {
        tmp := intersection(pset, &empty_set)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &empty_set))
      }
      {
        tmp := intersection(pset, empty_slice)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &empty_set))
      }
      {
        tmp := intersection(pset, empty_array)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &empty_set))
      }
      // intersecting disjoint should be empty 
      {
        tmp := intersection(pset, disjoint_set_pair[idx])
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &empty_set))
      }
      {
        arr := asArray(disjoint_set_pair[idx])
        defer delete(arr)
        tmp := intersection(pset, disjoint_set_pair[idx])
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &empty_set))
      }
      // intersecting self should result in self
      {
        tmp := intersection(pset, pset)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, pset))
      }
      {
        slice := asArray(pset)
        defer delete(slice)
        tmp := intersection(pset, slice[:])
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, pset))
      }
    }
    {
      // sized self symdiff test
      tmp := intersection(&set_A, array_A)
      defer deleteSet(&tmp)
      tc.expect(t, isequal(&tmp, array_A))
    }
    {
      // complementary subsets test
      {
        tmp := intersection(&set_A, &set_A1)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &set_A1))
      }
      {
        tmp := intersection(&set_A, &set_A1C)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &set_A1C))
      }
    }
  }
  {
    // Slice First Tests
    slices_to_test := [?][]int{empty_slice, array_A[:], slice_A1, slice_B}
    disjoint_set_pair := [?]^Set(int){&empty_set, &set_B, &set_B, &set_A}
    for slice, idx in slices_to_test {
      // intersecting empty should be empty
      {
        tmp := intersection(slice, &empty_set)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, empty_slice))
      }
      {
        tmp := intersection(slice, empty_slice)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, empty_slice))
      }
      {
        tmp := intersection(slice, empty_array)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, empty_slice))
      }
      // intersecting disjoint should be empty
      {
        tmp := intersection(slice, disjoint_set_pair[idx])
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, empty_slice))
      }
      {
        arr := asArray(disjoint_set_pair[idx])
        defer delete(arr)
        tmp := intersection(slice, disjoint_set_pair[idx])
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, empty_slice))
      }
      // intersecting self should result in self
      {
        tmp := intersection(slice, slice)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, slice))
      }
      {
        tmp := intersection(slice, slice[:])
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, slice))
      }
    }
    {
      // sized self union test
      tmp := intersection(&set_A, array_A)
      defer deleteSet(&tmp)
      tc.expect(t, isequal(&tmp, array_A))
    }
    {
      // complementary subsets test
      {
        tmp := intersection(&set_A, &set_A1)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &set_A1))
      }
      {
        tmp := intersection(&set_A, &set_A1C)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &set_A1C))
      }
    }
  }
  {
    // fixed array first
    {
      // intersection empty
      {
        tmp := intersection(array_A, &empty_set)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, empty_slice))
      }
      {
        tmp := intersection(array_A, empty_slice)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, empty_slice))
      }
      {
        tmp := intersection(array_A, empty_array)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, empty_slice))
      }
    }
    {
      // intersection self
      {
        tmp := intersection(array_A, &set_A)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
      {
        tmp := intersection(array_A, slice_A)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
      {
        tmp := intersection(array_A, array_A)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
    }
    {
      // intersection disjoint
      {
        tmp := intersection(array_A, &set_B)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, empty_slice))
      }
      {
        tmp := intersection(array_A, slice_B)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, empty_slice))
      }
      {
        tmp := intersection(array_A, array_B)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, empty_slice))
      }
    }
    {
      // intersection subset should result in subset
      {
        tmp := intersection(array_A, &set_A1)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A1))
      }
      {
        tmp := intersection(array_A, slice_A1)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A1))
      }
      {
        tmp := intersection(array_A, array_A1)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A1))
      }
    }
  }
}
