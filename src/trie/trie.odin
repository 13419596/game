package trie

import "core:intrinsics"
import "core:log"
import "core:runtime"
import Q "core:container/queue"


Trie :: struct($K, $V: typeid) {
  // This class is a data structure where data is entered into a prefix tree using iterable keys (e.g. strings)
  // and stores data at that node. Then when querying data, the longest matching prefix is found and the data there
  // is returned.
  root:      _TrieNode(K, V),
  allocator: runtime.Allocator,
}

@(require_results)
makeTrie :: proc($K, $V: typeid, allocator := context.allocator) -> Trie(K, V) {
  out := Trie(K, V) {
    root      = _makeTrieNode(K{}, V, allocator),
    allocator = allocator,
  }
  return out
}

deleteTrie :: proc(self: ^$T/Trie($K, $V)) {
  if self == nil {
    return
  }
  _deleteTrieNode(&self.root)
}

_getLongestPrefix :: proc(self: ^$T/Trie($K, $V), key: []K) -> ([]K, Maybe(V)) {
  // Finds the longest matching prefix in trie and returns the value there. 
  node := &self.root
  longest_value: Maybe(V) = nil
  longest_idx := 0
  for k, idx in key {
    if value, ok := node.value.?; ok {
      longest_idx = idx
      longest_value = value
    }
    if k in node.children {
      node = &node.children[k]
    } else {
      break
    }
  }
  return key[:longest_idx], longest_value
}

_getLongestPrefix_int_string :: proc(self: ^$T/Trie($K, $V), key: string) -> (string, Maybe(V)) where intrinsics.type_is_integer(K) && size_of(K) >= 4 {
  // Finds the longest matching prefix in trie and returns the value there. 
  node := &self.root
  longest_value: Maybe(V) = nil
  longest_idx := 0
  for k, idx in key {
    kint := K(k)
    if value, ok := node.value.(V); ok {
      longest_idx = idx
      longest_value = value
    }
    if kint in node.children {
      node = &node.children[kint]
    } else {
      break
    }
  }
  return key[:longest_idx], longest_value
}

getLongestPrefix :: proc {
  _getLongestPrefix,
  _getLongestPrefix_int_string,
}

getNumValues :: proc(self: ^$T/Trie($K, $V)) -> int {
  // Returns the number of nodes in the trie. 
  return _getTotalValues(&self.root)
}

@(private)
_discard :: proc(self: ^$T/Trie($K, $V), key: []K) -> bool {
  // Removes value specified by key, does nothing if not found. 
  node := &self.root
  key_idx := 0
  for k, idx in key {
    if k in node.children {
      key_idx = idx + 1
      node = &node.children[k]
    } else {
      break
    }
  }
  if key_idx != len(key) {
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
  key_idx := 0
  for k, idx in key {
    kint := K(k)
    if kint in node.children {
      key_idx = idx + 1
      node = &node.children[kint]
    } else {
      break
    }
  }
  if key_idx != len(key) {
    return false
  }
  if value, ok := node.value.?; ok {
    node.value = {}
    return true
  } else {
    return false
  }
}


discard :: proc {
  _discard_int_string,
  _discard,
}

_setItem :: proc(self: ^$T/Trie($K, $V), key: []K, value: V) {
  node := &self.root
  for k, idx in key {
    if k in node.children {
      node = &node.children[k]
    } else {
      node.children[k] = _makeTrieNode(k, V, self.allocator)
      node = &node.children[k]
    }
  }
  node.value = value
}

_setItem_int_string :: proc(self: ^$T/Trie($K, $V), key: string, value: V) where intrinsics.type_is_integer(K) && size_of(K) >= 4 {
  node := &self.root
  for k, idx in key {
    kint := K(k)
    if kint in node.children {
      node = &node.children[kint]
    } else {
      node.children[kint] = _makeTrieNode(kint, V, self.allocator)
      node = &node.children[kint]
    }
  }
  node.value = value
}

setItem :: proc {
  _setItem_int_string,
  _setItem,
}


@(private = "file")
_StackItem :: struct($K, $V: typeid) {
  key:   [dynamic]K,
  node:  ^_TrieNode(K, V),
  depth: int,
}

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

/*
getAllKeyValues :: proc(self: ^$T/Trie($K, $V), allocator := context.allocator) -> []TrieKeyValue(K,V) {
  out := make([dynamic]TrieKeyValue(K,V), allocator)
  stack := Q.Queue(_StackItem(K, V)) {
    data = make([dynamic]_StackItem(K, V), context.temp_allocator),
  }
  Q.init(q = &stack, allocator=context.temp_allocator)
  Q.push_back(&stack, _StackItem(K, V){node = &self.root})
  for stack.len > 0 {
    item := Q.pop_back(&stack)
    if value, ok := item.node.value.?; ok {
      k := make([dynamic]K)
      k = item.key
      append(&out, TrieKeyValue(K,V){})
      append(&out_k, k)
      append(&out_v, value)
    }
    for next_k, node in &item.node.children {
      next_item := _StackItem(K, V){
        node = &node,
        depth=        item.depth+1,
      }
      if item.depth>0 {
        next_item.key  =make([dynamic]K,len(item.key)+1, context.temp_allocator)
        for k,i in item.key {
          next_item.key[i] = k
        }
        next_item.key[len(next_item.key)-1] = next_k
      }
      Q.push_back(&stack, next_item)
    }
  }
  return out_k,out_v
}

*/
