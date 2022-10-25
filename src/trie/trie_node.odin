package trie

import "core:fmt"
import "core:log"

_TrieNode :: struct($K, $V: typeid) where K != rune {
  // Private module class for use in the Trie object 
  // For some odd reason rune keyed maps don't work well, so they are disabled
  key:      K,
  value:    Maybe(V),
  children: map[K]_TrieNode(K, V),
}

_makeTrieNode :: proc(key: $K, $V: typeid, allocator := context.allocator) -> _TrieNode(K, V) {
  out := _TrieNode(K, V) {
    key = key,
    value = {},
    children = make(map[K]_TrieNode(K, V), 0, allocator),
  }
  return out
}

_deleteTrieNode :: proc(self: ^$T/_TrieNode($K, $V)) {
  if self == nil {
    return
  }
  self.value = {}
  for k, v in &self.children {
    _deleteTrieNode(&v)
  }
  delete(self.children)
  self.children = {}
}

_getTotalValues :: proc(self: ^$T/_TrieNode($K, $V), depth: int = 0) -> int {
  total := 0
  if self == nil {
    return total
  }
  if _, ok := self.value.(V); ok {
    total += 1
  }
  if len(self.children) <= 0 {
    return total
  }
  for k, v in &self.children {
    total += _getTotalValues(&v, depth + 1)
  }
  return total
}

_recursePrintNode :: proc(self: ^$T/_TrieNode($K, $V), depth: int = 0) {
  if self == nil {
    return
  }
  for i in 0 ..< depth {
    fmt.printf(" ")
  }
  fmt.printf("'%v' ", self.key)
  if value, ok := self.value.?; ok {
    fmt.printf(": %v", value)
  }
  fmt.printf("\n")
  for k in self.children {
    _recursePrintNode(&self.children[k], depth + 1)
  }
}
