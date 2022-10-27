// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_trie

import "core:fmt"
import "core:log"
import "core:runtime"
import "core:testing"
import "game:trie"
import tc "tests:common"

@(test)
test_Trie :: proc(t: ^testing.T) {
  test_makeTrie(t)
  test_setItem(t)
  test_discardItem(t)
  test_containsKey(t)
  test_getLongestPrefix(t)
  test_getAllValues(t)
}

@(test)
test_makeTrie :: proc(t: ^testing.T) {
  using trie
  {
    tr := makeTrie(int, int, context.temp_allocator)
    tc.expect(t, &tr != nil)
  }
  {
    tr := makeTrie(int, int)
    tc.expect(t, &tr != nil)
    tc.expect(t, 0 == getNumValues(&tr))
    deleteTrie(&tr)
  }
}

@(test)
test_setItem :: proc(t: ^testing.T) {
  using trie
  {
    tr := makeTrie(int, int)
    defer deleteTrie(&tr)
    tc.expect(t, 0 == getNumValues(&tr))
    setItem(&tr, "AB", 3)
    setItem(&tr, "AC", 4)
    tc.expect(t, len(tr.root.children) == 1)
    tc.expect(t, 2 == getNumValues(&tr))
  }
  {
    tr := makeTrie(uint, int)
    defer deleteTrie(&tr)
    tc.expect(t, 0 == getNumValues(&tr))
    setItem(&tr, "AB", 3)
    setItem(&tr, "AC", 4)
    tc.expect(t, len(tr.root.children) == 1)
    tc.expect(t, 2 == getNumValues(&tr))
  }
  {
    tr := makeTrie(int, int)
    defer deleteTrie(&tr)
    tc.expect(t, 0 == getNumValues(&tr))
    arr := [?]int{3, 8}
    setItem(&tr, arr[:], 3)
    arr[len(arr) - 1] = 6555
    setItem(&tr, arr[:], 4)
    tc.expect(t, len(tr.root.children) == 1)
    tc.expect(t, 2 == getNumValues(&tr))
    setItem(&tr, arr[:], 400000)
    tc.expect(t, len(tr.root.children) == 1)
  }
}


@(test)
test_discardItem :: proc(t: ^testing.T) {
  using trie
  tr := makeTrie(int, int)
  defer deleteTrie(&tr)
  setItem(&tr, "abcdef", 0)
  setItem(&tr, "abcde", 1)
  setItem(&tr, "abcd", 2)
  tc.expect(t, 3 == getNumValues(&tr))
  tc.expect(t, discardItem(&tr, "abcd"))
  tc.expect(t, 2 == getNumValues(&tr))
  tc.expect(t, !discardItem(&tr, "abcd"))
  arr := [?]int{97, 98, 99, 100, 101}
  tc.expect(t, discardItem(&tr, arr[:]))
  tc.expect(t, 1 == getNumValues(&tr))
  tc.expect(t, !discardItem(&tr, arr[:]))
}


@(test)
test_containsKey :: proc(t: ^testing.T) {
  using trie
  tr := makeTrie(int, int)
  defer deleteTrie(&tr)
  arr_abcdef := [?]int{97, 98, 99, 100, 101, 102}
  tc.expect(t, !containsKey(&tr, "abcdef"))
  tc.expect(t, !containsKey(&tr, arr_abcdef[:]))
  setItem(&tr, "abcdef", 0)
  tc.expect(t, containsKey(&tr, "abcdef"))
  tc.expect(t, containsKey(&tr, arr_abcdef[:]))
  tc.expect(t, !containsKey(&tr, "abcde"))
  tc.expect(t, !containsKey(&tr, arr_abcdef[:len(arr_abcdef) - 1]))
  setItem(&tr, "abcde", 1)
  tc.expect(t, containsKey(&tr, "abcde"))
  tc.expect(t, containsKey(&tr, arr_abcdef[:len(arr_abcdef) - 1]))
  tc.expect(t, !containsKey(&tr, "abcd"))
  tc.expect(t, !containsKey(&tr, arr_abcdef[:len(arr_abcdef) - 2]))
  setItem(&tr, "abcd", 2)
  tc.expect(t, containsKey(&tr, "abcd"))
  tc.expect(t, containsKey(&tr, arr_abcdef[:len(arr_abcdef) - 2]))
  tc.expect(t, discardItem(&tr, "abcd"))
  tc.expect(t, 2 == getNumValues(&tr))
  tc.expect(t, !containsKey(&tr, "abcd"))
  tc.expect(t, !containsKey(&tr, arr_abcdef[:len(arr_abcdef) - 2]))
}

@(test)
test_getLongestPrefix :: proc(t: ^testing.T) {
  using trie
  tr := makeTrie(int, int)
  defer deleteTrie(&tr)
  setItem(&tr, "abcdef", 0)
  setItem(&tr, "abcdefffffffffffffff", 10)
  setItem(&tr, "abcde", 1)
  setItem(&tr, "abcd", 2)
  setItem(&tr, "abcU", 2)
  {
    k, v := getLongestPrefix(&tr, "abcdeffff")
    expected := "abcdef"
    tc.expect(t, v == 0)
    tc.expect(t, k == expected, fmt.tprintf("Expected:\"%v\". Got:\"%v\"", expected, k))
  }
  {
    arr := []int{97, 98, 99, 100, 101, 102, 102, 102, 102}
    k, v := getLongestPrefix(&tr, arr[:])
    expected_v := 0
    expected_k := []int{97, 98, 99, 100, 101, 102}
    tc.expect(t, v == expected_v, fmt.tprintf("Expected:%v  Got:%v", expected_v, v))
    all_eq := len(k) == len(expected_k)
    for idx in 0 ..< min(len(k), len(expected_k)) {
      all_eq &= (expected_k[idx] == k[idx])
    }
    tc.expect(t, all_eq, fmt.tprintf("Expected:\"%v\". Got:\"%v\"", expected_k, k))
  }
  {
    k, v := getLongestPrefix(&tr, "abcde*******")
    tc.expect(t, v == 1)
    tc.expect(t, k == "abcde")
  }
}

@(test)
test_getAllValues :: proc(t: ^testing.T) {
  using trie
  tr := makeTrie(int, int)
  defer deleteTrie(&tr)
  setItem(&tr, "abcdef", 0)
  setItem(&tr, "abcde", 1)
  setItem(&tr, "abcd", 2)
  setItem(&tr, "AbcU", 3)
  setItem(&tr, "AbcUUUUU", 4)
  {
    s := pformatTrie(&tr)
    defer delete(s)
    log.debugf("Trie:\n%v", s)
    tc.expect(t, len(s) > 3)
  }
  {
    values := getAllValues(&tr)
    defer delete(values)
    tc.expect(t, len(values) == 5)
  }
  {
    keys := getAllKeys(&tr)
    defer {
      for k in &keys {
        delete(k)
      }
      delete(keys)
    }
    log.debugf("KEYS:\n%v", keys)
    tc.expect(t, len(keys) == 5)
  }
  {
    kvs := getAllKeyValues(&tr)
    defer {
      for kv in &kvs {
        deleteTrieKeyValue(&kv)
      }
      delete(kvs)
    }
    log.debugf("KEY-VALUES:\n%v", kvs)
    tc.expect(t, len(kvs) == 5)
  }
}
