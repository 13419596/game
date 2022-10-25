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
