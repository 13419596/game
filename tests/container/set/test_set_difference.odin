// Tests "game:container/set"
// Must be run with `-collection:tests=` flag
package test_set

import "core:fmt"
import "core:io"
import "core:os"
import "core:testing"
import "core:sort"
import rand "core:math/rand"
import tc "tests:common"
import container_set "game:container/set"

@(test)
test_set_difference :: proc(t: ^testing.T) {
  tests := [?]proc(_: ^testing.T){test_difference_update, test_difference}
  for test in tests {
    test(t)
  }
}

@(test, private = "file")
test_difference_update :: proc(t: ^testing.T) {
  // Evaluates: set -= other
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
    // subtracting empty should do nothing
    {
      tmp := copy(pset)
      defer deleteSet(&tmp)
      difference_update(&tmp, &empty_set)
      tc.expect(t, isequal(&tmp, pset))
    }
    {
      tmp := copy(pset)
      defer deleteSet(&tmp)
      difference_update(&tmp, empty_slice)
      tc.expect(t, isequal(&tmp, pset))
    }
    {
      tmp := copy(pset)
      defer deleteSet(&tmp)
      difference_update(&tmp, empty_array)
      tc.expect(t, isequal(&tmp, pset))
    }
    // subtracting disjoint should do nothing
    {
      tmp := copy(pset)
      defer deleteSet(&tmp)
      difference_update(&tmp, disjoint_set_pair[idx])
      tc.expect(t, isequal(&tmp, pset))
    }
    {
      tmp := copy(pset)
      defer deleteSet(&tmp)
      arr := asArray(disjoint_set_pair[idx])
      defer delete(arr)
      difference_update(&tmp, arr[:])
      tc.expect(t, isequal(&tmp, pset))
    }
    // subtracting self should result in empty
    {
      tmp := copy(pset)
      defer deleteSet(&tmp)
      difference_update(&tmp, pset)
      tc.expect(t, isequal(&tmp, &empty_set))
    }
    {
      tmp := copy(pset)
      defer deleteSet(&tmp)
      slice := asArray(&tmp)
      defer delete(slice)
      difference_update(&tmp, slice[:])
      tc.expect(t, isequal(&tmp, &empty_set))
    }
  }
  {
    // sized self subtract test
    tmp := copy(&set_A)
    defer deleteSet(&tmp)
    difference_update(&tmp, array_A)
    tc.expect(t, isequal(&tmp, &empty_set))
  }
  {
    // complementary subsets test
    {
      tmp := copy(&set_A)
      defer deleteSet(&tmp)
      difference_update(&tmp, &set_A1)
      tc.expect(t, isequal(&tmp, &set_A1C))
    }
    {
      tmp := copy(&set_A)
      defer deleteSet(&tmp)
      difference_update(&tmp, &set_A1C)
      tc.expect(t, isequal(&tmp, &set_A1))
    }
  }
}

////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////

@(test, private = "file")
test_difference :: proc(t: ^testing.T) {
  // Evaluates: lhs - rhs
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

  {
    // Set First Tests
    sets_to_test := [?]^Set(int){&empty_set, &set_A, &set_A1, &set_B}
    disjoint_set_pair := [?]^Set(int){&empty_set, &set_B, &set_B, &set_A}
    for pset, idx in sets_to_test {
      // subtracting empty should do nothing
      {
        tmp := difference(pset, &empty_set)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, pset))
      }
      {
        tmp := difference(pset, empty_slice)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, pset))
      }
      {
        tmp := difference(pset, empty_array)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, pset))
      }
      // subtracting disjoint should do nothing
      {
        tmp := difference(pset, disjoint_set_pair[idx])
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, pset))
      }
      {
        arr := asArray(disjoint_set_pair[idx])
        defer delete(arr)
        tmp := difference(pset, disjoint_set_pair[idx])
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, pset))
      }
      // subtracting self should result in empty
      {
        tmp := difference(pset, pset)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &empty_set))
      }
      {
        slice := asArray(pset)
        defer delete(slice)
        tmp := difference(pset, slice[:])
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &empty_set))
      }
    }
    {
      // sized self subtract test
      tmp := difference(&set_A, array_A)
      defer deleteSet(&tmp)
      tc.expect(t, isequal(&tmp, &empty_set))
    }
    {
      // complementary subsets test
      {
        tmp := difference(&set_A, &set_A1)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &set_A1C))
      }
      {
        tmp := difference(&set_A, &set_A1C)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &set_A1))
      }
    }
  }
  {
    // Slice First Tests
    slices_to_test := [?][]int{empty_slice, array_A[:], slice_A1, slice_B}
    disjoint_set_pair := [?]^Set(int){&empty_set, &set_B, &set_B, &set_A}
    for slice, idx in slices_to_test {
      // subtracting empty should do nothing
      {
        tmp := difference(slice, &empty_set)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, slice))
      }
      {
        tmp := difference(slice, empty_slice)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, slice))
      }
      {
        tmp := difference(slice, empty_array)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, slice))
      }
      // subtracting disjoint should do nothing
      {
        tmp := difference(slice, disjoint_set_pair[idx])
        defer deleteSet(&tmp)
        result := isequal(&tmp, slice)
        if !result {
          fmt.printf("slice:%v - %v == %v ; expected:%v\n", slice, disjoint_set_pair[idx], tmp, slice)
        }
        tc.expect(t, result)
      }
      {
        arr := asArray(disjoint_set_pair[idx])
        defer delete(arr)
        tmp := difference(slice, disjoint_set_pair[idx])
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, slice))
      }
      // subtracting self should result in empty
      {
        tmp := difference(slice, slice)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &empty_set))
      }
      {
        tmp := difference(slice, slice[:])
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &empty_set))
      }
    }
    {
      // sized self subtract test
      tmp := difference(&set_A, array_A)
      defer deleteSet(&tmp)
      tc.expect(t, isequal(&tmp, &empty_set))
    }
    {
      // complementary subsets test
      {
        tmp := difference(&set_A, &set_A1)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &set_A1C))
      }
      {
        tmp := difference(&set_A, &set_A1C)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, &set_A1))
      }
    }
  }
  {
    // fixed array first
    {
      // difference empty
      {
        tmp := difference(array_A, &empty_set)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
      {
        tmp := difference(array_A, empty_slice)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
      {
        tmp := difference(array_A, empty_array)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
    }
    {
      // difference self
      {
        tmp := difference(array_A, &set_A)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, empty_array))
      }
      {
        tmp := difference(array_A, slice_A)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, empty_array))
      }
      {
        tmp := difference(array_A, array_A)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, empty_array))
      }
    }
    {
      // difference disjoint
      {
        tmp := difference(array_A, &set_B)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
      {
        tmp := difference(array_A, slice_B)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
      {
        tmp := difference(array_A, array_B)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A))
      }
    }
    {
      // difference subset
      {
        tmp := difference(array_A, &set_A1)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A1C))
      }
      {
        tmp := difference(array_A, slice_A1)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A1C))
      }
      {
        tmp := difference(array_A, array_A1)
        defer deleteSet(&tmp)
        tc.expect(t, isequal(&tmp, array_A1C))
      }
    }
  }
}
