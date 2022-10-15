// Must be run with `-collection:tests=` flag
package test_re

import "core:fmt"
import "core:sort"
import "core:testing"
import "core:unicode"
import "core:unicode/utf8"
import re "game:re"
import set "game:container/set"
import tc "tests:common"

@(test)
test_token_nfa :: proc(t: ^testing.T, verbose: bool = false) {
  using re
  context.allocator = context.temp_allocator
  patterns := [?]string{"abc", "a(b)+", "a(cb+)+", "[ab]+", "(?P<name>H+)*", "()", "(|)"} // "[ab]+(?P<name>[cd]?)*e{2,3}"}
  expected_nfa_nodes := [?]int{5, 6, 7, 3, 5, 4, 5}
  tc.expect(t, len(patterns) == len(expected_nfa_nodes), "Expected patterns length and expected nfa lengths to be the same.")
  for pattern, pattern_idx in patterns {
    nfa, nfa_ok := makeTokenNfaFromPattern(pattern, {})
    tc.expect(t, nfa_ok, "Expected nfa to be ok")
    cmp := len(nfa.tokens) == expected_nfa_nodes[pattern_idx]
    tc.expect(
      t,
      len(nfa.tokens) == expected_nfa_nodes[pattern_idx],
      fmt.tprintf("Expected num nfa nodes to be %v. Got:%v", expected_nfa_nodes[pattern_idx], len(nfa.tokens)),
    )
    cmp &= len(nfa.digraph) == expected_nfa_nodes[pattern_idx]
    tc.expect(
      t,
      len(nfa.digraph) == expected_nfa_nodes[pattern_idx],
      fmt.tprintf("Expected num nfa nodes to be %v. Got:%v", expected_nfa_nodes[pattern_idx], len(nfa.digraph)),
    )
    for k, v in &nfa.digraph {
      if k != nfa.tail_index {
        cmp = cmp && set.size(&v) > 0
        tc.expect(t, set.size(&v) > 0, "Expected non-tail to be non-empty")
      } else {
        cmp = cmp && set.size(&v) == 0
        tc.expect(t, set.size(&v) == 0, "Expected tail to be empty")
      }
    }
    if !cmp && verbose {
      fmt.printf("Pattern: \"%v\"\n", pattern)
      fmt.printf("NFA:\n")
      for tok, idx in nfa.tokens {
        fmt.printf("% 2d: %v\n", idx, tok)
        edges := set.asArray(&nfa.digraph[idx], context.temp_allocator)
        sort.quick_sort(edges[:])
        fmt.printf("   -> %v\n", edges)
      }
      fmt.printf("\n")
    }
  }
}
