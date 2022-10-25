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
test_TrieNode :: proc(t: ^testing.T) {
  test_makeTrieNode(t)
  test_getTotalValues(t)
}

@(test)
test_makeTrieNode :: proc(t: ^testing.T) {
  using trie
  {
    node := _makeTrieNode(int{}, int, context.temp_allocator)
    tc.expect(t, &node != nil)
  }
  {
    node := _makeTrieNode(int{}, int)
    tc.expect(t, &node != nil)
    tc.expect(t, len(node.children) == 0)
    _deleteTrieNode(&node)
    tc.expect(t, node.value == nil)
  }
}

@(test)
test_getTotalValues :: proc(t: ^testing.T) {
  using trie
  {
    node := _makeTrieNode(0, int)
    defer _deleteTrieNode(&node)
    tc.expect(t, 0 == _getTotalValues(&node))
  }
  {
    node := _makeTrieNode(0, int)
    defer _deleteTrieNode(&node)
    tc.expect(t, 0 == _getTotalValues(&node))
    node.value = 3
    tc.expect(t, 1 == _getTotalValues(&node))
  }
  {
    node := _makeTrieNode(0, int)
    defer _deleteTrieNode(&node)
    tc.expect(t, 0 == _getTotalValues(&node))
    tc.expect(t, len(node.children) == 0)
    node.value = 3
    node.children[4] = _makeTrieNode(3, int)
    tc.expect(t, 1 == _getTotalValues(&node))
    tc.expect(t, len(node.children) == 1)
    child_node := &node.children[4]
    child_node.value = 99
    tc.expect(t, 2 == _getTotalValues(&node))
    node.value = nil
    tc.expect(t, 1 == _getTotalValues(&node))
    child_node.value = nil
    tc.expect(t, 0 == _getTotalValues(&node))
  }
}
