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


@(test)
test_infix_to_postfix :: proc(t: ^testing.T, verbose: bool = false) {
  using re
  context.allocator = context.temp_allocator
  patterns := [?]string{"(b|cd)", "abc", "a|bcd|e", "(a|bcd|e)", "a(b?)+", "[ab]+", "(a|b)?c", "a$b^c", "($a|a)^", "a(b+)+", "()", "(a|b)"}
  expected_num_infix_tokens := [?]int{6, 3, 7, 9, 6, 2, 7, 5, 7, 6, 2, 5}
  all_expected_postfix_tokens := [?][]Token{
    {
      GroupBeginToken{index = 0},
      LiteralToken{'b'},
      LiteralToken{'c'},
      LiteralToken{'d'},
      ImplicitToken{.CONCATENATION},
      AlternationToken{},
      ImplicitToken{.CONCATENATION},
      GroupEndToken{index = 0},
      ImplicitToken{.CONCATENATION},
    },
    {LiteralToken{'a'}, LiteralToken{'b'}, ImplicitToken{.CONCATENATION}, LiteralToken{'c'}, ImplicitToken{.CONCATENATION}},
    {
      LiteralToken{'a'},
      LiteralToken{'b'},
      LiteralToken{'c'},
      ImplicitToken{.CONCATENATION},
      LiteralToken{'d'},
      ImplicitToken{.CONCATENATION},
      AlternationToken{},
      LiteralToken{'e'},
      AlternationToken{},
    },
    {
      GroupBeginToken{index = 0},
      LiteralToken{'a'},
      LiteralToken{'b'},
      LiteralToken{'c'},
      ImplicitToken{.CONCATENATION},
      LiteralToken{'d'},
      ImplicitToken{.CONCATENATION},
      AlternationToken{},
      LiteralToken{'e'},
      AlternationToken{},
      ImplicitToken{.CONCATENATION},
      GroupEndToken{index = 0},
      ImplicitToken{.CONCATENATION},
    },
    {
      LiteralToken{'a'},
      GroupBeginToken{index = 0},
      LiteralToken{'b'},
      QuantityToken{0, 1},
      ImplicitToken{.CONCATENATION},
      GroupEndToken{index = 0},
      ImplicitToken{.CONCATENATION},
      QuantityToken{1, nil},
      ImplicitToken{.CONCATENATION},
    },
    {makeSetToken("ab"), QuantityToken{1, nil}},
    {
      GroupBeginToken{index = 0},
      LiteralToken{'a'},
      LiteralToken{'b'},
      AlternationToken{},
      ImplicitToken{.CONCATENATION},
      GroupEndToken{index = 0},
      ImplicitToken{.CONCATENATION},
      QuantityToken{0, 1},
      LiteralToken{'c'},
      ImplicitToken{.CONCATENATION},
    },
    {
      LiteralToken{'a'},
      AssertionToken{.DOLLAR},
      ImplicitToken{.CONCATENATION},
      LiteralToken{'b'},
      ImplicitToken{.CONCATENATION},
      AssertionToken{.CARET},
      ImplicitToken{.CONCATENATION},
      LiteralToken{'c'},
      ImplicitToken{.CONCATENATION},
    },
    {
      GroupBeginToken{index = 0},
      AssertionToken{.DOLLAR},
      LiteralToken{'a'},
      ImplicitToken{.CONCATENATION},
      LiteralToken{'a'},
      AlternationToken{},
      ImplicitToken{.CONCATENATION},
      GroupEndToken{index = 0},
      ImplicitToken{.CONCATENATION},
      AssertionToken{.CARET},
      ImplicitToken{.CONCATENATION},
    },
    {
      LiteralToken{'a'},
      GroupBeginToken{index = 0},
      LiteralToken{'b'},
      QuantityToken{1, nil},
      ImplicitToken{.CONCATENATION},
      GroupEndToken{index = 0},
      ImplicitToken{.CONCATENATION},
      QuantityToken{1, nil},
      ImplicitToken{.CONCATENATION},
    },
    {GroupBeginToken{index = 0}, GroupEndToken{index = 0}, ImplicitToken{.CONCATENATION}},
    {
      GroupBeginToken{index = 0},
      LiteralToken{'a'},
      LiteralToken{'b'},
      AlternationToken{},
      ImplicitToken{.CONCATENATION},
      GroupEndToken{index = 0},
      ImplicitToken{.CONCATENATION},
    },
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
    if !cmp {
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
