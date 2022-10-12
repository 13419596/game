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

@(test)
test_match_token :: proc(t: ^testing.T) {
  test_parseLatterQuantityToken(t)
  test_parseLatterEscapedRune(t)
  test_parseLatterSetToken(t)
  test_parseLatterGroupBeginToken(t)
  test_makeTokenFromString(t)
  test_makeLiteralTokenCaseInsensitive(t)
  test_makeSetTokenCaseInsensitive(t)
  test_makeTokenCaseInsensitive(t)
  test_doesSetTokenMatch(t)
}


@(test)
test_parseLatterQuantityToken :: proc(t: ^testing.T) {
  using re
  {
    invalid_patterns := [?]string{"5,3}"}
    for pattern in invalid_patterns {
      tok, num_bytes_parsed, ok := parseLatterQuantityToken(pattern)
      tc.expect(t, !ok, fmt.tprintf("Expected pattern:\"%v\" to be not ok", pattern))
    }
  }
  {
    literal_patterns := [?]string{"", "f", ",", ",f", ",1", ",1f", "}", "}f", "0", "0f", "0,000}", "0,000}f", ",000}", ",000}f", "000,}", "000,}f"}
    expected := LiteralToken {
      value = '{',
    }
    for pattern in literal_patterns {
      tok, num_bytes_parsed, ok := parseLatterQuantityToken(pattern)
      tc.expect(t, ok, fmt.tprintf("Expected pattern:\"%v\" to be not ok", pattern))
      tc.expect(t, num_bytes_parsed == 0, fmt.tprintf("Pattern:len(\"%v\") Expected:%v; Got %v", pattern, 0, num_bytes_parsed))
      if ltok, ltok_ok := tok.(LiteralToken); ltok_ok {
        tc.expect(t, ltok == expected, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Got:%v", pattern, expected, ltok))
      } else {
        tc.expect(t, false, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Got:%v", pattern, expected, ltok))
      }
    }
  }
  {
    valid_patterns := [?]string{",}", "0}", "3}", "444}", ",3}", ",444}", "0,}", "1,}", "1,44}", "11,434}"}
    expecteds := [?]QuantityToken{
      QuantityToken{0, 0},
      QuantityToken{0, 0},
      QuantityToken{3, 3},
      QuantityToken{444, 444},
      QuantityToken{0, 3},
      QuantityToken{0, 444},
      QuantityToken{0, nil},
      QuantityToken{1, nil},
      QuantityToken{1, 44},
      QuantityToken{11, 434},
    }
    for pattern, idx in valid_patterns {
      tok, num_bytes_parsed, ok := parseLatterQuantityToken(pattern)
      expected := expecteds[idx]
      tc.expect(t, ok, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Not okay", pattern, expected))
      tc.expect(t, num_bytes_parsed == len(pattern), fmt.tprintf("Pattern:len(\"%v\")==%v; Got %v", pattern, len(pattern), num_bytes_parsed))
      if qtok, qtok_ok := tok.(QuantityToken); qtok_ok {
        tc.expect(t, qtok == expected, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Got:%v", pattern, expected, qtok))
      } else {
        tc.expect(t, false, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Got:%v", pattern, expected, qtok))
      }
    }
  }
}

@(test)
test_parseLatterEscapedRune :: proc(t: ^testing.T) {
  using re
  {
    // escaped metas
    meta_chars := "$^*+?\\.|(){}[]"
    for rn in meta_chars {
      tok, num_bytes_parsed, ok := parseLatterEscapedRune(rn)
      expected := LiteralToken{rn}
      tc.expect(t, ok, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Not okay", rn, expected))
      tc.expect(t, num_bytes_parsed == 1)
      if ltok, ltok_ok := tok.(LiteralToken); ltok_ok {
        tc.expect(t, ltok == expected, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Got:%v", rn, expected, ltok))
      } else {
        tc.expect(t, false, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Got:%v", rn, expected, ltok))
      }
    }
  }
  {
    // special chars
    special_chars := "ntv"
    expecteds := "\n\t\v"
    for rn, idx in special_chars {
      tok, num_bytes_parsed, ok := parseLatterEscapedRune(rn)
      expected := LiteralToken{rune(expecteds[idx])}
      tc.expect(t, ok, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Not okay", rn, expected))
      tc.expect(t, num_bytes_parsed == 1)
      if ltok, ltok_ok := tok.(LiteralToken); ltok_ok {
        tc.expect(t, ltok == expected, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Got:%v", rn, expected, ltok))
      } else {
        tc.expect(t, false, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Got:%v", rn, expected, ltok))
      }
    }
  }
  {
    // shorthand chars
    class_chars := "bswd"
    expected_classes := [?]ShortHandClass{.Flag_B, .Flag_S, .Flag_W, .Flag_D}
    for to_upper in 0 ..= 1 {
      for initial_rn, idx in class_chars {
        rn := to_upper != 0 ? unicode.to_upper(initial_rn) : initial_rn
        tok, num_bytes_parsed, ok := parseLatterEscapedRune(rn)
        defer deleteToken(&tok)
        expected := to_upper != 0 ? SetToken{neg_shorthands = {expected_classes[idx]}} : SetToken{pos_shorthands = {expected_classes[idx]}}
        tc.expect(t, ok, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Not okay", rn, expected))
        tc.expect(t, num_bytes_parsed == 1)
        if stok, stok_ok := tok.(SetToken); stok_ok {
          tc.expect(t, isequal_SetToken(&stok, &expected), fmt.tprintf("Pattern:\"%v\"; Expected:%v; Got:%v", rn, expected, stok))
        } else {
          tc.expect(t, false, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Got:%v", rn, expected, stok))
        }
      }
    }
  }
}

@(private = "file")
makeSetToken :: proc(
  set_chars: string = "",
  set_negated: bool = false,
  pos_sh: bit_set[re.ShortHandClass] = {},
  neg_sh: bit_set[re.ShortHandClass] = {},
  allocator := context.allocator,
) -> re.SetToken {
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

@(test)
test_parseLatterSetToken :: proc(t: ^testing.T) {
  using re
  using sort
  using container_set
  {
    invalid_patterns := [?]string{"", "]", "a", "\\", "\\]", "a-z"}
    for pattern, idx in invalid_patterns {
      tok, num_bytes_parsed, ok := parseLatterSetToken(pattern)
      tc.expect(t, !ok, fmt.tprintf("Pattern:\"%v\"; Expected Not okay", pattern))
      tc.expect(t, num_bytes_parsed == 0, fmt.tprintf("Pattern:len(\"%v\")==%v; Got %v", pattern, len(pattern), num_bytes_parsed))
    }
  }
  {
    valid_patterns := [?]string{
      "a]",
      "ab]",
      "\\\\]",
      "\\]]",
      "a-d]",
      "^a-d]",
      "^a]",
      "\\d]",
      "\\d\\w\\s]",
      "^\\d\\w\\s]",
      "\\D\\W\\S]",
      "^\\D\\W\\S]",
      "\\d\\w\\s\\D\\W\\S]",
      "^\\d\\w\\s\\D\\W\\S]",
      ".]",
      "\n\b\v\t]",
      "\\n\\b\\v\\t]",
      "\\n\\b\\v\\ta-c-]",
      "-\\n\\b\\v\\ta-c-]",
      "^-\\n\\b\\v\\ta-c-]",
      "^-\\n\\b\\v\\ta-c\\w\\S-]",
      "-\\n\\b\\v\\ta-c\\w\\S-]",
    }
    expecteds := [?]SetToken{
      makeSetToken("a"),
      makeSetToken("ab"),
      makeSetToken("\\"),
      makeSetToken("]"),
      makeSetToken("abcd"),
      makeSetToken("abcd", true),
      makeSetToken("a", true),
      makeSetToken("", false, {.Flag_D}),
      makeSetToken("", false, {.Flag_D, .Flag_W, .Flag_S}, {}),
      makeSetToken("", true, {}, {.Flag_D, .Flag_W, .Flag_S}),
      makeSetToken("", false, {}, {.Flag_D, .Flag_W, .Flag_S}),
      makeSetToken("", true, {.Flag_D, .Flag_W, .Flag_S}, {}),
      makeSetToken("", false, {.Flag_D, .Flag_W, .Flag_S}, {.Flag_D, .Flag_W, .Flag_S}),
      makeSetToken("", true, {.Flag_D, .Flag_W, .Flag_S}, {.Flag_D, .Flag_W, .Flag_S}),
      makeSetToken("."),
      makeSetToken("\n\b\v\t"),
      makeSetToken("\n\b\v\t"),
      makeSetToken("\n\b\v\tabc-"),
      makeSetToken("\n\b\v\tabc-"),
      makeSetToken("\n\b\v\tabc-", true),
      makeSetToken("-\n\b\v\tabc", true, {.Flag_S}, {.Flag_W}),
      makeSetToken("-\n\b\v\tabc", false, {.Flag_W}, {.Flag_S}),
    }
    tc.expect(t, len(valid_patterns) == len(expecteds), "expected patterns and results to be same length")
    for pattern, idx in valid_patterns {
      tok, num_bytes_parsed, ok := parseLatterSetToken(pattern)
      expected := expecteds[idx]
      tc.expect(t, ok, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Not okay", pattern, expected))
      tc.expect(t, num_bytes_parsed == len(pattern), fmt.tprintf("Pattern:len(\"%v\")==%v; Got %v", pattern, len(pattern), num_bytes_parsed))
      cmp := isequal_SetToken(&tok, &expected)
      // if !cmp {
      //   e_tmp := make([dynamic]u32)
      //   t_tmp := make([dynamic]u32)
      //   defer delete(e_tmp)
      //   defer delete(t_tmp)
      //   for k, v in expected.charset.set {
      //     append(&e_tmp, u32(k))
      //   }
      //   for k, v in tok.charset.set {
      //     append(&t_tmp, u32(k))
      //   }
      //   quick_sort(e_tmp[:])
      //   quick_sort(t_tmp[:])
      //   fmt.printf("Expected : %v\n", e_tmp)
      //   fmt.printf("Got      : %v\n", t_tmp)
      // }
      tc.expect(t, cmp, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Got:%v", pattern, expected, tok))
    }
  }
}


@(test)
test_parseLatterGroupBeginToken :: proc(t: ^testing.T) {
  using re
  using sort
  using container_set
  {
    invalid_patterns := [?]string{"?", "?<foo>", "?P<f-o>", "?P<foo!>", "?P<<foo>"}
    for pattern, idx in invalid_patterns {
      tok, num_bytes_parsed, ok := parseLatterGroupBeginToken(pattern)
      tc.expect(t, !ok, fmt.tprintf("Pattern:\"%v\"; Expected Not okay", pattern))
      tc.expect(t, num_bytes_parsed == 0, fmt.tprintf("Pattern:\"%v\"; Expected bytes==0; Got %v", pattern, num_bytes_parsed))
    }
  }
  {
    valid_patterns := [?]string{"", "a", "?:", "?:fooo", "?P<name>", "?P<name>test)", "?P<námë3>test)"}
    expecteds := [?]GroupBeginToken{
      GroupBeginToken{},
      GroupBeginToken{},
      GroupBeginToken{non_capturing = true},
      GroupBeginToken{non_capturing = true},
      GroupBeginToken{mname = "name"},
      GroupBeginToken{mname = "name"},
      GroupBeginToken{mname = "námë3"},
    }
    lengths := [?]int{0, 0, 2, 2, 7, 7, 10}
    tc.expect(t, len(valid_patterns) == len(expecteds), "expected patterns and results to be same length")
    tc.expect(t, len(valid_patterns) == len(lengths), "expected patterns and results to be same length")
    for pattern, idx in valid_patterns {
      tok, num_bytes_parsed, ok := parseLatterGroupBeginToken(pattern)
      defer deleteGroupBeginToken(&tok)
      expected := expecteds[idx]
      tc.expect(t, ok, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Not okay", pattern, expected))
      tc.expect(t, num_bytes_parsed == lengths[idx], fmt.tprintf("Expected length:%v; Got %v", lengths[idx], num_bytes_parsed))
      cmp := isequal_GroupBeginToken(&tok, &expected)
      // if !cmp {
      //   fmt.printf(".index: %v == %v => %v\n",tok.index, expected.index, tok.index==expected.index)
      //   fmt.printf(".mname: %v == %v => %v\n",tok.mname, expected.mname, tok.mname==expected.mname)
      //   fmt.printf(".mname lhs: %v == nil => %v\n",tok.mname, tok.mname == nil)
      //   fmt.printf(".mname rhs: %v == nil => %v\n",expected.mname, expected.mname == nil)
      // }
      tc.expect(t, cmp, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Got:%v", pattern, expected, tok))
    }
  }
}


@(test)
test_makeTokenFromString :: proc(t: ^testing.T) {
  using re
  {
    invalid_patterns := [?]string{"\\"}
    for pattern, idx in invalid_patterns {
      tok, num_bytes_parsed, ok := makeTokenFromString(pattern)
      defer deleteToken(&tok)
      tc.expect(t, num_bytes_parsed == 0, fmt.tprintf("Expected bytes parsed == 0. Got:%v", num_bytes_parsed))
      tc.expect(t, !ok, "Expected not okay")
    }
  }
  {
    valid_patterns := [?]string {
      // Quanity patterns
      "{,}",
      "{0}",
      "{3}",
      "{444}",
      "{,3}",
      "{,444}",
      "{0,}",
      "{1,}",
      "{1,44}",
      "{11,434}",
      // Set Patterns
      "[a]a",
      "[ab]a",
      "[\\\\]",
      "[\\]]",
      "[a-d]",
      "[^a-d]",
      "[^a]",
      "[\\d]",
      "[\\d\\w\\s]",
      "[^\\d\\w\\s]",
      "[\\D\\W\\S]",
      "[^\\D\\W\\S]",
      "[\\d\\w\\s\\D\\W\\S]",
      "[^\\d\\w\\s\\D\\W\\S]",
      "[.]",
      "[\n\b\v\t]",
      "[\\n\\b\\v\\t]",
      "[\\n\\b\\v\\ta-c-]",
      "[-\\n\\b\\v\\ta-c-]",
      "[^-\\n\\b\\v\\ta-c-]",
      "[^-\\n\\b\\v\\ta-c\\w\\S-]",
      "[-\\n\\b\\v\\ta-c\\w\\S-]",
      // Group Begins
      "(",
      "(?:",
      "(?P<name>",
      "(?P<námë3>",
      // Group End
      ")",
      // Escaped meta
      "\\$",
      "\\^",
      "\\*",
      "\\+",
      "\\?",
      "\\.",
      "\\|",
      "\\(",
      "\\)",
      "\\{",
      "\\}",
      "\\[",
      "\\]",
      "\\\\",
      // Regular
      "a",
      "3",
      // Backslash chars
      "\b",
      "\n",
      "\t",
      "\v",
      // Escaped backslash chars
      "\\n",
      "\\t",
      "\\v",
      // Meta Chars
      "$",
      "^",
      "*",
      "+",
      "?",
      ".",
      "|",
      "(",
      ")",
      "}",
      "]",
      // Single shorthand classes,
      "\\b",
      "\\B",
      "\\w",
      "\\W",
      "\\s",
      "\\S",
      "\\d",
      "\\D",
    }
    expecteds := [?]Token{
      QuantityToken{0, 0},
      QuantityToken{0, 0},
      QuantityToken{3, 3},
      QuantityToken{444, 444},
      QuantityToken{0, 3},
      QuantityToken{0, 444},
      QuantityToken{0, nil},
      QuantityToken{1, nil},
      QuantityToken{1, 44},
      QuantityToken{11, 434},
      makeSetToken("a"),
      makeSetToken("ab"),
      makeSetToken("\\"),
      makeSetToken("]"),
      makeSetToken("abcd"),
      makeSetToken("abcd", true),
      makeSetToken("a", true),
      makeSetToken("", false, {.Flag_D}),
      makeSetToken("", false, {.Flag_D, .Flag_W, .Flag_S}, {}),
      makeSetToken("", true, {}, {.Flag_D, .Flag_W, .Flag_S}),
      makeSetToken("", false, {}, {.Flag_D, .Flag_W, .Flag_S}),
      makeSetToken("", true, {.Flag_D, .Flag_W, .Flag_S}, {}),
      makeSetToken("", false, {.Flag_D, .Flag_W, .Flag_S}, {.Flag_D, .Flag_W, .Flag_S}),
      makeSetToken("", true, {.Flag_D, .Flag_W, .Flag_S}, {.Flag_D, .Flag_W, .Flag_S}),
      makeSetToken("."),
      makeSetToken("\n\b\v\t"),
      makeSetToken("\n\b\v\t"),
      makeSetToken("\n\b\v\tabc-"),
      makeSetToken("\n\b\v\tabc-"),
      makeSetToken("\n\b\v\tabc-", true),
      makeSetToken("-\n\b\v\tabc", true, {.Flag_S}, {.Flag_W}),
      makeSetToken("-\n\b\v\tabc", false, {.Flag_W}, {.Flag_S}),
      GroupBeginToken{},
      GroupBeginToken{non_capturing = true},
      GroupBeginToken{mname = "name"},
      GroupBeginToken{mname = "námë3"},
      GroupEndToken{},
      LiteralToken{'$'},
      LiteralToken{'^'},
      LiteralToken{'*'},
      LiteralToken{'+'},
      LiteralToken{'?'},
      LiteralToken{'.'},
      LiteralToken{'|'},
      LiteralToken{'('},
      LiteralToken{')'},
      LiteralToken{'{'},
      LiteralToken{'}'},
      LiteralToken{'['},
      LiteralToken{']'},
      LiteralToken{'\\'},
      LiteralToken{'a'},
      LiteralToken{'3'},
      LiteralToken{'\b'},
      LiteralToken{'\n'},
      LiteralToken{'\t'},
      LiteralToken{'\v'},
      LiteralToken{'\n'},
      LiteralToken{'\t'},
      LiteralToken{'\v'},
      ZeroWidthToken{.END},
      ZeroWidthToken{.BEGINNING},
      QuantityToken{0, nil},
      QuantityToken{1, nil},
      QuantityToken{0, 1},
      SetToken{pos_shorthands = {.Flag_Dot}},
      ZeroWidthToken{.ALTERNATION},
      GroupBeginToken{},
      GroupEndToken{},
      LiteralToken{'}'},
      LiteralToken{']'},
      SetToken{pos_shorthands = {.Flag_B}},
      SetToken{neg_shorthands = {.Flag_B}},
      SetToken{pos_shorthands = {.Flag_W}},
      SetToken{neg_shorthands = {.Flag_W}},
      SetToken{pos_shorthands = {.Flag_S}},
      SetToken{neg_shorthands = {.Flag_S}},
      SetToken{pos_shorthands = {.Flag_D}},
      SetToken{neg_shorthands = {.Flag_D}},
    }
    tc.expect(t, len(valid_patterns) == len(expecteds), "Expected patterns and expected results to be same length")
    for pattern, idx in valid_patterns {
      expected := expecteds[idx]
      tok, num_bytes_parsed, ok := makeTokenFromString(pattern)
      defer deleteToken(&tok)
      // tc.expect(t, ok, fmt.tprintf("Pattern:\"%v\" Expected to be okay.", pattern))
      cmp := isequal_Token(&tok, &expected)
      tc.expect(t, cmp, fmt.tprintf("Pattern:\"%v\" Expected:%v Got:%v", pattern, expected, tok))
    }
  }
}

@(test)
test_makeLiteralTokenCaseInsensitive :: proc(t: ^testing.T) {
  using re
  inputs := [?]LiteralToken{LiteralToken{'a'}, LiteralToken{'.'}, LiteralToken{'A'}, LiteralToken{'Ø'}, LiteralToken{'Ä'}}
  expecteds := [?]LiteralToken{LiteralToken{'a'}, LiteralToken{'.'}, LiteralToken{'a'}, LiteralToken{'ø'}, LiteralToken{'ä'}}
  for _, idx in inputs {
    input := &inputs[idx]
    makeLiteralTokenCaseInsensitive(input)
    expected := expecteds[idx]
    tc.expect(t, input^ == expected, fmt.tprintf("Expected:%v Got:%v", expected, input))
  }
}

@(test)
test_makeSetTokenCaseInsensitive :: proc(t: ^testing.T) {
  using re
  context.allocator = context.temp_allocator
  inputs := [?]SetToken{makeSetToken("aaB"), makeSetToken("."), makeSetToken("ABCd0"), makeSetToken("Ø"), makeSetToken("Ä")}
  expecteds := [?]SetToken{makeSetToken("abAB"), makeSetToken("."), makeSetToken("abcdABCD0"), makeSetToken("øØ"), makeSetToken("äÄ")}
  for _, idx in inputs {
    input := &inputs[idx]
    makeSetTokenCaseInsensitive(input)
    expected := expecteds[idx]
    cmp := isequal_SetToken(input, &expected)
    tc.expect(t, cmp, fmt.tprintf("Expected:%v Got:%v", expected, input))
  }
}

@(test)
test_makeTokenCaseInsensitive :: proc(t: ^testing.T) {
  using re
  inputs := [?]Token{
    LiteralToken{'a'},
    LiteralToken{'.'},
    LiteralToken{'A'},
    LiteralToken{'Ø'},
    LiteralToken{'Ä'},
    makeSetToken("aaB"),
    makeSetToken("."),
    makeSetToken("ABCd0"),
    makeSetToken("Ø"),
    makeSetToken("Ä"),
  }
  expecteds := [?]Token{
    LiteralToken{'a'},
    LiteralToken{'.'},
    LiteralToken{'a'},
    LiteralToken{'ø'},
    LiteralToken{'ä'},
    makeSetToken("abAB"),
    makeSetToken("."),
    makeSetToken("abcdABCD0"),
    makeSetToken("øØ"),
    makeSetToken("äÄ"),
  }
  for _, idx in inputs {
    input := &inputs[idx]
    makeTokenCaseInsensitive(input)
    expected := expecteds[idx]
    cmp := isequal_Token(input, &expected)
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
