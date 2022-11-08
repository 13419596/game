// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_trie

import "core:fmt"
import "core:log"
import "core:runtime"
import "core:testing"
import "core:mem"
import "game:trie"
import tc "tests:common"

@(test)
test_TrieNode :: proc(t: ^testing.T) {
  test_makeTrieNode(t)
}

@(test)
test_makeTrieNode :: proc(t: ^testing.T) {
  using trie
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    tracking_allocator := mem.Tracking_Allocator{}
    mem.tracking_allocator_init(&tracking_allocator, alloc)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    {
      node := _makeTrieNode(int{}, int)
      tc.expect(t, &node != nil)
    }
    tc.expect(t, len(tracking_allocator.allocation_map) == 0)
    {
      node := _makeTrieNode(int{}, int)
      tc.expect(t, &node != nil)
      tc.expect(t, len(node.children) == 0)
      _deleteTrieNode(&node)
      tc.expect(t, node.value == nil)
    }
    tc.expect(t, len(tracking_allocator.allocation_map) == 0)
  }
}
