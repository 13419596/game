// Must be run with `-collection:tests=` flag
package test_re

import "core:fmt"
import "core:sort"
import "core:testing"
import "core:unicode"
import "core:unicode/utf8"
import re "game:re"
import container_set "game:container/set"
import tc "tests:common"

@(private)
areTokenArraysEqual :: proc(lhs, rhs: []re.Token) -> bool {
  using re
  if len(lhs) != len(rhs) {
    return false
  }
  for _, idx in lhs {
    lv := &lhs[idx]
    rv := &rhs[idx]
    if !isequal_Token(lv, rv) {
      return false
    }
  }
  return true
}

@(test)
test_infix_to_postfix :: proc(t: ^testing.T, verbose: bool = false) {
  using re
  context.allocator = context.temp_allocator
  patterns := [?]string{"abc", "a(b?)+", "[ab]+(?P<name>[cd]?)*e{2,3}"}
  expected_num_infix_tokens := [?]int{3, 6, 9}
  all_expected_postfix_tokens := [?][]Token{
    {LiteralToken{'a'}, LiteralToken{'b'}, SpecialToken{.CONCATENATION}, LiteralToken{'c'}, SpecialToken{.CONCATENATION}},
    {
      LiteralToken{'a'},
      GroupBeginToken{index = 0},
      LiteralToken{'b'},
      QuantityToken{0, 1},
      GroupEndToken{index = 0},
      QuantityToken{1, nil},
      SpecialToken{.CONCATENATION},
    },
    {
      makeSetToken("ab"),
      QuantityToken{1, nil},
      GroupBeginToken{index = 0, mname = "name"},
      makeSetToken("cd"),
      QuantityToken{0, 1},
      GroupEndToken{index = 0},
      QuantityToken{0, nil},
      SpecialToken{.CONCATENATION},
      LiteralToken{'e'},
      QuantityToken{2, 3},
      SpecialToken{.CONCATENATION},
    },
  }
  tc.expect(t, len(patterns) == len(expected_num_infix_tokens), "Expected num patterns to be equal to num expected infix lengths")
  tc.expect(t, len(patterns) == len(all_expected_postfix_tokens), "Expected num patterns to be equal to num expected postfix patterns")
  for pattern, idx in patterns {
    if verbose {
      fmt.printf("Pattern: \"%v\"\n", pattern)
    }
    infix_tokens, infix_ok := parseTokensFromString(pattern)
    defer deleteTokens(&infix_tokens)
    tc.expect(t, infix_ok, "Expected parse to be ok")
    tc.expect(
      t,
      len(infix_tokens) == expected_num_infix_tokens[idx],
      fmt.tprintf("Expected %v infix tokens. Got %v", expected_num_infix_tokens[idx], len(infix_tokens)),
    )
    if verbose {
      fmt.printf("Infix Tokens:\n")
      for token, idx in infix_tokens {
        fmt.printf(" % 2d: %v\n", idx, token)
      }
    }
    postfix_tokens, postfix_ok := convertInfixToPostfix(infix_tokens[:])
    expected_postfix_tokens := all_expected_postfix_tokens[idx]
    defer deleteTokens(&postfix_tokens)
    if verbose {
      fmt.printf("\nPostfix Tokens:\n")
      for _, idx in 0 ..< max(len(postfix_tokens), len(expected_postfix_tokens)) {
        fmt.printf("% 2d: \n", idx)
        if idx < len(postfix_tokens) {
          fmt.printf("| %v\n", postfix_tokens[idx])
        } else {
          fmt.printf("| missing\n")
        }
        if idx < len(expected_postfix_tokens) {
          fmt.printf("| %v\n", expected_postfix_tokens[idx])
        } else {
          fmt.printf("| missing\n")
        }
      }
      fmt.printf("\n")
    }
    cmp := areTokenArraysEqual(postfix_tokens[:], expected_postfix_tokens[:])
    tc.expect(t, cmp, "Postfix operators were not the same as expected")
  }
}
