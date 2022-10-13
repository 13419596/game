package re

import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"
import container_set "game:container/set"

SpecialTokenType :: enum {
  // Special tokens for use in the NFA
  HEAD, // beginning of sequence
  TAIL, // end of sequence
  CONCATENATION, // implicit
}

SpecialToken :: struct {
  op: SpecialTokenType,
}

OperationTokenType :: enum {
  ALTERNATION, // |
  // named as such because meaning should be end-of-entire-sequence or end-of-line
  // depending on the regex flags
  DOLLAR, // $,  
  CARET, // ^
}

OperationToken :: struct {
  op: OperationTokenType,
}

QuantityToken :: struct {
  lower: int,
  upper: Maybe(int),
}

SetToken :: struct {
  charset:        container_set.Set(rune),
  set_negated:    bool,
  pos_shorthands: bit_set[ShortHandClass],
  neg_shorthands: bit_set[ShortHandClass],
}

LiteralToken :: struct {
  value: rune,
}

GroupBeginToken :: struct {
  // () capturing
  // (?P<name>regex), named, capturing
  // (?:regex)	non-capturing
  index:         int,
  mname:         Maybe(string),
  non_capturing: bool,
}

GroupEndToken :: struct {
  index: int,
}


Token :: union {
  SpecialToken,
  OperationToken,
  GroupBeginToken,
  GroupEndToken,
  QuantityToken,
  SetToken,
  LiteralToken,
}

/////////////
// Delete

deleteSetToken :: proc(token: ^SetToken) {
  using container_set
  deleteSet(&token.charset)
}

deleteGroupBeginToken :: proc(token: ^GroupBeginToken) {
  if name, ok := token.mname.(string); ok {
    delete(name)
    token.mname = nil
  }
}

deleteToken :: proc(token: ^Token) {
  switch tok in token {
  case SpecialToken:
  case OperationToken:
  case GroupEndToken:
  case QuantityToken:
  case LiteralToken:
  // do nothing
  case GroupBeginToken:
    deleteGroupBeginToken(&tok)
  case SetToken:
    deleteSetToken(&tok)
  }
  token^ = nil
}

deleteTokens_dynamic :: proc(tokens: ^[dynamic]Token) {
  for _, idx in tokens {
    deleteToken(&tokens[idx])
  }
  clear(tokens)
  delete(tokens^)
  tokens^ = nil
}

deleteTokens_array :: proc(tokens: ^[]Token) {
  for _, idx in tokens {
    deleteToken(&tokens[idx])
    tokens[idx] = nil
  }
}

deleteTokens :: proc {
  deleteTokens_dynamic,
  deleteTokens_array,
}

/////////////
// clone

@(require_results)
copy_SetToken :: proc(token: ^SetToken, allocator := context.allocator) -> SetToken {
  using container_set
  out := SetToken {
    charset        = copy(&token.charset, allocator),
    set_negated    = token.set_negated,
    pos_shorthands = token.pos_shorthands,
    neg_shorthands = token.neg_shorthands,
  }
  return out
}

@(require_results)
copy_GroupBeginToken :: proc(token: ^GroupBeginToken, allocator := context.allocator) -> GroupBeginToken {
  using container_set
  mname_copy: Maybe(string) = nil
  if name, ok := token.mname.(string); ok {
    mname_copy = strings.clone(name, allocator)
  }
  out := GroupBeginToken {
    index         = token.index,
    mname         = mname_copy,
    non_capturing = token.non_capturing,
  }
  return out
}

@(require_results)
copy_Token :: proc(token: ^Token, allocator := context.allocator) -> Token {
  token := token
  switch tok in token {
  case SetToken:
    return copy_SetToken(&tok, allocator)
  case GroupBeginToken:
    return copy_GroupBeginToken(&tok, allocator)
  case GroupEndToken:
    return tok
  case SpecialToken:
    return tok
  case OperationToken:
    return tok
  case QuantityToken:
    return tok
  case LiteralToken:
    return tok
  }
  return token^
}

/////////////
// Is Equal

isequal_SetToken :: proc(lhs, rhs: ^SetToken) -> bool {
  return(
    (lhs.set_negated == rhs.set_negated) &&
    (lhs.pos_shorthands == rhs.pos_shorthands) &&
    (lhs.neg_shorthands == rhs.neg_shorthands) &&
    (container_set.isequal(&lhs.charset, &rhs.charset)) \
  )
}

isequal_GroupBeginToken :: proc(lhs, rhs: ^GroupBeginToken) -> bool {
  return (lhs.index == rhs.index) && (lhs.non_capturing == rhs.non_capturing) && (lhs.mname == nil && rhs.mname == nil) || (lhs.mname == rhs.mname)
}

isequal_Token :: proc(lhs, rhs: ^Token) -> bool {
  switch ltok in lhs {
  case SetToken:
    if rtok, ok := rhs.(SetToken); ok {
      return isequal_SetToken(&ltok, &rtok)
    }
  case GroupBeginToken:
    if rtok, ok := rhs.(GroupBeginToken); ok {
      return isequal_GroupBeginToken(&ltok, &rtok)
    }
  case SpecialToken:
    if rtok, ok := rhs.(SpecialToken); ok {
      return ltok == rtok
    }
  case OperationToken:
    if rtok, ok := rhs.(OperationToken); ok {
      return ltok == rtok
    }
  case GroupEndToken:
    if rtok, ok := rhs.(GroupEndToken); ok {
      return ltok == rtok
    }
  case LiteralToken:
    if rtok, ok := rhs.(LiteralToken); ok {
      return ltok == rtok
    }
  case QuantityToken:
    if rtok, ok := rhs.(QuantityToken); ok {
      return ltok == rtok
    }
  }
  return false
}

//////////////////////////////////////

@(require_results)
makeCaseInsensitiveLiteral :: proc(lit_token: ^LiteralToken, allocator := context.allocator) -> Token {
  // If literal token has a character that can be lower/upper then return a set token otherwise return the same
  using unicode
  using container_set
  rn := lit_token.value
  if !is_lower(rn) && !is_upper(lit_token.value) {
    return lit_token^
  }
  arr := [?]rune{to_lower(rn), to_upper(rn)}
  return SetToken{charset = fromArray(arr = arr[:], allocator = allocator)}
}

updateSetTokenCaseInsensitive :: proc(set_token: ^SetToken) {
  // it is expected that the number of characters in the set tokens 
  // will be less than the total of all characters compared, so expanding the
  // set token to include both pairs will be faster than changing case of all compared strings
  using container_set
  using unicode
  for k, _ in set_token.charset.set {
    add(&set_token.charset, to_lower(k))
    add(&set_token.charset, to_upper(k))
  }
}

doesSetTokenMatch :: proc(
  set_token: ^SetToken,
  curr_rune: rune,
  prev_rune: rune = {},
  at_beginning: bool = false,
  at_end: bool = false,
  flags: RegexFlags = {},
) -> bool {
  // ignores case-insensitive flag
  // it is assumed that set token has already been transformed to a case-insensitive version
  using container_set
  in_charset := contains(&set_token.charset, curr_rune)
  if in_charset {
    return !set_token.set_negated
  }
  if .Flag_Dot in set_token.pos_shorthands {
    return .DOTALL in flags ? true : curr_rune != '\n'
  }
  is_ascii := .ASCII in flags
  for shc in ShortHandClass {
    pos_f := shc in set_token.pos_shorthands
    neg_f := shc in set_token.neg_shorthands
    if pos_f == neg_f {
      if pos_f {
        // both flags present so either always matches or never
        return !set_token.set_negated
      } else {
        continue
      }
    }
    matches := matchesCharacterClass(
      curr_rune = curr_rune,
      prev_rune = prev_rune,
      sh_class = shc,
      ascii = is_ascii,
      at_beginning = at_beginning,
      at_end = at_beginning,
    )
    if (matches && pos_f) || (!matches && neg_f) {
      return !set_token.set_negated
    }
  }
  // therefore character not in set
  // so return set_negated value. 
  // regular/ not negated -> false
  // inverted / negated   -> true
  return set_token.set_negated
}
