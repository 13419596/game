// Must be run with `-collection:tests=` flag
package test_re

import "core:fmt"
import "core:testing"
import re "game:re"
import tc "tests:common"

@(test)
test_shorthand :: proc(t: ^testing.T) {
  test_isShorthandDigit(t)
  test_isShorthandWord(t)
  test_isShorthandWhitespace(t)
  test_isShorthandBoundary(t)
}

@(test)
test_isShorthandDigit :: proc(t: ^testing.T) {
  using re
  for rn in "0123456789" {
    tc.expect(t, isShorthandDigit_ascii(rn))
    tc.expect(t, isShorthandDigit_utf8(rn))
    tc.expect(t, isShorthandDigit(rn, true))
    tc.expect(t, isShorthandDigit(rn, false))
    tc.expect(t, matchesCharacterClass(rn, .Flag_D, {}, false))
    tc.expect(t, matchesCharacterClass(rn, .Flag_D, {}, true))
  }
  for rn in "ab_ !" {
    tc.expect(t, !isShorthandDigit_ascii(rn))
    tc.expect(t, !isShorthandDigit_utf8(rn))
    tc.expect(t, !isShorthandDigit(rn, true))
    tc.expect(t, !isShorthandDigit(rn, false))
    tc.expect(t, !matchesCharacterClass(rn, .Flag_D, {}, false))
    tc.expect(t, !matchesCharacterClass(rn, .Flag_D, {}, true))
  }
}

@(test)
test_isShorthandWord :: proc(t: ^testing.T) {
  using re
  for rn in "0123456789ab_" {
    tc.expect(t, isShorthandWord_ascii(rn))
    tc.expect(t, isShorthandWord_utf8(rn))
    tc.expect(t, isShorthandWord(rn, true))
    tc.expect(t, isShorthandWord(rn, false))
    tc.expect(t, matchesCharacterClass(rn, .Flag_W, {}, false))
    tc.expect(t, matchesCharacterClass(rn, .Flag_W, {}, true))
  }
  for rn in " !" {
    tc.expect(t, !isShorthandWord_ascii(rn))
    tc.expect(t, !isShorthandWord_utf8(rn))
    tc.expect(t, !isShorthandWord(rn, true))
    tc.expect(t, !isShorthandWord(rn, false))
    tc.expect(t, !matchesCharacterClass(rn, .Flag_W, {}, false))
    tc.expect(t, !matchesCharacterClass(rn, .Flag_W, {}, true))
  }
}


@(test)
test_isShorthandWhitespace :: proc(t: ^testing.T) {
  using re
  for rn in "a" {
    tc.expect(t, !isShorthandWhitespace_ascii(rn))
    tc.expect(t, !isShorthandWhitespace_utf8(rn))
    tc.expect(t, !isShorthandWhitespace(rn, true))
    tc.expect(t, !isShorthandWhitespace(rn, false))
    tc.expect(t, !matchesCharacterClass(rn, .Flag_S, {}, false))
    tc.expect(t, !matchesCharacterClass(rn, .Flag_S, {}, true))
  }
  for rn in " \n\t\v" {
    tc.expect(t, isShorthandWhitespace_ascii(rn))
    tc.expect(t, isShorthandWhitespace_utf8(rn))
    tc.expect(t, isShorthandWhitespace(rn, true))
    tc.expect(t, isShorthandWhitespace(rn, false))
    tc.expect(t, matchesCharacterClass(rn, .Flag_S, {}, false))
    tc.expect(t, matchesCharacterClass(rn, .Flag_S, {}, true))
  }
}

@(test)
test_isShorthandBoundary :: proc(t: ^testing.T) {
  using re
  tc.expect(t, matchesCharacterClass({}, .Flag_B, {}, false, true, false))
  tc.expect(t, matchesCharacterClass({}, .Flag_B, {}, false, false, true))
  tc.expect(t, matchesCharacterClass({}, .Flag_B, {}, true, true, false))
  tc.expect(t, matchesCharacterClass({}, .Flag_B, {}, true, false, true))
  {
    prev_rn := 'a'
    for rn in "0123456789ab_" {
      tc.expect(t, !matchesCharacterClass(rn, .Flag_B, prev_rn, false, false, false))
      tc.expect(t, !matchesCharacterClass(rn, .Flag_B, prev_rn, true, false, false))
    }
    for rn in " !*\n" {
      tc.expect(t, matchesCharacterClass(rn, .Flag_B, prev_rn, false, false, false))
      tc.expect(t, matchesCharacterClass(rn, .Flag_B, prev_rn, true, false, false))
    }
  }
  {
    prev_rn := ' '
    for rn in "0123456789ab_" {
      tc.expect(t, matchesCharacterClass(rn, .Flag_B, prev_rn, false, false, false))
      tc.expect(t, matchesCharacterClass(rn, .Flag_B, prev_rn, true, false, false))
    }
    for rn in " !*\n" {
      tc.expect(t, !matchesCharacterClass(rn, .Flag_B, prev_rn, false, false, false))
      tc.expect(t, !matchesCharacterClass(rn, .Flag_B, prev_rn, true, false, false))
    }
  }
}
