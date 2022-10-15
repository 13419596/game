// Must be run with `-collection:tests=` flag
package test_re

import "core:fmt"
import "core:log"
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
  patterns := [?]string{"(b|cd)", "abc", "a|bcd|e", "(a|bcd|e)", "a(b?)+", "[ab]+", "(a|b)?c", "a$b^c", "($a|a)^", "a(b+)+", "()"}
  expected_num_infix_tokens := [?]int{6, 3, 7, 9, 6, 2, 7, 5, 7, 6, 2}
  all_expected_postfix_tokens := [?][]Token{
    {
      GroupBeginToken{index = 0},
      LiteralToken{'b'},
      LiteralToken{'c'},
      LiteralToken{'d'},
      SpecialToken{.CONCATENATION},
      OperationToken{.ALTERNATION},
      SpecialToken{.CONCATENATION},
      GroupEndToken{index = 0},
      SpecialToken{.CONCATENATION},
    },
    {LiteralToken{'a'}, LiteralToken{'b'}, SpecialToken{.CONCATENATION}, LiteralToken{'c'}, SpecialToken{.CONCATENATION}},
    {
      LiteralToken{'a'},
      LiteralToken{'b'},
      LiteralToken{'c'},
      SpecialToken{.CONCATENATION},
      LiteralToken{'d'},
      SpecialToken{.CONCATENATION},
      OperationToken{.ALTERNATION},
      LiteralToken{'e'},
      OperationToken{.ALTERNATION},
    },
    {
      GroupBeginToken{index = 0},
      LiteralToken{'a'},
      LiteralToken{'b'},
      LiteralToken{'c'},
      SpecialToken{.CONCATENATION},
      LiteralToken{'d'},
      SpecialToken{.CONCATENATION},
      OperationToken{.ALTERNATION},
      LiteralToken{'e'},
      OperationToken{.ALTERNATION},
      SpecialToken{.CONCATENATION},
      GroupEndToken{index = 0},
      SpecialToken{.CONCATENATION},
    },
    {
      LiteralToken{'a'},
      GroupBeginToken{index = 0},
      LiteralToken{'b'},
      QuantityToken{0, 1},
      SpecialToken{.CONCATENATION},
      GroupEndToken{index = 0},
      SpecialToken{.CONCATENATION},
      QuantityToken{1, nil},
      SpecialToken{.CONCATENATION},
    },
    {makeSetToken("ab"), QuantityToken{1, nil}},
    {
      GroupBeginToken{index = 0},
      LiteralToken{'a'},
      LiteralToken{'b'},
      OperationToken{.ALTERNATION},
      SpecialToken{.CONCATENATION},
      GroupEndToken{index = 0},
      SpecialToken{.CONCATENATION},
      QuantityToken{0, 1},
      LiteralToken{'c'},
      SpecialToken{.CONCATENATION},
    },
    {
      LiteralToken{'a'},
      OperationToken{.DOLLAR},
      SpecialToken{.CONCATENATION},
      LiteralToken{'b'},
      SpecialToken{.CONCATENATION},
      OperationToken{.CARET},
      SpecialToken{.CONCATENATION},
      LiteralToken{'c'},
      SpecialToken{.CONCATENATION},
    },
    {
      GroupBeginToken{index = 0},
      OperationToken{.DOLLAR},
      LiteralToken{'a'},
      SpecialToken{.CONCATENATION},
      LiteralToken{'a'},
      OperationToken{.ALTERNATION},
      SpecialToken{.CONCATENATION},
      GroupEndToken{index = 0},
      SpecialToken{.CONCATENATION},
      OperationToken{.CARET},
      SpecialToken{.CONCATENATION},
    },
    {
      LiteralToken{'a'},
      GroupBeginToken{index = 0},
      LiteralToken{'b'},
      QuantityToken{1, nil},
      SpecialToken{.CONCATENATION},
      GroupEndToken{index = 0},
      SpecialToken{.CONCATENATION},
      QuantityToken{1, nil},
      SpecialToken{.CONCATENATION},
    },
    {
      GroupBeginToken{index = 0},
      GroupEndToken{index = 0},
      SpecialToken{.CONCATENATION},
    }
  }
  tc.expect(t, len(patterns) == len(expected_num_infix_tokens), "Expected num patterns to be equal to num expected infix lengths")
  tc.expect(t, len(patterns) == len(all_expected_postfix_tokens), "Expected num patterns to be equal to num expected postfix patterns")
  for pattern, idx in patterns {
    infix_tokens, infix_ok := parseTokensFromString(pattern)
    defer deleteTokens(&infix_tokens)
    tc.expect(t, infix_ok, "Expected parse to be ok")
    tc.expect(
      t,
      len(infix_tokens) == expected_num_infix_tokens[idx],
      fmt.tprintf("Expected %v infix tokens. Got %v", expected_num_infix_tokens[idx], len(infix_tokens)),
    )
    postfix_tokens, postfix_ok := convertInfixToPostfix(infix_tokens[:])
    expected_postfix_tokens := all_expected_postfix_tokens[idx]
    defer deleteTokens(&postfix_tokens)
    cmp := areTokenArraysEqual(postfix_tokens[:], expected_postfix_tokens[:])
    if !cmp  {
      log.errorf("Pattern: \"%v\"", pattern)
      log.errorf("Infix Tokens:")
      for token, idx in infix_tokens {
        log.errorf(" % 2d: %v", idx, token)
      }
      log.errorf("\nPostfix Tokens:")
      for _, idx in 0 ..< max(len(postfix_tokens), len(expected_postfix_tokens)) {
        log.errorf("% 2d: ", idx)
        if idx < len(postfix_tokens) {
          log.errorf("| got: %v", postfix_tokens[idx])
        } else {
          log.errorf("| got: missing")
        }
        if idx < len(expected_postfix_tokens) {
          log.errorf("| exp: %v", expected_postfix_tokens[idx])
        } else {
          log.errorf("| exp: missing")
        }
      }
      log.errorf("\n")
    }
    tc.expect(t, cmp, "Postfix operators were not the same as expected")
  }
}
