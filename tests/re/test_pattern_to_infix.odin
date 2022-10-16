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
test_pattern_to_infix :: proc(t: ^testing.T) {
  test_parseLatterQuantityToken(t)
  test_parseLatterEscapedRune(t)
  test_parseLatterSetToken(t)
  test_parseLatterGroupBeginToken(t)
  test__parseSingleTokenFromString(t)
  test_parseTokensFromString(t)
}


@(test)
test_parseLatterQuantityToken :: proc(t: ^testing.T) {
  using re
  {
    invalid_patterns := [?]string{"5,3}"}
    for pattern in invalid_patterns {
      tok, num_bytes_parsed, ok := _parseLatterQuantityToken(pattern)
      tc.expect(t, !ok, fmt.tprintf("Expected pattern:\"%v\" to be not ok", pattern))
    }
  }
  {
    literal_patterns := [?]string{"", "f", ",", ",f", ",1", ",1f", "}", "}f", "0", "0f", "0,000}", "0,000}f", ",000}", ",000}f", "000,}", "000,}f"}
    expected := LiteralToken {
      value = '{',
    }
    for pattern in literal_patterns {
      tok, num_bytes_parsed, ok := _parseLatterQuantityToken(pattern)
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
      tok, num_bytes_parsed, ok := _parseLatterQuantityToken(pattern)
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
      tok, num_bytes_parsed, ok := _parseLatterEscapedRune(rn)
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
      tok, num_bytes_parsed, ok := _parseLatterEscapedRune(rn)
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
        tok, num_bytes_parsed, ok := _parseLatterEscapedRune(rn)
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

@(test)
test_parseLatterSetToken :: proc(t: ^testing.T) {
  using re
  using sort
  using container_set
  {
    invalid_patterns := [?]string{"", "]", "a", "\\", "\\]", "a-z"}
    for pattern, idx in invalid_patterns {
      tok, num_bytes_parsed, ok := _parseLatterSetToken(pattern)
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
      tok, num_bytes_parsed, ok := _parseLatterSetToken(pattern)
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
      //   log.errorf("Expected : %v\n", e_tmp)
      //   log.errorf("Got      : %v\n", t_tmp)
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
      tok, num_bytes_parsed, ok := _parseLatterGroupBeginToken(pattern)
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
    lengths := [?]int{0, 0, 2, 2, 8, 8, 11}
    tc.expect(t, len(valid_patterns) == len(expecteds), "expected patterns and results to be same length")
    tc.expect(t, len(valid_patterns) == len(lengths), "expected patterns and results to be same length")
    for pattern, idx in valid_patterns {
      tok, num_bytes_parsed, ok := _parseLatterGroupBeginToken(pattern)
      defer deleteGroupBeginToken(&tok)
      expected := expecteds[idx]
      tc.expect(t, ok, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Not okay", pattern, expected))
      tc.expect(t, num_bytes_parsed == lengths[idx], fmt.tprintf("Expected length:%v; Got %v", lengths[idx], num_bytes_parsed))
      cmp := isequal_GroupBeginToken(&tok, &expected)
      // if !cmp {
      //   log.errorf(".index: %v == %v => %v\n",tok.index, expected.index, tok.index==expected.index)
      //   log.errorf(".mname: %v == %v => %v\n",tok.mname, expected.mname, tok.mname==expected.mname)
      //   log.errorf(".mname lhs: %v == nil => %v\n",tok.mname, tok.mname == nil)
      //   log.errorf(".mname rhs: %v == nil => %v\n",expected.mname, expected.mname == nil)
      // }
      tc.expect(t, cmp, fmt.tprintf("Pattern:\"%v\"; Expected:%v; Got:%v", pattern, expected, tok))
    }
  }
}


@(test)
test__parseSingleTokenFromString :: proc(t: ^testing.T) {
  using re
  {
    invalid_patterns := [?]string{"\\"}
    for pattern, idx in invalid_patterns {
      tok, num_bytes_parsed, ok := _parseSingleTokenFromString(pattern)
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
      "[a]",
      "[ab]",
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
      AssertionToken{.DOLLAR},
      AssertionToken{.CARET},
      QuantityToken{0, nil},
      QuantityToken{1, nil},
      QuantityToken{0, 1},
      SetToken{pos_shorthands = {.Flag_Dot}},
      AlternationToken{},
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
      tok, num_bytes_parsed, ok := _parseSingleTokenFromString(pattern)
      defer deleteToken(&tok)
      tc.expect(t, ok, fmt.tprintf("Pattern:\"%v\" Expected to be okay.", pattern))
      cmp := isequal_Token(&tok, &expected)
      tc.expect(t, cmp, fmt.tprintf("Pattern:\"%v\" Expected:%v Got:%v", pattern, expected, tok))
      tc.expect(t, len(pattern) == num_bytes_parsed, fmt.tprintf("Expected len(\"%v\")==%v  Got:%v", pattern, len(pattern), num_bytes_parsed))
    }
  }
}

@(test)
test_parseTokensFromString :: proc(t: ^testing.T) {
  using re
  if false {
    patterns := [?]string{"(?P<name>A)\\b.\\.+s?b*\n\\n\\\\"}
    expected_num_tokens := [?]int{2, 1, 3, 14, 14, 2, 3}
    flags := [?]RegexFlags{{}, {.IGNORECASE}}
    for pattern, idx in patterns {
      for flag in flags {
        toks, ok := parseTokensFromString(pattern, flag)
        defer deleteTokens(&toks)
        expected_num := expected_num_tokens[idx]
        tc.expect(t, ok, fmt.tprintf("Expected parse to be ok for pattern:\"%v\"", pattern))
        cmp := len(toks) == expected_num
        if !cmp {
          log.errorf("pattern: \"%v\" ok?% 5v Expected length:%v Got:%v", pattern, ok, expected_num, len(toks))
          for tok, idx in toks {
            log.errorf("% 3d: %v", idx, tok)
          }
        }
        tc.expect(t, cmp, fmt.tprintf("Expected %v tokens. Got %v", expected_num, len(toks)))
      }
    }
  }
  {
    invalid_patterns := [?]string{"(", "((", ")", "?", "*", "+", "{1,4}", "a++", "$+", "+"}
    for pattern, idx in invalid_patterns {
      toks, ok := parseTokensFromString(pattern)
      tc.expect(t, !ok, fmt.tprintf("Expected parse to be not ok for pattern \"%v\"", pattern))
      tc.expect(t, toks == nil, "Expected tokens to be nil")
    }
  }
  // test patterns requiring empties
  {
    patterns := [?]string{"(|)", "(a|)", "(|a)", "h{1,2}", "[a-b\\W]", "(?:h)", "()", "(((a)(b)(c)?))"}
    all_expected_tokens := [?][]Token {
      {
        GroupBeginToken{index = 0},
        ImplicitToken{.CONCATENATION},
        ImplicitToken{.EMPTY},
        AlternationToken{},
        ImplicitToken{.EMPTY},
        ImplicitToken{.CONCATENATION},
        GroupEndToken{index = 0},
      },
      {
        GroupBeginToken{index = 0},
        ImplicitToken{.CONCATENATION},
        LiteralToken{'a'},
        AlternationToken{},
        ImplicitToken{.EMPTY},
        ImplicitToken{.CONCATENATION},
        GroupEndToken{index = 0},
      },
      {
        GroupBeginToken{index = 0},
        ImplicitToken{.CONCATENATION},
        ImplicitToken{.EMPTY},
        AlternationToken{},
        LiteralToken{'a'},
        ImplicitToken{.CONCATENATION},
        GroupEndToken{index = 0},
      },
      {LiteralToken{'h'}, QuantityToken{1, 2}},
      {makeSetToken("ab", false, {}, {.Flag_W}, context.temp_allocator)},
      {GroupBeginToken{non_capturing = true}, ImplicitToken{.CONCATENATION}, LiteralToken{'h'}, ImplicitToken{.CONCATENATION}, GroupEndToken{}},
      {GroupBeginToken{index = 0}, ImplicitToken{.CONCATENATION}, GroupEndToken{}},
      {
        GroupBeginToken{index = 0},
        ImplicitToken{.CONCATENATION},// "(((a)(b)(c)?))", 
        GroupBeginToken{index = 1},
        ImplicitToken{.CONCATENATION},
        GroupBeginToken{index = 2},
        ImplicitToken{.CONCATENATION},
        LiteralToken{'a'},
        ImplicitToken{.CONCATENATION},
        GroupEndToken{index = 2},
        ImplicitToken{.CONCATENATION},
        GroupBeginToken{index = 3},
        ImplicitToken{.CONCATENATION},
        LiteralToken{'b'},
        ImplicitToken{.CONCATENATION},
        GroupEndToken{index = 3},
        ImplicitToken{.CONCATENATION},
        GroupBeginToken{index = 4},
        ImplicitToken{.CONCATENATION},
        LiteralToken{'c'},
        ImplicitToken{.CONCATENATION},
        GroupEndToken{index = 4},
        QuantityToken{0, 1},
        ImplicitToken{.CONCATENATION},
        GroupEndToken{index = 1},
        ImplicitToken{.CONCATENATION},
        GroupEndToken{index = 0},
      },
    }
    for pattern, idx in patterns {
      toks, ok := parseTokensFromString(pattern)
      defer deleteTokens(&toks)
      expected_tokens := all_expected_tokens[idx]
      tc.expect(t, ok, fmt.tprintf("Expected parse to be ok for pattern:\"%v\"", pattern))
      tc.expect(t, ok, fmt.tprintf("Infix tokens for pattern:\"%v\" is not equal to expected. Got:%v  Expected:%v", pattern, toks, expected_tokens))
      cmp := areTokenArraysEqual(toks[:], expected_tokens)
      tc.expect(t, cmp, fmt.tprintf("Infix tokens for pattern:\"%v\" is not equal to expected. Got:%v  Expected:%v", pattern, toks, expected_tokens))
      if !cmp {
        log.errorf("Pattern: \"%v\" ok?% 5v Expected length:%v Got:%v", pattern, ok, len(expected_tokens), len(toks))
        for idx in 0 ..< max(len(toks), len(expected_tokens)) {
          log.errorf("% 2d: ", idx)
          if idx < len(toks) {
            log.errorf("| got: %v", toks[idx])
          } else {
            log.errorf("| got: missing")
          }
          if idx < len(expected_tokens) {
            log.errorf("| exp: %v", expected_tokens[idx])
          } else {
            log.errorf("| exp: missing")
          }
        }
        log.errorf("\n")
      }
    }
  }
}
