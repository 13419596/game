package trie

import "core:fmt"
import "core:intrinsics"
import "core:log"
import "core:runtime"
import "core:strings"
import Q "core:container/queue"


Trie :: struct($K, $V: typeid) {
  // This class is a data structure where data is entered into a prefix tree using iterable keys (e.g. strings)
  // and stores data at that node. Then when querying data, the longest matching prefix is found and the data there
  // is returned.
  root:       _TrieNode(K, V),
  _allocator: runtime.Allocator,
}

@(require_results)
makeTrie :: proc($K, $V: typeid, allocator := context.allocator) -> Trie(K, V) {
  out := Trie(K, V) {
    root       = _makeTrieNode(K{}, V, allocator),
    _allocator = allocator,
  }
  return out
}

deleteTrie :: proc(self: ^$T/Trie($K, $V)) {
  if self == nil {
    return
  }
  _deleteTrieNode(&self.root, self._allocator)
}

/////////////////////////////////////

_getLongestPrefix :: proc(self: ^$T/Trie($K, $V), key: []K) -> ([]K, Maybe(V)) {
  // Finds the longest matching prefix in trie and returns the value there. 
  node := &self.root
  longest_value: Maybe(V) = nil
  longest_idx := 0
  for k, idx in key {
    if k in node.children {
      node = &node.children[k]
    } else {
      break
    }
    if value, ok := node.value.?; ok {
      longest_idx = idx
      longest_value = value
    }
  }
  return key[:longest_idx + 1], longest_value
}

_getLongestPrefix_int_string :: proc(self: ^$T/Trie($K, $V), key: string) -> (string, Maybe(V)) where intrinsics.type_is_integer(K) && size_of(K) >= 4 {
  // Finds the longest matching prefix in trie and returns the value there. 
  node := &self.root
  longest_value: Maybe(V) = nil
  longest_idx := 0
  for k, idx in key {
    kint := K(k)
    if kint in node.children {
      node = &node.children[kint]
    } else {
      break
    }
    if value, ok := node.value.?; ok {
      longest_idx = idx
      longest_value = value
    }
  }
  return key[:longest_idx + 1], longest_value
}

getLongestPrefix :: proc {
  _getLongestPrefix,
  _getLongestPrefix_int_string,
}

///////////////////////////////////////////////////////////////////////////


@(private)
_discard :: proc(self: ^$T/Trie($K, $V), key: []K) -> bool {
  // Removes value specified by key and returns True, returns False if key is not found
  node := &self.root
  longest_idx := 0
  for k, idx in key {
    kint := K(k)
    if kint in node.children {
      node = &node.children[kint]
    } else {
      break
    }
    if value, ok := node.value.?; ok {
      longest_idx = idx
    }
  }
  if longest_idx + 1 != len(key) {
    return false
  }
  if value, ok := node.value.?; ok {
    node.value = {}
    return true
  } else {
    return false
  }
}

@(private)
_discard_int_string :: proc(self: ^$T/Trie($K, $V), key: string) -> bool where intrinsics.type_is_integer(K) && size_of(K) >= 4 {
  node := &self.root
  longest_idx := 0
  for k, idx in key {
    kint := K(k)
    if kint in node.children {
      node = &node.children[kint]
    } else {
      break
    }
    if value, ok := node.value.?; ok {
      longest_idx = idx
    }
  }
  if longest_idx + 1 != len(key) {
    return false
  }
  if value, ok := node.value.?; ok {
    node.value = {}
    return true
  } else {
    return false
  }
}


discardItem :: proc {// Removes value specified by key and returns True, returns False if key is not found
  _discard_int_string,
  _discard,
}

///////////////////////////////////////////////////////////////////////////

_hasKey :: proc(self: ^$T/Trie($K, $V), key: []K) -> bool {
  node := &self.root
  longest_idx := 0
  for k, idx in key {
    kint := K(k)
    if kint in node.children {
      node = &node.children[kint]
    } else {
      break
    }
    if value, ok := node.value.?; ok {
      longest_idx = idx
    }
  }
  out := longest_idx + 1 >= len(key)
  return out
}

_hasKey_int_string :: proc(self: ^$T/Trie($K, $V), key: string) -> bool where intrinsics.type_is_integer(K) && size_of(K) >= 4 {
  node := &self.root
  longest_idx := 0
  for k, idx in key {
    kint := K(k)
    if kint in node.children {
      node = &node.children[kint]
    } else {
      break
    }
    if value, ok := node.value.?; ok {
      longest_idx = idx
    }
  }

  out := longest_idx + 1 >= len(key)
  return out
}

hasKey :: proc {
  _hasKey,
  _hasKey_int_string,
}

///////////////////////////////////////////////////////////////////////////

_setValue :: proc(self: ^$T/Trie($K, $V), key: []K, value: V) {
  node := &self.root
  for k, idx in key {
    if k in node.children {
      node = &node.children[k]
    } else {
      node.children[k] = _makeTrieNode(k, V, self._allocator)
      node = &node.children[k]
    }
  }
  node.value = value
}

_setValue_int_string :: proc(self: ^$T/Trie($K, $V), key: string, value: V) where intrinsics.type_is_integer(K) && size_of(K) >= 4 {
  node := &self.root
  for k, idx in key {
    kint := K(k)
    if kint in node.children {
      node = &node.children[kint]
    } else {
      node.children[kint] = _makeTrieNode(kint, V, self._allocator)
      node = &node.children[kint]
    }
  }
  node.value = value
}

setValue :: proc {
  _setValue_int_string,
  _setValue,
}

///////////////////////////////////////////////////////////////////////////

_getValue :: proc(self: ^$T/Trie($K, $V), key: []K) -> (out: V, ok: bool) {
  node := &self.root
  longest_idx := 0
  for k, idx in key {
    kint := K(k)
    if kint in node.children {
      node = &node.children[kint]
    } else {
      break
    }
    if value, ok := node.value.?; ok {
      longest_idx = idx
    }
  }
  if longest_idx + 1 >= len(key) {
    out = node.value.?
    ok = true
  }
  return
}

_getValue_int_string :: proc(self: ^$T/Trie($K, $V), key: string) -> (out: V, ok: bool) where intrinsics.type_is_integer(K) && size_of(K) >= 4 {
  node := &self.root
  longest_idx := 0
  for k, idx in key {
    kint := K(k)
    if kint in node.children {
      node = &node.children[kint]
    } else {
      break
    }
    if value, ok := node.value.?; ok {
      longest_idx = idx
    }
  }
  if longest_idx + 1 >= len(key) {
    out = node.value.?
    ok = true
  }
  return
}

getValue :: proc {
  _getValue,
  _getValue_int_string,
}

///////////////////////////////////////////////////////////////////////////

@(private = "file")
_StackItem :: struct($K, $V: typeid) {
  // assumes that the stack item will be allocated via temp_allocator,
  // and thus will not need to be de-allocated
  key:          [dynamic]K,
  node:         ^_TrieNode(K, V),
  depth:        int,
  child_index:  int,
  num_children: int,
  mprefix:      Maybe(string),
}

_getNumValues_fromNode :: proc(node: ^$T/_TrieNode($K, $V)) -> int {
  // Returns the number of nodes in the trie. 
  total := 0
  S :: _StackItem(K, V)
  stack := Q.Queue(S) {
    data = make([dynamic]S, context.temp_allocator),
  }
  Q.init(&stack)
  Q.push_back(&stack, S{node = node})
  for stack.len > 0 {
    item := Q.pop_back(&stack)
    if value, ok := item.node.value.?; ok {
      total += 1
    }
    for k, node in &item.node.children {
      Q.push_back(&stack, S{node = &node})
    }
  }
  return total
}

getNumValues :: proc(self: ^$T/Trie($K, $V)) -> int {
  return _getNumValues_fromNode(node = &self.root)
}

///////////////////////////////////////////////////////////////////////////

@(require_results)
pformatTrie :: proc(self: ^$T/Trie($K, $V), allocator := context.allocator) -> string {
  using strings
  out_lines := make([dynamic]string, context.temp_allocator)
  S :: _StackItem(K, V)
  stack := Q.Queue(S) {
    data = make([dynamic]S, context.temp_allocator),
  }
  Q.init(&stack)
  Q.push_back(&stack, S{node = &self.root, mprefix = ""})
  for stack.len > 0 {
    item := Q.pop_back(&stack)
    prefix := item.mprefix.? or_else ""
    if item.depth > 0 {
      line := make([dynamic]string, context.temp_allocator)
      append(&line, prefix)
      if item.child_index + 1 >= item.num_children {
        // last child
        prefix = fmt.tprintf("%v  ", prefix)
        append(&line, "└")
      } else {
        prefix = fmt.tprintf("%v| ", prefix)
        append(&line, "├")
      }
      append(&line, "── ")
      when K == rune {
        append(&line, fmt.tprintf("%q", item.node.key))
      } else {
        append(&line, fmt.tprintf("%v", item.node.key))
      }
      if value, ok := item.node.value.?; ok {
        when V == rune {
          append(&line, fmt.tprintf(": %q", item.node.value))
        } else {
          append(&line, fmt.tprintf(": %v", item.node.value))
        }
      }
      append(&out_lines, join(line[:], "", context.temp_allocator))
    }
    child_idx := 0
    num_children := len(item.node.children)
    for k, node in &item.node.children {
      // reverse indicies because children are pushed onto a stack
      Q.push_back(&stack, S{{}, &node, item.depth + 1, num_children - child_idx - 1, num_children, prefix})
      child_idx += 1
    }
  }
  out := join(out_lines[:], "\n", allocator)
  return out
}

///////////////////////////////////////////////////////////////////////////

@(require_results)
_getAllValues_fromNode :: proc(node: ^$T/_TrieNode($K, $V), allocator := context.allocator) -> []V {
  // Returns all the values stored in the trie
  out := make([dynamic]V, allocator)
  S :: _StackItem(K, V)
  stack := Q.Queue(S) {
    data = make([dynamic]S, context.temp_allocator),
  }
  Q.init(&stack)
  Q.push_back(&stack, S{node = node})
  for stack.len > 0 {
    item := Q.pop_back(&stack)
    if value, ok := item.node.value.?; ok {
      append(&out, value)
    }
    for k, node in &item.node.children {
      Q.push_back(&stack, S{node = &node})
    }
  }
  return out[:]
}

@(require_results)
getAllValues :: proc(self: ^$T/Trie($K, $V), allocator := context.allocator) -> []V {
  return _getAllValues_fromNode(&self.root, allocator)
}

///////////////////////////////////////////////////////////////////////////

@(require_results)
_getAllKeys_fromNode :: proc(node: ^$T/_TrieNode($K, $V), allocator := context.allocator) -> [][]K {
  // returns all keys with values in the trie
  out := make([dynamic][]K, allocator)
  S :: _StackItem(K, V)
  stack := Q.Queue(S) {
    data = make([dynamic]S, context.temp_allocator),
  }
  Q.init(&stack)
  Q.push_back(&stack, S{node = node})
  for stack.len > 0 {
    item := Q.pop_back(&stack)
    if value, ok := item.node.value.?; ok {
      // allocate final key
      out_key := make([dynamic]K, len(item.key), allocator)
      for k, i in item.key {
        out_key[i] = k
      }
      append(&out, out_key[:])
    }
    for last_k, node in &item.node.children {
      next_key := make(T = [dynamic]K, len = len(item.key) + 1, allocator = context.temp_allocator)
      for k, i in item.key {
        next_key[i] = k
      }
      if len(next_key) > 0 {
        next_key[len(next_key) - 1] = last_k
      }
      Q.push_back(&stack, S{node = &node, key = next_key, depth = item.depth + 1})
    }
  }
  return out[:]
}


@(require_results)
getAllKeys :: proc(self: ^$T/Trie($K, $V), allocator := context.allocator) -> [][]K {
  return _getAllKeys_fromNode(&self.root, allocator)
}

///////////////////////////////////////////////////////////////////////////

TrieKeyValue :: struct($K, $V: typeid) {
  key:   []K,
  value: V,
}

deleteTrieKeyValue :: proc(kv: ^$T/TrieKeyValue($K, $V)) {
  if kv == nil {
    return
  }
  delete(kv.key)
}

@(require_results)
_getAllKeyValues_fromNode :: proc(node: ^$T/_TrieNode($K, $V), allocator := context.allocator) -> []TrieKeyValue(K, V) {
  // returns all keys with values in the trie
  out := make([dynamic]TrieKeyValue(K, V), allocator)
  S :: _StackItem(K, V)
  stack := Q.Queue(S) {
    data = make([dynamic]S, context.temp_allocator),
  }
  Q.init(&stack)
  Q.push_back(&stack, S{node = node})
  for stack.len > 0 {
    item := Q.pop_back(&stack)
    if value, ok := item.node.value.?; ok {
      // allocate final key
      out_key := make([dynamic]K, len(item.key), allocator)
      for k, i in item.key {
        out_key[i] = k
      }
      append(&out, TrieKeyValue(K, V){key = out_key[:], value = value})
    }
    for last_k, node in &item.node.children {
      next_key := make(T = [dynamic]K, len = len(item.key) + 1, allocator = context.temp_allocator)
      for k, i in item.key {
        next_key[i] = k
      }
      if len(next_key) > 0 {
        next_key[len(next_key) - 1] = last_k
      }
      Q.push_back(&stack, S{node = &node, key = next_key, depth = item.depth + 1})
    }
  }
  return out[:]
}

@(require_results)
getAllKeyValues :: proc(self: ^$T/Trie($K, $V), allocator := context.allocator) -> []TrieKeyValue(K, V) {
  return _getAllKeyValues_fromNode(&self.root, allocator)
}

///////////////////////////////////////////////////////////////////////////

_getPrefixNode_fromNode_v :: proc(node: ^$T/_TrieNode($K, $V), key: []K) -> ^_TrieNode(K, V) {
  if node == nil {
    return nil
  }
  node := node
  node_idx := 0
  for k, idx in key {
    kint := K(k)
    if kint in node.children {
      node_idx = idx
      node = &node.children[kint]
    } else {
      break
    }
  }
  if node_idx + 1 >= len(key) {
    // found node - regardless of it containing a value
    return node
  } else {
    return nil
  }
}

_getPrefixNode_fromNode_int_string :: proc(node: ^$T/_TrieNode($K, $V), key: string) -> ^_TrieNode(K, V) where intrinsics.type_is_integer(K) &&
  size_of(K) >= 4 {
  if node == nil {
    return nil
  }
  node := node
  node_idx := 0
  for k, idx in key {
    kint := K(k)
    if kint in node.children {
      node_idx = idx
      node = &node.children[kint]
    } else {
      break
    }
  }
  if node_idx + 1 >= len(key) {
    // found node - regardless of it containing a value
    return node
  } else {
    return nil
  }
}

_getPrefixNode_fromNode :: proc {
  _getPrefixNode_fromNode_v,
  _getPrefixNode_fromNode_int_string,
}

_getPrefixNode :: proc(self: ^$T/Trie($K, $V), key: $KEY) -> ^_TrieNode(K, V) {
  return _getPrefixNode_fromNode(&self.root, key)
}


@(require_results)
getAllValuesWithPrefix :: proc(self: ^$T/Trie($K, $V), key: $KEY, allocator := context.allocator) -> []V {
  node := _getPrefixNode(self, key)
  if node == nil {
    return {}
  }
  return _getAllValues_fromNode(node, allocator)
}

@(require_results)
getAllKeysWithPrefix :: proc(self: ^$T/Trie($K, $V), key: $KEY, allocator := context.allocator) -> [][]K {
  node := _getPrefixNode(self, key)
  if node == nil {
    return {}
  }
  return _getAllKeys_fromNode(node, allocator)
}


@(require_results)
getAllKeyValuesWithPrefix :: proc(self: ^$T/Trie($K, $V), key: $KEY, allocator := context.allocator) -> []TrieKeyValue(K, V) {
  node := _getPrefixNode(self, key)
  if node == nil {
    return {}
  }
  return _getAllKeyValues_fromNode(node, allocator)
}
