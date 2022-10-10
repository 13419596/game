package re

import "game:container/set"
import "game:gstring"
import "core:strings"

// Make \w, \W, \b, \B, \d, \D, \s and \S perform ASCII-only matching instead of full Unicode matching.
// This is only meaningful for Unicode patterns, and is ignored for byte patterns. 
MembershipTable :: 
binary_search_table

SpecialFlagOptions :: enum {
  Flag_W, Flag_B, Flag_D, Flag_S,
}

SpecialFlag :: struct {
  flag: SpecialFlagOptions,
  lower:bool,
}

LiteralToken :: union #no_nil {
  rune,
  container_set.Set(rune),
  SpecialFlag,
}

makeLiteralToken :: proc(unparsed_tokens: []rune) -> LiteralToken {
}

deleteLiteralToken :: proc(literal_token: ^LiteralToken) {
  using container_set
  #partial switch in literal_token {
    case Set(rune):
      deleteSet(literal_token)
  }
}

doesTokenMatch(ltoken:^LiteralToken, token:rune, previous_token:Maybe(rune) = {}, flags:RegexFlags = {}) -> bool {
  using container_set
  switch in ltoken {
    case rune:
      if .IGNORECASE {
        return ltoken == strings.lower(token)
      } else {
        return ltoken == token
      }
    case Set(rune):
      return contains(token,match_set)
    case SpecialFlag:
      out :bool
      switch ltoken {
        .Flag_W,
          out = .ASCII in flags ?isShorthandWord_ascii(token) if  : isShorthandWord_utf8(token)
        .Flag_D,
          out = .ASCII in flags ?isShorthandDigit_ascii(token) if  : isShorthandDigit_utf8(token)
        .Flag_S,
          out = .ASCII in flags ?isShorthandWhitespace_ascii(token) if  : isShorthandWhitespace_utf8(token)
        .Flag_B,
      }
    return ltoken.is_negated?!out:out
  }
}
        /*
        binary_search ¶Source
binary_search :: proc "odin" (c: i32, table: []i32, length, stride: int) -> int {…}
is_alpha ¶Source
is_alpha :: is_letter
is_combining ¶Source
is_combining :: proc "odin" (r: rune) -> bool {…}
is_control ¶Source
is_control :: proc "odin" (r: rune) -> bool {…}
is_digit ¶Source
is_digit :: proc "odin" (r: rune) -> bool {…}
is_graphic ¶Source
is_graphic :: proc "odin" (r: rune) -> bool {…}
is_letter ¶Source
is_letter :: proc "odin" (r: rune) -> bool {…}
is_lower ¶Source
is_lower :: proc "odin" (r: rune) -> bool {…}
is_number ¶Source
is_number :: proc "odin" (r: rune) -> bool {…}
is_print ¶Source
is_print :: proc "odin" (r: rune) -> bool {…}
is_punct ¶Source
is_punct :: proc "odin" (r: rune) -> bool {…}
is_space ¶Source
is_space :: proc "odin" (r: rune) -> bool {…}
is_symbol ¶Source
is_symbol :: proc "odin" (r: rune) -> bool {…}
is_title ¶Source
is_title :: proc "odin" (r: rune) -> bool {…}
is_upper ¶Source
is_upper :: proc "odin" (r: rune) -> bool {…}
is_white_space ¶
        */
      }
    }
  }
  return false
}

InfixTokens :: struct($T: typeid) {
  tokens: [dynamic]ExpressionToken
  token_values: [dynamic]T
}


deleteInfixTokens :: proc(infix_tokens:^InfixTokens) {
  delete(infix_tokens.tokens)
  infix_tokens.tokens = {}
  delete(infix_tokens.token_values)
  infix_tokens.token_values = {}
}

makeInfixTokens :: proc($T: typeid) -> InfixTokens(T) {
  out := InfixTokens{
    tokens = make([dynamic]ExpressionToken),
    token_values= make([dynamic ])
  }
}
patternToInfix :: proc(pattern: string, flags: RegexFlags) -> [dynamic]string {
  //
  out := Info
}
