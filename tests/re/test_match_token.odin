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
makeSetToken :: proc(
  set_chars: string = "",
  set_negated: bool = false,
  pos_sh: bit_set[re.ShortHandClass] = {},
  neg_sh: bit_set[re.ShortHandClass] = {},
  allocator := context.allocator,
) -> re.SetToken {
  // Helper function to make set tokens
  using container_set
  using re
  out := SetToken {
    charset        = makeSet(T = rune, allocator = allocator),
    set_negated    = set_negated,
    pos_shorthands = pos_sh,
    neg_shorthands = neg_sh,
  }
  for rn in set_chars {
    add(&out.charset, rn)
  }
  return out
}

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
test_match_token :: proc(t: ^testing.T) {
  test_makeCaseInsensitiveLiteral(t)
  test_updateSetTokenCaseInsensitive(t)
  test_doesSetTokenMatch(t)
}


@(test)
test_updateSetTokenCaseInsensitive :: proc(t: ^testing.T) {
  using re
  context.allocator = context.temp_allocator
  inputs := [?]SetToken{makeSetToken("aaB"), makeSetToken("."), makeSetToken("ABCd0"), makeSetToken("Ø"), makeSetToken("Ä")}
  expecteds := [?]SetToken{makeSetToken("abAB"), makeSetToken("."), makeSetToken("abcdABCD0"), makeSetToken("øØ"), makeSetToken("äÄ")}
  for _, idx in inputs {
    input := &inputs[idx]
    updateSetTokenCaseInsensitive(input)
    expected := expecteds[idx]
    cmp := isequal_SetToken(input, &expected)
    tc.expect(t, cmp, fmt.tprintf("Expected:%v Got:%v", expected, input))
  }
}

@(test)
test_makeCaseInsensitiveLiteral :: proc(t: ^testing.T) {
  using re
  context.allocator = context.temp_allocator
  inputs := [?]LiteralToken{LiteralToken{'.'}, LiteralToken{'a'}, LiteralToken{'Ø'}}
  expecteds := [?]Token{LiteralToken{'.'}, makeSetToken("aA"), makeSetToken("øØ")}
  for _, idx in inputs {
    input := &inputs[idx]
    result := makeCaseInsensitiveLiteral(input)
    expected := expecteds[idx]
    cmp := isequal_Token(&result, &expected)
    tc.expect(t, cmp, fmt.tprintf("Expected:%v Got:%v", expected, input))
  }
}

@(test)
test_doesSetTokenMatch :: proc(t: ^testing.T) {
  using re
  /*
    set_token: ^SetToken,
  curr_rune: rune,
  prev_rune: rune = {},
  at_beginning: bool = false,
  at_end: bool = false,
  flags: RegexFlags = {},
  */
  {
    stok := makeSetToken("ab")
    inputs := [?]rune{'a', 'b', 'c', 'A', 'B', '.', '!', ' ', '0'}
    expecteds := [?]bool{true, true, false, false, false, false, false, false, false}
    for input, idx in inputs {
      expected := expecteds[idx]
      result := doesSetTokenMatch(&stok, input)
      if result != expected {
        fmt.printf("r:'%v' result:%v expected:%v\n", input, result, expected)
      }
      tc.expect(t, (result == expected))
    }
  }
  // FLAG W
  {
    stok := makeSetToken(set_chars = "ab", pos_sh = {.Flag_W})
    inputs := [?]rune{'a', 'b', 'c', 'A', 'B', '.', '!', ' ', '0'}
    expecteds := [?]bool{true, true, true, true, true, false, false, false, true}
    for input, idx in inputs {
      expected := expecteds[idx]
      result := doesSetTokenMatch(&stok, input)
      if result != expected {
        fmt.printf("r:'%v' result:%v expected:%v\n", input, result, expected)
      }
      tc.expect(t, (result == expected))
    }
  }
  {
    stok := makeSetToken(set_chars = "ab", neg_sh = {.Flag_W})
    inputs := [?]rune{'a', 'b', 'c', 'A', 'B', '.', '!', ' ', '0'}
    expecteds := [?]bool{true, true, false, false, false, true, true, true, false}
    for input, idx in inputs {
      expected := expecteds[idx]
      result := doesSetTokenMatch(&stok, input)
      if result != expected {
        fmt.printf("r:'%v' result:%v expected:%v\n", input, result, expected)
      }
      tc.expect(t, (result == expected))
    }
  }
  {
    stok := makeSetToken(set_chars = "ab", pos_sh = {.Flag_W}, set_negated = true)
    inputs := [?]rune{'a', 'b', 'c', 'A', 'B', '.', '!', ' ', '0'}
    expecteds := [?]bool{false, false, false, false, false, true, true, true, false}
    for input, idx in inputs {
      expected := expecteds[idx]
      result := doesSetTokenMatch(&stok, input)
      if result != expected {
        fmt.printf("r:'%v' result:%v expected:%v\n", input, result, expected)
      }
      tc.expect(t, (result == expected))
    }
  }
  {
    stok := makeSetToken(set_chars = "ab", neg_sh = {.Flag_W}, set_negated = true)
    inputs := [?]rune{'a', 'b', 'c', 'A', 'B', '.', '!', ' ', '0'}
    expecteds := [?]bool{false, false, true, true, true, false, false, false, true}
    for input, idx in inputs {
      expected := expecteds[idx]
      result := doesSetTokenMatch(&stok, input)
      if result != expected {
        fmt.printf("r:'%v' result:%v expected:%v\n", input, result, expected)
      }
      tc.expect(t, (result == expected))
    }
  }
  // FLAG D
  {
    stok := makeSetToken(set_chars = "ab", pos_sh = {.Flag_D})
    inputs := [?]rune{'a', 'b', 'c', 'A', 'B', '.', '!', ' ', '0'}
    expecteds := [?]bool{true, true, false, false, false, false, false, false, true}
    for input, idx in inputs {
      expected := expecteds[idx]
      result := doesSetTokenMatch(&stok, input)
      if result != expected {
        fmt.printf("r:'%v' result:%v expected:%v\n", input, result, expected)
      }
      tc.expect(t, (result == expected))
    }
  }
  {
    stok := makeSetToken(set_chars = "ab", neg_sh = {.Flag_D})
    inputs := [?]rune{'a', 'b', 'c', 'A', 'B', '.', '!', ' ', '0'}
    expecteds := [?]bool{true, true, true, true, true, true, true, true, false}
    for input, idx in inputs {
      expected := expecteds[idx]
      result := doesSetTokenMatch(&stok, input)
      if result != expected {
        fmt.printf("r:'%v' result:%v expected:%v\n", input, result, expected)
      }
      tc.expect(t, (result == expected))
    }
  }
  {
    stok := makeSetToken(set_chars = "ab", pos_sh = {.Flag_D}, set_negated = true)
    inputs := [?]rune{'a', 'b', 'c', 'A', 'B', '.', '!', ' ', '0'}
    expecteds := [?]bool{false, false, true, true, true, true, true, true, false}
    for input, idx in inputs {
      expected := expecteds[idx]
      result := doesSetTokenMatch(&stok, input)
      if result != expected {
        fmt.printf("r:'%v' result:%v expected:%v\n", input, result, expected)
      }
      tc.expect(t, (result == expected))
    }
  }
  {
    stok := makeSetToken(set_chars = "ab", neg_sh = {.Flag_D}, set_negated = true)
    inputs := [?]rune{'a', 'b', 'c', 'A', 'B', '.', '!', ' ', '0'}
    expecteds := [?]bool{false, false, false, false, false, false, false, false, true}
    for input, idx in inputs {
      expected := expecteds[idx]
      result := doesSetTokenMatch(&stok, input)
      if result != expected {
        fmt.printf("r:'%v' result:%v expected:%v\n", input, result, expected)
      }
      tc.expect(t, (result == expected))
    }
  }
  // FLAG S
  {
    stok := makeSetToken(set_chars = "ab", pos_sh = {.Flag_S})
    inputs := [?]rune{'a', 'b', 'c', 'A', 'B', '.', '!', ' ', '0'}
    expecteds := [?]bool{true, true, false, false, false, false, false, true, false}
    for input, idx in inputs {
      expected := expecteds[idx]
      result := doesSetTokenMatch(&stok, input)
      if result != expected {
        fmt.printf("r:'%v' result:%v expected:%v\n", input, result, expected)
      }
      tc.expect(t, (result == expected))
    }
  }
  {
    stok := makeSetToken(set_chars = "ab", neg_sh = {.Flag_S})
    inputs := [?]rune{'a', 'b', 'c', 'A', 'B', '.', '!', ' ', '0'}
    expecteds := [?]bool{true, true, true, true, true, true, true, false, true}
    for input, idx in inputs {
      expected := expecteds[idx]
      result := doesSetTokenMatch(&stok, input)
      if result != expected {
        fmt.printf("r:'%v' result:%v expected:%v\n", input, result, expected)
      }
      tc.expect(t, (result == expected))
    }
  }
  {
    stok := makeSetToken(set_chars = "ab", pos_sh = {.Flag_S}, set_negated = true)
    inputs := [?]rune{'a', 'b', 'c', 'A', 'B', '.', '!', ' ', '0'}
    expecteds := [?]bool{false, false, true, true, true, true, true, false, true}
    for input, idx in inputs {
      expected := expecteds[idx]
      result := doesSetTokenMatch(&stok, input)
      if result != expected {
        fmt.printf("r:'%v' result:%v expected:%v\n", input, result, expected)
      }
      tc.expect(t, (result == expected))
    }
  }
  {
    stok := makeSetToken(set_chars = "ab", neg_sh = {.Flag_S}, set_negated = true)
    inputs := [?]rune{'a', 'b', 'c', 'A', 'B', '.', '!', ' ', '0'}
    expecteds := [?]bool{false, false, false, false, false, false, false, true, false}
    for input, idx in inputs {
      expected := expecteds[idx]
      result := doesSetTokenMatch(&stok, input)
      if result != expected {
        fmt.printf("r:'%v' result:%v expected:%v\n", input, result, expected)
      }
      tc.expect(t, (result == expected))
    }
  }
  {
    stok := makeSetToken(pos_sh = {.Flag_Dot})
    inputs := [?]rune{'a', 'b', 'c', 'A', 'B', '.', '!', ' ', '0'}
    for input, idx in inputs {
      expected := true
      result := doesSetTokenMatch(&stok, input)
      if result != expected {
        fmt.printf("r:'%v' result:%v expected:%v\n", input, result, expected)
      }
      tc.expect(t, (result == expected))
    }
    tc.expect(t, false == doesSetTokenMatch(&stok, '\n'))
    tc.expect(t, true == doesSetTokenMatch(set_token = &stok, curr_rune = '\n', flags = {.DOTALL}))
  }
}
