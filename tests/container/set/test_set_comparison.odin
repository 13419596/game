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
test_set_comparison :: proc(t: ^testing.T) {
  tests := [?]proc(_: ^testing.T){test_issuperset, test_issubset, test_isequal, test_isdisjoint}
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
test_issuperset :: proc(t: ^testing.T) {
  // Evaluates: lhs ⊇ rhs
  using container_set
  empty_set := makeSet(int)
  defer deleteSet(&empty_set)
  empty_array := [?]int{}
  empty_slice := empty_array[:]
  {
    tc.expect(t, issuperset(&empty_set, &empty_set))
    tc.expect(t, issuperset(&empty_set, empty_slice))
    tc.expect(t, issuperset(&empty_set, empty_array))
    tc.expect(t, issuperset(empty_slice, &empty_set))
    tc.expect(t, issuperset(empty_slice, empty_slice))
    tc.expect(t, issuperset(empty_slice, empty_array))
    tc.expect(t, issuperset(empty_array, &empty_set))
    tc.expect(t, issuperset(empty_array, empty_slice))
    tc.expect(t, issuperset(empty_array, empty_array))
  }
  array_A := [?]int{1, 2, 3}
  set_A := fromArray(array_A)
  defer deleteSet(&set_A)
  set_A1 := fromArray(array_A[1:])
  defer deleteSet(&set_A1)
  slice_A := array_A[:]
  array_B := [?]int{4, 5, 6, 7}
  set_B := fromArray(array_B)
  defer deleteSet(&set_B)
  slice_B := array_B[:]
  {
    // A ⊇ A
    tc.expect(t, issuperset(&set_A, &set_A))
    tc.expect(t, issuperset(&set_A, slice_A))
    tc.expect(t, issuperset(&set_A, array_A))
    tc.expect(t, issuperset(slice_A, &set_A))
    tc.expect(t, issuperset(slice_A, slice_A))
    tc.expect(t, issuperset(slice_A, array_A))
    tc.expect(t, issuperset(array_A, &set_A))
    tc.expect(t, issuperset(array_A, slice_A))
    tc.expect(t, issuperset(array_A, array_A))
  }
  {
    // A ⊇ ∅
    tc.expect(t, issuperset(&set_A, &empty_set))
    tc.expect(t, issuperset(&set_A, empty_slice))
    tc.expect(t, issuperset(&set_A, empty_array))
    tc.expect(t, issuperset(slice_A, &empty_set))
    tc.expect(t, issuperset(slice_A, empty_slice))
    tc.expect(t, issuperset(slice_A, empty_array))
    tc.expect(t, issuperset(array_A, &empty_set))
    tc.expect(t, issuperset(array_A, empty_slice))
    tc.expect(t, issuperset(array_A, empty_array))
  }
  {
    // A ⊇ A subset
    tc.expect(t, issuperset(&set_A, &set_A1))
    tc.expect(t, issuperset(&set_A, slice_A[1:]))
    tc.expect(t, issuperset(&set_A, array_A[1:]))
    tc.expect(t, issuperset(slice_A, &set_A1))
    tc.expect(t, issuperset(slice_A, slice_A[1:]))
    tc.expect(t, issuperset(slice_A, array_A[1:]))
    tc.expect(t, issuperset(array_A, &set_A1))
    tc.expect(t, issuperset(array_A, slice_A[1:]))
    tc.expect(t, issuperset(array_A, array_A[1:]))
  }
  // Now swap order and the result should be false
  {
    // ∅ ⊇ A
    tc.expect(t, !issuperset(&empty_set, &set_A))
    tc.expect(t, !issuperset(empty_slice, &set_A))
    tc.expect(t, !issuperset(empty_array, &set_A))
    tc.expect(t, !issuperset(&empty_set, slice_A))
    tc.expect(t, !issuperset(empty_slice, slice_A))
    tc.expect(t, !issuperset(empty_array, slice_A))
    tc.expect(t, !issuperset(&empty_set, array_A))
    tc.expect(t, !issuperset(empty_slice, array_A))
    tc.expect(t, !issuperset(empty_array, array_A))
  }
  {
    // A subset ⊇ A
    tc.expect(t, !issuperset(&set_A1, &set_A))
    tc.expect(t, !issuperset(slice_A[1:], &set_A))
    tc.expect(t, !issuperset(array_A[1:], &set_A))
    tc.expect(t, !issuperset(&set_A1, slice_A))
    tc.expect(t, !issuperset(slice_A[1:], slice_A))
    tc.expect(t, !issuperset(array_A[1:], slice_A))
    tc.expect(t, !issuperset(&set_A1, array_A))
    tc.expect(t, !issuperset(slice_A[1:], array_A))
    tc.expect(t, !issuperset(array_A[1:], array_A))
  }
  // issuperset of disjoint should be false both ways
  {
    // A ⊇ B
    tc.expect(t, !issuperset(&set_A, &set_B))
    tc.expect(t, !issuperset(slice_A, &set_B))
    tc.expect(t, !issuperset(array_A, &set_B))
    tc.expect(t, !issuperset(&set_A, slice_B))
    tc.expect(t, !issuperset(slice_A, slice_B))
    tc.expect(t, !issuperset(array_A, slice_B))
    tc.expect(t, !issuperset(&set_A, array_B))
    tc.expect(t, !issuperset(slice_A, array_B))
    tc.expect(t, !issuperset(array_A, array_B))
  }
  {
    // B ⊇ A
    tc.expect(t, !issuperset(&set_B, &set_A))
    tc.expect(t, !issuperset(slice_B, &set_A))
    tc.expect(t, !issuperset(array_B, &set_A))
    tc.expect(t, !issuperset(&set_B, slice_A))
    tc.expect(t, !issuperset(slice_B, slice_A))
    tc.expect(t, !issuperset(array_B, slice_A))
    tc.expect(t, !issuperset(&set_B, array_A))
    tc.expect(t, !issuperset(slice_B, array_A))
    tc.expect(t, !issuperset(array_B, array_A))
  }
}

@(test, private = "file")
test_issubset :: proc(t: ^testing.T) {
  // Evaluates: lhs ⊆ rhs
  using container_set
  empty_set := makeSet(int)
  defer deleteSet(&empty_set)
  empty_array := [?]int{}
  empty_slice := empty_array[:]

  {
    tc.expect(t, issubset(&empty_set, &empty_set))
    tc.expect(t, issubset(&empty_set, empty_slice))
    tc.expect(t, issubset(&empty_set, empty_array))
    tc.expect(t, issubset(empty_slice, &empty_set))
    tc.expect(t, issubset(empty_slice, empty_slice))
    tc.expect(t, issubset(empty_slice, empty_array))
    tc.expect(t, issubset(empty_array, &empty_set))
    tc.expect(t, issubset(empty_array, empty_slice))
    tc.expect(t, issubset(empty_array, empty_array))
  }
  array_A := [?]int{1, 2, 3}
  set_A := fromArray(array_A)
  defer deleteSet(&set_A)
  set_A1 := fromArray(array_A[1:])
  defer deleteSet(&set_A1)
  slice_A := array_A[:]
  array_B := [?]int{4, 5, 6, 7}
  set_B := fromArray(array_B)
  defer deleteSet(&set_B)
  slice_B := array_B[:]
  {
    // A ⊆ A
    tc.expect(t, issubset(&set_A, &set_A))
    tc.expect(t, issubset(&set_A, slice_A))
    tc.expect(t, issubset(&set_A, array_A))
    tc.expect(t, issubset(slice_A, &set_A))
    tc.expect(t, issubset(slice_A, slice_A))
    tc.expect(t, issubset(slice_A, array_A))
    tc.expect(t, issubset(array_A, &set_A))
    tc.expect(t, issubset(array_A, slice_A))
    tc.expect(t, issubset(array_A, array_A))
  }
  {
    // A ⊆ ∅
    tc.expect(t, !issubset(&set_A, &empty_set))
    tc.expect(t, !issubset(&set_A, empty_slice))
    tc.expect(t, !issubset(&set_A, empty_array))
    tc.expect(t, !issubset(slice_A, &empty_set))
    tc.expect(t, !issubset(slice_A, empty_slice))
    tc.expect(t, !issubset(slice_A, empty_array))
    tc.expect(t, !issubset(array_A, &empty_set))
    tc.expect(t, !issubset(array_A, empty_slice))
    tc.expect(t, !issubset(array_A, empty_array))
  }
  {
    // A ⊆ A subset
    tc.expect(t, !issubset(&set_A, &set_A1))
    tc.expect(t, !issubset(&set_A, slice_A[1:]))
    tc.expect(t, !issubset(&set_A, array_A[1:]))
    tc.expect(t, !issubset(slice_A, &set_A1))
    tc.expect(t, !issubset(slice_A, slice_A[1:]))
    tc.expect(t, !issubset(slice_A, array_A[1:]))
    tc.expect(t, !issubset(array_A, &set_A1))
    tc.expect(t, !issubset(array_A, slice_A[1:]))
    tc.expect(t, !issubset(array_A, array_A[1:]))
  }
  // Now swap order and the result should be true
  {
    // ∅ ⊆ A
    tc.expect(t, issubset(&empty_set, &set_A))
    tc.expect(t, issubset(empty_slice, &set_A))
    tc.expect(t, issubset(empty_array, &set_A))
    tc.expect(t, issubset(&empty_set, slice_A))
    tc.expect(t, issubset(empty_slice, slice_A))
    tc.expect(t, issubset(empty_array, slice_A))
    tc.expect(t, issubset(&empty_set, array_A))
    tc.expect(t, issubset(empty_slice, array_A))
    tc.expect(t, issubset(empty_array, array_A))
  }
  {
    // A subset ⊆ A
    tc.expect(t, issubset(&set_A1, &set_A))
    tc.expect(t, issubset(slice_A[1:], &set_A))
    tc.expect(t, issubset(array_A[1:], &set_A))
    tc.expect(t, issubset(&set_A1, slice_A))
    tc.expect(t, issubset(slice_A[1:], slice_A))
    tc.expect(t, issubset(array_A[1:], slice_A))
    tc.expect(t, issubset(&set_A1, array_A))
    tc.expect(t, issubset(slice_A[1:], array_A))
    tc.expect(t, issubset(array_A[1:], array_A))
  }
  // issubset of disjoint should be false both ways
  {
    // A ⊆ B
    tc.expect(t, !issubset(&set_A, &set_B))
    tc.expect(t, !issubset(slice_A, &set_B))
    tc.expect(t, !issubset(array_A, &set_B))
    tc.expect(t, !issubset(&set_A, slice_B))
    tc.expect(t, !issubset(slice_A, slice_B))
    tc.expect(t, !issubset(array_A, slice_B))
    tc.expect(t, !issubset(&set_A, array_B))
    tc.expect(t, !issubset(slice_A, array_B))
    tc.expect(t, !issubset(array_A, array_B))
  }
  {
    // B ⊆ A
    tc.expect(t, !issubset(&set_B, &set_A))
    tc.expect(t, !issubset(slice_B, &set_A))
    tc.expect(t, !issubset(array_B, &set_A))
    tc.expect(t, !issubset(&set_B, slice_A))
    tc.expect(t, !issubset(slice_B, slice_A))
    tc.expect(t, !issubset(array_B, slice_A))
    tc.expect(t, !issubset(&set_B, array_A))
    tc.expect(t, !issubset(slice_B, array_A))
    tc.expect(t, !issubset(array_B, array_A))
  }
}

@(test, private = "file")
test_isequal :: proc(t: ^testing.T) {
  // Evaluates: lhs == rhs
  using container_set
  empty_set := makeSet(int)
  defer deleteSet(&empty_set)
  empty_array := [?]int{}
  empty_slice := empty_array[:]
  {
    tc.expect(t, isequal(&empty_set, &empty_set))
    tc.expect(t, isequal(&empty_set, empty_slice))
    tc.expect(t, isequal(&empty_set, empty_array))
    tc.expect(t, isequal(empty_slice, &empty_set))
    tc.expect(t, isequal(empty_slice, empty_slice))
    tc.expect(t, isequal(empty_slice, empty_array))
    tc.expect(t, isequal(empty_array, &empty_set))
    tc.expect(t, isequal(empty_array, empty_slice))
    tc.expect(t, isequal(empty_array, empty_array))
  }
  array_A := [?]int{1, 2, 3}
  set_A := fromArray(array_A)
  defer deleteSet(&set_A)
  set_A1 := fromArray(array_A[1:])
  defer deleteSet(&set_A1)
  slice_A := array_A[:]
  array_B := [?]int{4, 5, 6, 7}
  set_B := fromArray(array_B)
  defer deleteSet(&set_B)
  slice_B := array_B[:]
  {
    // A == A
    tc.expect(t, isequal(&set_A, &set_A))
    tc.expect(t, isequal(&set_A, slice_A))
    tc.expect(t, isequal(&set_A, array_A))
    tc.expect(t, isequal(slice_A, &set_A))
    tc.expect(t, isequal(slice_A, slice_A))
    tc.expect(t, isequal(slice_A, array_A))
    tc.expect(t, isequal(array_A, &set_A))
    tc.expect(t, isequal(array_A, slice_A))
    tc.expect(t, isequal(array_A, array_A))
  }
  {
    // A == ∅
    tc.expect(t, !isequal(&set_A, &empty_set))
    tc.expect(t, !isequal(&set_A, empty_slice))
    tc.expect(t, !isequal(&set_A, empty_array))
    tc.expect(t, !isequal(slice_A, &empty_set))
    tc.expect(t, !isequal(slice_A, empty_slice))
    tc.expect(t, !isequal(slice_A, empty_array))
    tc.expect(t, !isequal(array_A, &empty_set))
    tc.expect(t, !isequal(array_A, empty_slice))
    tc.expect(t, !isequal(array_A, empty_array))
  }
  {
    // A == A subset
    tc.expect(t, !isequal(&set_A, &set_A1))
    tc.expect(t, !isequal(&set_A, slice_A[1:]))
    tc.expect(t, !isequal(&set_A, array_A[1:]))
    tc.expect(t, !isequal(slice_A, &set_A1))
    tc.expect(t, !isequal(slice_A, slice_A[1:]))
    tc.expect(t, !isequal(slice_A, array_A[1:]))
    tc.expect(t, !isequal(array_A, &set_A1))
    tc.expect(t, !isequal(array_A, slice_A[1:]))
    tc.expect(t, !isequal(array_A, array_A[1:]))
  }
  // Now swap order and the result should be same
  {
    // ∅ == A
    tc.expect(t, !isequal(&empty_set, &set_A))
    tc.expect(t, !isequal(empty_slice, &set_A))
    tc.expect(t, !isequal(empty_array, &set_A))
    tc.expect(t, !isequal(&empty_set, slice_A))
    tc.expect(t, !isequal(empty_slice, slice_A))
    tc.expect(t, !isequal(empty_array, slice_A))
    tc.expect(t, !isequal(&empty_set, array_A))
    tc.expect(t, !isequal(empty_slice, array_A))
    tc.expect(t, !isequal(empty_array, array_A))
  }
  {
    // A subset == A
    tc.expect(t, !isequal(&set_A1, &set_A))
    tc.expect(t, !isequal(slice_A[1:], &set_A))
    tc.expect(t, !isequal(array_A[1:], &set_A))
    tc.expect(t, !isequal(&set_A1, slice_A))
    tc.expect(t, !isequal(slice_A[1:], slice_A))
    tc.expect(t, !isequal(array_A[1:], slice_A))
    tc.expect(t, !isequal(&set_A1, array_A))
    tc.expect(t, !isequal(slice_A[1:], array_A))
    tc.expect(t, !isequal(array_A[1:], array_A))
  }
  // isequal of disjoint should be false both ways
  {
    // A == B
    tc.expect(t, !isequal(&set_A, &set_B))
    tc.expect(t, !isequal(slice_A, &set_B))
    tc.expect(t, !isequal(array_A, &set_B))
    tc.expect(t, !isequal(&set_A, slice_B))
    tc.expect(t, !isequal(slice_A, slice_B))
    tc.expect(t, !isequal(array_A, slice_B))
    tc.expect(t, !isequal(&set_A, array_B))
    tc.expect(t, !isequal(slice_A, array_B))
    tc.expect(t, !isequal(array_A, array_B))
  }
  {
    // B == A
    tc.expect(t, !isequal(&set_B, &set_A))
    tc.expect(t, !isequal(slice_B, &set_A))
    tc.expect(t, !isequal(array_B, &set_A))
    tc.expect(t, !isequal(&set_B, slice_A))
    tc.expect(t, !isequal(slice_B, slice_A))
    tc.expect(t, !isequal(array_B, slice_A))
    tc.expect(t, !isequal(&set_B, array_A))
    tc.expect(t, !isequal(slice_B, array_A))
    tc.expect(t, !isequal(array_B, array_A))
  }
}

@(test, private = "file")
test_isdisjoint :: proc(t: ^testing.T) {
  // Evaluates: (lhs ∩ rhs) == ∅
  using container_set
  empty_set := makeSet(int)
  defer deleteSet(&empty_set)
  empty_array := [?]int{}
  empty_slice := empty_array[:]
  {
    tc.expect(t, isdisjoint(&empty_set, &empty_set))
    tc.expect(t, isdisjoint(&empty_set, empty_slice))
    tc.expect(t, isdisjoint(&empty_set, empty_array))
    tc.expect(t, isdisjoint(empty_slice, &empty_set))
    tc.expect(t, isdisjoint(empty_slice, empty_slice))
    tc.expect(t, isdisjoint(empty_slice, empty_array))
    tc.expect(t, isdisjoint(empty_array, &empty_set))
    tc.expect(t, isdisjoint(empty_array, empty_slice))
    tc.expect(t, isdisjoint(empty_array, empty_array))
  }
  array_A := [?]int{1, 2, 3}
  set_A := fromArray(array_A)
  defer deleteSet(&set_A)
  set_A1 := fromArray(array_A[1:])
  defer deleteSet(&set_A1)
  set_A1C := fromArray(array_A[1:])
  defer deleteSet(&set_A1C)
  slice_A := array_A[:]
  array_B := [?]int{4, 5, 6, 7}
  set_B := fromArray(array_B)
  defer deleteSet(&set_B)
  slice_B := array_B[:]
  {
    // (A ∩ A) == ∅
    tc.expect(t, !isdisjoint(&set_A, &set_A))
    tc.expect(t, !isdisjoint(&set_A, slice_A))
    tc.expect(t, !isdisjoint(&set_A, array_A))
    tc.expect(t, !isdisjoint(slice_A, &set_A))
    tc.expect(t, !isdisjoint(slice_A, slice_A))
    tc.expect(t, !isdisjoint(slice_A, array_A))
    tc.expect(t, !isdisjoint(array_A, &set_A))
    tc.expect(t, !isdisjoint(array_A, slice_A))
    tc.expect(t, !isdisjoint(array_A, array_A))
  }
  {
    // (A ∩ ∅) == ∅
    tc.expect(t, isdisjoint(&set_A, &empty_set))
    tc.expect(t, isdisjoint(&set_A, empty_slice))
    tc.expect(t, isdisjoint(&set_A, empty_array))
    tc.expect(t, isdisjoint(slice_A, &empty_set))
    tc.expect(t, isdisjoint(slice_A, empty_slice))
    tc.expect(t, isdisjoint(slice_A, empty_array))
    tc.expect(t, isdisjoint(array_A, &empty_set))
    tc.expect(t, isdisjoint(array_A, empty_slice))
    tc.expect(t, isdisjoint(array_A, empty_array))
  }
  {
    // (A ∩ A subset) == ∅
    tc.expect(t, !isdisjoint(&set_A, &set_A1))
    tc.expect(t, !isdisjoint(&set_A, slice_A[1:]))
    tc.expect(t, !isdisjoint(&set_A, array_A[1:]))
    tc.expect(t, !isdisjoint(slice_A, &set_A1))
    tc.expect(t, !isdisjoint(slice_A, slice_A[1:]))
    tc.expect(t, !isdisjoint(slice_A, array_A[1:]))
    tc.expect(t, !isdisjoint(array_A, &set_A1))
    tc.expect(t, !isdisjoint(array_A, slice_A[1:]))
    tc.expect(t, !isdisjoint(array_A, array_A[1:]))
  }
  // Now swap order 
  {
    // (∅ ∩  ∅) == ∅
    tc.expect(t, isdisjoint(&empty_set, &set_A))
    tc.expect(t, isdisjoint(empty_slice, &set_A))
    tc.expect(t, isdisjoint(empty_array, &set_A))
    tc.expect(t, isdisjoint(&empty_set, slice_A))
    tc.expect(t, isdisjoint(empty_slice, slice_A))
    tc.expect(t, isdisjoint(empty_array, slice_A))
    tc.expect(t, isdisjoint(&empty_set, array_A))
    tc.expect(t, isdisjoint(empty_slice, array_A))
    tc.expect(t, isdisjoint(empty_array, array_A))
  }
  {
    // (A subset ∩ A) == ∅
    tc.expect(t, !isdisjoint(&set_A1, &set_A))
    tc.expect(t, !isdisjoint(slice_A[1:], &set_A))
    tc.expect(t, !isdisjoint(array_A[1:], &set_A))
    tc.expect(t, !isdisjoint(&set_A1, slice_A))
    tc.expect(t, !isdisjoint(slice_A[1:], slice_A))
    tc.expect(t, !isdisjoint(array_A[1:], slice_A))
    tc.expect(t, !isdisjoint(&set_A1, array_A))
    tc.expect(t, !isdisjoint(slice_A[1:], array_A))
    tc.expect(t, !isdisjoint(array_A[1:], array_A))
  }
  // isdisjoint of disjoint should be true both ways
  {
    // (A ∩ B) == ∅
    tc.expect(t, isdisjoint(&set_A, &set_B))
    tc.expect(t, isdisjoint(slice_A, &set_B))
    tc.expect(t, isdisjoint(array_A, &set_B))
    tc.expect(t, isdisjoint(&set_A, slice_B))
    tc.expect(t, isdisjoint(slice_A, slice_B))
    tc.expect(t, isdisjoint(array_A, slice_B))
    tc.expect(t, isdisjoint(&set_A, array_B))
    tc.expect(t, isdisjoint(slice_A, array_B))
    tc.expect(t, isdisjoint(array_A, array_B))
  }
  {
    // (B ∩ A) == ∅
    tc.expect(t, isdisjoint(&set_B, &set_A))
    tc.expect(t, isdisjoint(slice_B, &set_A))
    tc.expect(t, isdisjoint(array_B, &set_A))
    tc.expect(t, isdisjoint(&set_B, slice_A))
    tc.expect(t, isdisjoint(slice_B, slice_A))
    tc.expect(t, isdisjoint(array_B, slice_A))
    tc.expect(t, isdisjoint(&set_B, array_A))
    tc.expect(t, isdisjoint(slice_B, array_A))
    tc.expect(t, isdisjoint(array_B, array_A))
  }
}
