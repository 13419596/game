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

areMapsKeysEqual :: proc(m1: ^$M1/map[$K]$V, m2: ^$M2/map[K]V) -> bool {
  if len(m1) != len(m2) {
    return false
  }
  for k, _ in m1 {
    if !(k in m2) {
      return false
    }
  }
  for k, _ in m2 {
    if !(k in m1) {
      return false
    }
  }
  return true
}

randomSetInt :: proc(N: Maybe(int) = nil, scale: f64 = 10.) -> container_set.Set(int) {
  using rand
  N := N.(int) or_else int(abs(exp_float64() * scale))
  out := container_set.makeSet(int)
  for n in 0 ..< N {
    out.set[n] = {}
  }
  return out
}

areSortedListsEqual :: proc(arr: $A1/[]$T, expected: $A2/[]T) -> bool {
  expected := expected
  if len(arr) != len(expected) {
    return false
  }
  cmp :: proc(lhs, rhs: $T) -> int {
    return int(lhs - rhs)
  }
  sort.quick_sort(arr)
  sort.quick_sort(expected[:])
  for idx in 0 ..< len(arr) {
    if arr[idx] != expected[idx] {
      return false
    }
  }
  return true
}
