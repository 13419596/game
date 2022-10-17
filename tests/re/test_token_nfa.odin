// Must be run with `-collection:tests=` flag
package test_re

import "core:fmt"
import "core:sort"
import "core:testing"
import "core:unicode"
import "core:unicode/utf8"
import re "game:re"
import set "game:container/set"
import dg "game:digraph"
import tc "tests:common"

@(private)
checkDigraphIdenticallyEqual :: proc(d1, d2: ^dg.Digraph($T)) -> bool {
  // checks that digraphs are identically equal (same nodes, same edges, same order)
  if dg.getNumNodes(d1) != dg.getNumNodes(d2) {
    return false
  }
  for node, out_nodes in &d1.data {
    if node not_in d2.data {
      return false
    }
    if !set.isequal(&out_nodes, &d2.data[node]) {
      return false
    }
  }
  return true
}


@(test)
test_token_nfa :: proc(t: ^testing.T, verbose: bool = false) {
  using re
  patterns := [?]string{
    "abc",
    "a{0}",
    "a{1}",
    "a{2}",
    "a(b)+",
    "a(cb+)+",
    "[ab]+",
    "a?",
    "a*",
    "a+",
    "a{3,}",
    "()",
    "(|)",
    "(a|)",
    "(|a)",
    "a{1,2}",
    "a{0,2}",
    "a{,2}",
    "(?P<name>H+)*",
    "((a))",
    "(a)(b)",
  }
  expected_nfa_edges := [?][][2]int {
    {{0, 2}, {2, 3}, {3, 4}, {4, 1}}, // "abc"
    {{0, 2}, {0, 1}, {2, 1}}, // "a{0}" 
    {{0, 2}, {2, 1}}, // "a{1}"
    {{0, 2}, {2, 3}, {3, 1}}, // "a{2}"
    {{0, 2}, {2, 3}, {3, 4}, {4, 5}, {5, 1}, {5, 3}}, // "a(b)+"
    {{0, 2}, {2, 3}, {3, 4}, {4, 5}, {5, 6}, {5, 5}, {6, 1}, {6, 3}}, // "a(cb+)+"
    {{0, 2}, {2, 1}, {2, 2}}, // "[ab]+"
    {{0, 2}, {0, 1}, {2, 1}}, // a?
    {{0, 2}, {0, 1}, {2, 2}, {2, 1}}, // a*
    {{0, 2}, {2, 2}, {2, 1}}, // a*
    {{0, 2}, {2, 3}, {3, 4}, {4, 4}, {4, 1}}, // a{3,}
    {{0, 2}, {2, 3}, {3, 1}}, // ()
    {{0, 2}, {2, 3}, {3, 1}}, // (|)
    {{0, 2}, {2, 3}, {2, 4}, {3, 4}, {4, 1}}, // (a|)
    {{0, 2}, {2, 3}, {2, 4}, {3, 4}, {4, 1}}, // (|a)
    {{0, 2}, {2, 3}, {2, 1}, {3, 1}}, // a{1,2}
    {{0, 2}, {0, 1}, {2, 1}, {2, 3}, {3, 1}}, // a{0,2}
    {{0, 2}, {0, 1}, {2, 1}, {2, 3}, {3, 1}}, // a{,2}
    {{0, 2}, {2, 3}, {3, 3}, {3, 4}, {4, 1}, {4, 2}, {0, 1}}, // "(?P<name>H+)*"
    {{0, 2}, {2, 3}, {3, 4}, {4, 5}, {5, 6}, {6, 1}}, // ((a))
    {{0, 2}, {2, 3}, {3, 4}, {4, 5}, {5, 6}, {6, 7}, {7, 1}}, // (a)(b)
  }
  tc.expect(t, len(patterns) == len(expected_nfa_edges), "Expected patterns length and expected nfas length to be the same.")
  for pattern, pattern_idx in patterns {
    if pattern_idx + 1 > min(len(patterns), len(expected_nfa_edges)) {
      break
    }
    expected_dg := dg.makeDigraphFromEdges(expected_nfa_edges[pattern_idx])
    defer dg.deleteDigraph(&expected_dg)
    nfa, nfa_ok := makeTokenNfaFromPattern(pattern, {})
    defer deleteTokenNfa(&nfa)
    tc.expect(t, nfa_ok, "Expected nfa to be ok")
    cmp := checkDigraphIdenticallyEqual(&nfa.digraph, &expected_dg)
    tc.expect(t, cmp, fmt.tprintf("NFA not as expected. Expected:%v. Got:%v", expected_dg, &nfa.digraph))
    for node, out_nodes in &nfa.digraph.data {
      if node != nfa.tail_index {
        size_check := set.size(&out_nodes) > 0
        tc.expect(t, size_check, "Expected non-tail to be non-empty")
        cmp = cmp && size_check
      } else {
        size_check := set.size(&out_nodes) == 0
        tc.expect(t, set.size(&out_nodes) == 0, "Expected tail to be empty")
        cmp = cmp && size_check
      }
    }
    if !cmp && verbose {
      fmt.printf("Pattern: \"%v\"\n", pattern)
      fmt.printf("NFA:\n")
      for tok, idx in nfa.tokens {
        fmt.printf("% 2d: %v\n", idx, tok)
        edges := set.asArray(&nfa.digraph.data[idx], context.temp_allocator)
        sort.quick_sort(edges[:])
        fmt.printf("   -> %v\n", edges)
      }
      fmt.printf("\n")
    }
  }
}
