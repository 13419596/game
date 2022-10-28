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
test_set_basic :: proc(t: ^testing.T) {
  tests := [?]proc(_: ^testing.T){
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
  set := makeSet(int)
  defer deleteSet(&set)
  tc.expect(t, len(set.set) == 0, "intial zero length")
  set.set[3] = 3
  tc.expect(t, len(set.set) != 0)
  reset(&set)
  tc.expect(t, len(set.set) == 0, "reset should set length back to zero.")
}

@(test, private = "file")
test_copy :: proc(t: ^testing.T) {
  using container_set
  using rand
  {
    set1 := makeSet(int)
    defer deleteSet(&set1)
    set2 := makeSet(int)
    defer deleteSet(&set2)
    tc.expect(t, areMapsKeysEqual(&set1.set, &set2.set), "initial set innards should be equal")
  }
  {
    set1 := makeSet(int)
    defer deleteSet(&set1)
    set2 := copy(&set1)
    defer deleteSet(&set2)
    tc.expect(t, areMapsKeysEqual(&set1.set, &set2.set), "initial copied set innards should be equal")
  }
  for monte in 0 ..< num_monte {
    set1 := randomSetInt()
    defer deleteSet(&set1)
    set2 := copy(&set1)
    defer deleteSet(&set2)
    tc.expect(t, areMapsKeysEqual(&set1.set, &set2.set))
  }
}

@(test, private = "file")
test_asArray :: proc(t: ^testing.T) {
  using container_set
  using rand
  {
    set := makeSet(int)
    defer deleteSet(&set)
    arr := asArray(&set)
    defer delete(arr)
    tc.expect(t, len(arr) == 0, "initial set should result in empty array")
  }
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

@(test, private = "file")
test_fromArray :: proc(t: ^testing.T) {
  using container_set
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
  //from array
  {
    expected := [?]int{-1, 0, 1, 2, 99}
    set := fromArray([?]int{-1, 0, 1, 2, 99})
    defer deleteSet(&set)
    arr := asArray(&set)
    defer delete(arr)
    tc.expect(t, areSortedListsEqual(arr[:], expected[:]))
  }
}


@(test, private = "file")
test_size :: proc(t: ^testing.T) {
  using container_set
  using rand
  {
    set := makeSet(int)
    defer deleteSet(&set)
    tc.expect(t, size(&set) == 0, "initial set should result in empty array")
  }
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

@(test, private = "file")
test_add :: proc(t: ^testing.T) {
  using container_set
  using rand
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

@(test, private = "file")
test_discard :: proc(t: ^testing.T) {
  using container_set
  using rand
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

@(test, private = "file")
test_pop :: proc(t: ^testing.T) {
  using container_set
  using rand
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

@(test, private = "file")
test_pop_safe :: proc(t: ^testing.T) {
  using container_set
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


@(test, private = "file")
test_contains :: proc(t: ^testing.T) {
  using container_set
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
