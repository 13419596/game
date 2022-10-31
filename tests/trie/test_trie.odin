// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_trie

import "core:fmt"
import "core:log"
import "core:runtime"
import "core:testing"
import "game:trie"
import set "game:container/set"
import tc "tests:common"

@(test)
test_Trie :: proc(t: ^testing.T) {
  test_makeTrie(t)
  test_setValue(t)
  test_discardItem(t)
  test_hasKey(t)
  test_getLongestPrefix(t)
  test_getAllValues(t)
  test_getAllWithPrefix(t)
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
test_setValue :: proc(t: ^testing.T) {
  using trie
  {
    tr := makeTrie(int, int)
    defer deleteTrie(&tr)
    tc.expect(t, 0 == getNumValues(&tr))
    setValue(&tr, "AB", 3)
    setValue(&tr, "AC", 4)
    tc.expect(t, len(tr.root.children) == 1)
    tc.expect(t, 2 == getNumValues(&tr))
  }
  {
    tr := makeTrie(uint, int)
    defer deleteTrie(&tr)
    tc.expect(t, 0 == getNumValues(&tr))
    setValue(&tr, "AB", 3)
    setValue(&tr, "AC", 4)
    tc.expect(t, len(tr.root.children) == 1)
    tc.expect(t, 2 == getNumValues(&tr))
  }
  {
    tr := makeTrie(int, int)
    defer deleteTrie(&tr)
    tc.expect(t, 0 == getNumValues(&tr))
    arr := [?]int{3, 8}
    setValue(&tr, arr[:], 3)
    arr[len(arr) - 1] = 6555
    setValue(&tr, arr[:], 4)
    tc.expect(t, len(tr.root.children) == 1)
    tc.expect(t, 2 == getNumValues(&tr))
    setValue(&tr, arr[:], 400000)
    tc.expect(t, len(tr.root.children) == 1)
  }
}


@(test)
test_discardItem :: proc(t: ^testing.T) {
  using trie
  tr := makeTrie(int, int)
  defer deleteTrie(&tr)
  setValue(&tr, "abcdef", 0)
  setValue(&tr, "abcde", 1)
  setValue(&tr, "abcd", 2)
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
test_hasKey :: proc(t: ^testing.T) {
  using trie
  tr := makeTrie(int, int)
  defer deleteTrie(&tr)
  arr_abcdef := [?]int{97, 98, 99, 100, 101, 102}
  tc.expect(t, !hasKey(&tr, "abcdef"))
  tc.expect(t, !hasKey(&tr, arr_abcdef[:]))
  setValue(&tr, "abcdef", 0)
  tc.expect(t, hasKey(&tr, "abcdef"))
  tc.expect(t, hasKey(&tr, arr_abcdef[:]))
  tc.expect(t, !hasKey(&tr, "abcde"))
  tc.expect(t, !hasKey(&tr, arr_abcdef[:len(arr_abcdef) - 1]))
  setValue(&tr, "abcde", 1)
  tc.expect(t, hasKey(&tr, "abcde"))
  tc.expect(t, hasKey(&tr, arr_abcdef[:len(arr_abcdef) - 1]))
  tc.expect(t, !hasKey(&tr, "abcd"))
  tc.expect(t, !hasKey(&tr, arr_abcdef[:len(arr_abcdef) - 2]))
  setValue(&tr, "abcd", 2)
  tc.expect(t, hasKey(&tr, "abcd"))
  tc.expect(t, hasKey(&tr, arr_abcdef[:len(arr_abcdef) - 2]))
  tc.expect(t, discardItem(&tr, "abcd"))
  tc.expect(t, 2 == getNumValues(&tr))
  tc.expect(t, !hasKey(&tr, "abcd"))
  tc.expect(t, !hasKey(&tr, arr_abcdef[:len(arr_abcdef) - 2]))
}

@(test)
test_getLongestPrefix :: proc(t: ^testing.T) {
  using trie
  tr := makeTrie(int, int)
  defer deleteTrie(&tr)
  setValue(&tr, "abcdef", 0)
  setValue(&tr, "abcdefffffffffffffff", 10)
  setValue(&tr, "abcde", 1)
  setValue(&tr, "abcd", 2)
  setValue(&tr, "abcU", 2)
  {
    k, v := getLongestPrefix(&tr, "abcdeffff")
    expected := "abcdef"
    tc.expect(t, v == 0)
    tc.expect(t, k == expected, fmt.tprintf("Expected:%q. Got:%q", expected, k))
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
    tc.expect(t, all_eq, fmt.tprintf("Expected:%q. Got:%q", expected_k, k))
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
  setValue(&tr, "abcdef", 0)
  setValue(&tr, "abcde", 1)
  setValue(&tr, "abcd", 2)
  setValue(&tr, "AbcU", 3)
  setValue(&tr, "AbcUUUUU", 4)
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

@(test)
test_getAllWithPrefix :: proc(t: ^testing.T) {
  using trie
  tr := makeTrie(int, int)
  defer deleteTrie(&tr)
  setValue(&tr, "--test", 0)
  setValue(&tr, "--test1", 1)
  setValue(&tr, "--test2", 2)
  setValue(&tr, "--option", 3)
  {
    prefix := "--test"
    {
      expected_values := set.fromArray([]int{0, 1, 2})
      defer set.deleteSet(&expected_values)
      expected_keys := set.fromArray([]string{"--test", "--test1", "--test2"})
      defer set.deleteSet(&expected_keys)
      values := set.fromArray(getAllValuesWithPrefix(&tr, prefix, context.temp_allocator))
      defer set.deleteSet(&values)
      keys := getAllKeysWithPrefix(&tr, prefix)
      defer {
        for k in keys {
          delete(k)
        }
        delete(keys)
      }
      kvs := getAllKeyValuesWithPrefix(&tr, prefix)
      defer {
        for kv in &kvs {
          deleteTrieKeyValue(&kv)
        }
        delete(kvs)
      }
      tc.expect(t, set.isequal(&expected_values, &values), fmt.tprintf("Expected:%v. Got:%v", expected_values, values))
      tc.expect(t, len(keys) == set.size(&expected_keys), fmt.tprintf("Expected:%v. Got:%v", set.size(&expected_keys), len(keys)))
      tc.expect(t, len(kvs) == set.size(&expected_keys), fmt.tprintf("Expected:%v. Got:%v", set.size(&expected_keys), len(kvs)))
    }
  }
  {
    prefix := []int{45, 45, 116, 101, 115, 116}
    {
      expected_values := set.fromArray([]int{0, 1, 2})
      defer set.deleteSet(&expected_values)
      expected_keys := [][]int{{45, 45, 116, 101, 115, 116}, {45, 45, 116, 101, 115, 116, 49}, {45, 45, 116, 101, 115, 116, 50}}
      values := set.fromArray(getAllValuesWithPrefix(&tr, prefix, context.temp_allocator))
      defer set.deleteSet(&values)
      keys := getAllKeysWithPrefix(&tr, prefix)
      defer {
        for k in keys {
          delete(k)
        }
        delete(keys)
      }
      kvs := getAllKeyValuesWithPrefix(&tr, prefix)
      defer {
        for kv in &kvs {
          deleteTrieKeyValue(&kv)
        }
        delete(kvs)
      }
      tc.expect(t, set.isequal(&expected_values, &values), fmt.tprintf("Expected:%v. Got:%v", expected_values, values))
      tc.expect(t, len(keys) == len(&expected_keys), fmt.tprintf("Expected:%v. Got:%v", len(&expected_keys), len(keys)))
      tc.expect(t, len(kvs) == len(&expected_keys), fmt.tprintf("Expected:%v. Got:%v", len(&expected_keys), len(kvs)))
    }
  }
  {
    prefix := "UUUUUUU"
    {
      expected_values := []int{}
      expected_keys := []string{}
      expected_kvs := []TrieKeyValue(int, int){}
      values := getAllValuesWithPrefix(&tr, prefix)
      defer delete(values)
      keys := getAllKeysWithPrefix(&tr, prefix)
      defer {
        for k in keys {
          delete(k)
        }
        delete(keys)
      }
      kvs := getAllKeyValuesWithPrefix(&tr, prefix)
      defer {
        for kv in &kvs {
          deleteTrieKeyValue(&kv)
        }
        delete(kvs)
      }
      tc.expect(t, len(values) == len(expected_values), fmt.tprintf("Expected:%v. Got:%v", len(expected_values), len(values)))
      tc.expect(t, len(keys) == len(expected_keys), fmt.tprintf("Expected:%v. Got:%v", len(expected_keys), len(keys)))
      tc.expect(t, len(kvs) == len(expected_kvs), fmt.tprintf("Expected:%v. Got:%v", len(expected_kvs), len(kvs)))
    }
  }
}
