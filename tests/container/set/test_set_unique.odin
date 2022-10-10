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
test_set_unique_util :: proc(t: ^testing.T) {
  tests := [?]proc(_: ^testing.T){test_getUnique}
  for test in tests {
    test(t)
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
