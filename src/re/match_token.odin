package re

import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"
import container_set "game:container/set"

TokenOperation :: enum {
  CONCATENATION = 4, // IMPLICIT
  ALTERNATION   = 3, // |
  END           = 2, // $
  BEGINNING     = 1, // ^
}

ZeroWidthToken :: struct {
  op: TokenOperation,
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
  ZeroWidthToken,
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
  case ZeroWidthToken:
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
copy_Token :: proc(token: ^Token) -> Token {
  token := token
  switch tok in token {
  case SetToken:
    return copy_SetToken(&tok)
  case GroupBeginToken:
    return copy_GroupBeginToken(&tok)
  case GroupEndToken:
    return tok
  case ZeroWidthToken:
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
  case ZeroWidthToken:
    if rtok, ok := rhs.(ZeroWidthToken); ok {
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

_parseLatterQuantityToken :: proc(unparsed_runes: string) -> (out: Token, bytes_parsed: int, ok: bool) {
  // parses starting after the first {
  ok = true
  defer if !ok {bytes_parsed = 0}
  if len(unparsed_runes) <= bytes_parsed {
    // just a "{" so a literal {
    out = LiteralToken {
      value = '{',
    }
    return
  } else if unparsed_runes[bytes_parsed] == '}' {
    // "{}" so a literal {
    out = LiteralToken {
      value = '{',
    }
    return
  } else if unparsed_runes[bytes_parsed] == ',' {
    // "{," then just a literal {
    // "{,}" -> [0,0]
    // "{,#" then just a literal {
    // {,nan} then just a literal {
    // {,#} => [0,#]
    if len(unparsed_runes) <= bytes_parsed {
      // just "{," so just a literal {
      out = LiteralToken {
        value = '{',
      }
      return
    }
    bytes_parsed += 1 // ,
    if len(unparsed_runes) >= bytes_parsed + 1 && unparsed_runes[bytes_parsed] == '}' {
      // "{,}" -> [0,0]
      bytes_parsed += 1 // }
      out = QuantityToken{0, 0}
      return
    }
    upper_bytes_parsed := 0
    upper, upper_ok := parseUnprefixedInt(unparsed_runes[bytes_parsed:], &upper_bytes_parsed)
    if !upper_ok ||
       upper_bytes_parsed == 0 ||
       len(unparsed_runes) == (bytes_parsed + upper_bytes_parsed) ||
       unparsed_runes[bytes_parsed + upper_bytes_parsed] != '}' {
      // {,nan} then just a literal {
      // "{,#" then just a literal {
      bytes_parsed = 0
      out = LiteralToken {
        value = '{',
      }
      return
    }
    bytes_parsed += upper_bytes_parsed + 1 // #}
    out = QuantityToken {
      lower = 0,
      upper = upper,
    }
    return
  }
  lower_bytes_parsed := 0
  lower, lower_ok := parseUnprefixedInt(unparsed_runes[bytes_parsed:], &lower_bytes_parsed)
  if !lower_ok || lower_bytes_parsed == 0 || (len(unparsed_runes) <= (lower_bytes_parsed + bytes_parsed)) {
    // {nan -> just a literal {
    // only "{#"
    out = LiteralToken {
      value = '{',
    }
    return
  } else if unparsed_runes[bytes_parsed + lower_bytes_parsed] == '}' {
    // [lower,lower] just a single number
    bytes_parsed += lower_bytes_parsed + 1 // #}
    out = QuantityToken {
      lower = lower,
      upper = lower,
    }
    return
  } else if unparsed_runes[bytes_parsed + lower_bytes_parsed] != ',' {
    // "{#[^},]"
    out = LiteralToken {
      value = '{',
    }
    return
  }
  bytes_parsed += lower_bytes_parsed + 1 // #,
  if len(unparsed_runes) <= bytes_parsed {
    // only "{#,"
    bytes_parsed = 0
    out = LiteralToken {
      value = '{',
    }
    return
  } else if unparsed_runes[bytes_parsed] == '}' {
    // lower+
    bytes_parsed += 1
    out = QuantityToken {
      lower = lower,
    }
    return
  }
  upper_bytes_parsed := 0
  upper, upper_ok := parseUnprefixedInt(unparsed_runes[bytes_parsed:], &upper_bytes_parsed)
  if !upper_ok || upper_bytes_parsed == 0 {
    // {#,nan or only "{#,"
    bytes_parsed = 0
    out = LiteralToken {
      value = '{',
    }
    return
  } else if upper < lower {
    ok = false
    bytes_parsed = 0
    return
  }
  // [lower, upper]
  bytes_parsed += upper_bytes_parsed + 1 // #}
  out = QuantityToken {
    lower = lower,
    upper = upper,
  }
  return
}

_parseLatterEscapedRune :: proc(rn: rune) -> (out: Token, bytes_parsed: int, ok: bool) {
  bytes_parsed = 1
  ok = true
  defer if !ok {bytes_parsed = 0}
  lower_rn := unicode.to_lower(rn)
  is_negated := rn != lower_rn // upper are negated
  switch rn {
  ////////////
  // Character classes
  case 's', 'S':
    if is_negated {
      out = SetToken {
        neg_shorthands = {ShortHandClass.Flag_S},
      }
    } else {
      out = SetToken {
        pos_shorthands = {ShortHandClass.Flag_S},
      }
    }
    return
  case 'w', 'W':
    if is_negated {
      out = SetToken {
        neg_shorthands = {ShortHandClass.Flag_W},
      }
    } else {
      out = SetToken {
        pos_shorthands = {ShortHandClass.Flag_W},
      }
    }
    return
  case 'd', 'D':
    if is_negated {
      out = SetToken {
        neg_shorthands = {ShortHandClass.Flag_D},
      }
    } else {
      out = SetToken {
        pos_shorthands = {ShortHandClass.Flag_D},
      }
    }
    return
  case 'b', 'B':
    if is_negated {
      out = SetToken {
        neg_shorthands = {ShortHandClass.Flag_B},
      }
    } else {
      out = SetToken {
        pos_shorthands = {ShortHandClass.Flag_B},
      }
    }
    return
  ////////////
  // \n, \t, \v
  case 'n':
    out = LiteralToken {
      value = rune('\n'),
    }
    return
  case 't':
    out = LiteralToken {
      value = rune('\t'),
    }
    return
  case 'v':
    out = LiteralToken {
      value = rune('\v'),
    }
    return
  /////////////
  // Meta chars
  case '[', ']', '\\', '(', ')', '{', '}', '^', '$', '|', '?', '*', '+', '.':
    out = LiteralToken {
      value = rn,
    }
    return
  }
  ok = false
  bytes_parsed = 0
  return
}

@(require_results)
_parseLatterSetToken :: proc(unparsed_runes: string, allocator := context.allocator) -> (out: SetToken, bytes_parsed: int, ok: bool) {
  // starts parsing from first [
  using container_set
  ok = true
  defer if !ok {bytes_parsed = 0}
  bytes_parsed = 0
  out.set_negated = false
  out.charset = makeSet(T = rune, cap = 1, allocator = allocator)
  pos_shorthands: bit_set[ShortHandClass] = {}
  neg_shorthands: bit_set[ShortHandClass] = {}
  if len(unparsed_runes) <= bytes_parsed || unparsed_runes[bytes_parsed] == ']' {
    ok = false
    bytes_parsed = 0
    return
  } else if unparsed_runes[bytes_parsed] == '^' {
    bytes_parsed += 1
    out.set_negated = true
  }
  started_escape := false
  started_range := false
  reached_end := false
  prev_rune_was_char_class := false
  prev_rune: Maybe(rune) = nil
  end_idx := 0
  loop: for rn, idx in unparsed_runes[bytes_parsed:] {
    end_idx = idx
    switch rn {
    case '-':
      if prn, ok := prev_rune.(rune); ok {
        if started_range {
          // '-' hyphen is the end of a range; odd but valid
          if u32(rn) < u32(prn) {
            // range is invalid
            ok = false
            bytes_parsed = 0
            return
          }
          for v := u32(prn); v <= u32(rn); v += 1 {
            add(&out.charset, rune(v))
          }
          prev_rune = nil
        } else {
          started_range = true
        }
      } else {
        // at beginning "[- or after a range "[a-z-
        add(&out.charset, '-')
        prev_rune = '-'
      }
    case '\\':
      if started_escape {
        if rn == '\\' {
          prev_rune = '\\'
          started_escape = false
          add(&out.charset, '\\')
        } else {
          // not sure what to do here
        }
      } else {
        started_escape = true
      }
    case:
      if started_escape {
        prev_rune = nil
        switch rn {
        case '[':
          add(&out.charset, '[')
          prev_rune = '['
        case ']':
          add(&out.charset, ']')
          prev_rune = ']'
        case '\\':
          add(&out.charset, '\\')
          prev_rune = '\\'
        case 'n':
          add(&out.charset, '\n')
          prev_rune = '\n'
        case 't':
          add(&out.charset, '\t')
          prev_rune = '\t'
        case 'v':
          add(&out.charset, '\v')
          prev_rune = '\v'
        case 'D':
          neg_shorthands += {.Flag_D}
        case 'W':
          neg_shorthands += {.Flag_W}
        case 'S':
          neg_shorthands += {.Flag_S}
        case 'd':
          pos_shorthands += {.Flag_D}
        case 'w':
          pos_shorthands += {.Flag_W}
        case 's':
          pos_shorthands += {.Flag_S}
        case '.':
          add(&out.charset, '.') // just add a regular '.'
          prev_rune = '.'
        case 'b':
          // not a flag, add a literal \b
          add(&out.charset, '\b')
          prev_rune = '\b'
        case:
          // invalid escape
          ok = false
          bytes_parsed = 0
          return
        }
        started_escape = false
      } else if rn == ']' {
        reached_end = true
        if prn, ok := prev_rune.(rune); ok {
          add(&out.charset, prn)
        }
        prev_rune = rn
        break loop
      } else if started_range {
        // end of range
        if prn, ok := prev_rune.(rune); ok {
          if u32(rn) < u32(prn) {
            // range is invalid
            ok = false
            bytes_parsed = 0
            return
          }
          for v := u32(prn); v <= u32(rn); v += 1 {
            add(&out.charset, rune(v))
          }
          prev_rune = nil
        } else {
          // no previous rune / character class, but started range - invalid state
          ok = false
          bytes_parsed = 0
          return
        }
        started_range = false
      } else {
        if prn, ok := prev_rune.(rune); ok {
          add(&out.charset, prn)
        }
        prev_rune = rn
      }
    }
  }
  if !reached_end || started_escape {
    ok = false
    bytes_parsed = 0
    return
  }
  if started_range {
    // hyphen at the end
    add(&out.charset, '-')
  }
  bytes_parsed += (end_idx + 1)
  out.pos_shorthands = out.set_negated ? neg_shorthands : pos_shorthands
  out.neg_shorthands = out.set_negated ? pos_shorthands : neg_shorthands
  return
}

@(require_results)
_parseLatterGroupBeginToken :: proc(unparsed_runes: string, allocator := context.allocator) -> (out: GroupBeginToken, bytes_parsed: int, ok: bool) {
  // starts parsing after first (
  bytes_parsed = 0
  ok = true
  if len(unparsed_runes) == 0 {
    // no more to parse
    return
  } else if unparsed_runes[bytes_parsed] != '?' {
    // regular group, do nothing special
    return
  }
  bytes_parsed += 1
  // (?:regex)
  if len(unparsed_runes) <= bytes_parsed {
    // no more to parse, but expects more
    ok = false
    bytes_parsed = 0
    return
  } else if unparsed_runes[bytes_parsed] == ':' {
    out.non_capturing = true
    bytes_parsed += 1
    return
  } else if unparsed_runes[bytes_parsed] != 'P' {
    ok = false
    bytes_parsed = 0
    return
  }
  bytes_parsed += 1
  if len(unparsed_runes) <= bytes_parsed {
    // no more to parse, but expects more
    ok = false
    bytes_parsed = 0
    return
  } else if unparsed_runes[bytes_parsed] != '<' {
    ok = false
    bytes_parsed = 0
    return
  }
  bytes_parsed += 1
  name_start_index := bytes_parsed
  name_width := 0
  loop: for rn, idx in unparsed_runes[bytes_parsed:] {
    name_width = idx
    if rn == '>' {
      // end of name
      break loop
    } else if !isShorthandWord_utf8(rn) {
      // only word chararcters allowed in name
      ok = false
      bytes_parsed = 0
      return
    }
  }
  if name_width == 0 {
    // zero length name - invalid
    ok = false
    bytes_parsed = 0
    return
  }
  bytes_parsed += name_width + 1 // name + >
  out.mname = strings.clone(unparsed_runes[name_start_index:name_start_index + name_width], allocator)
  return
}

@(require_results)
parseSingleTokenFromString :: proc(unparsed_runes: string, allocator := context.allocator) -> (out: Token, bytes_parsed: int, ok: bool) {
  using container_set
  defer if !ok {bytes_parsed = 0}
  bytes_parsed = 0
  group_bytes_parsed := 0
  ok = true
  for rn in unparsed_runes {
    bytes_parsed += utf8.rune_size(rn)
    switch rn {
    case '[':
      out, group_bytes_parsed, ok = _parseLatterSetToken(unparsed_runes[bytes_parsed:], allocator)
      bytes_parsed += group_bytes_parsed
      return
    case '\\':
      if len(unparsed_runes) <= bytes_parsed {
        // expects more to parse, but at end of string
        ok = false
        bytes_parsed = 0
        return
      }
      out, group_bytes_parsed, ok = _parseLatterEscapedRune(rune(unparsed_runes[bytes_parsed]))
      bytes_parsed += group_bytes_parsed
      return
    case '(':
      out, group_bytes_parsed, ok = _parseLatterGroupBeginToken(unparsed_runes[bytes_parsed:], allocator)
      bytes_parsed += group_bytes_parsed
      return
    case '{':
      out, group_bytes_parsed, ok = _parseLatterQuantityToken(unparsed_runes[bytes_parsed:])
      bytes_parsed += group_bytes_parsed
      return

    // Meta characters
    case ')':
      out = GroupEndToken{}
      return
    case '^':
      out = ZeroWidthToken {
        op = TokenOperation.BEGINNING,
      }
      return
    case '$':
      out = ZeroWidthToken {
        op = TokenOperation.END,
      }
      return
    case '|':
      out = ZeroWidthToken {
        op = TokenOperation.ALTERNATION,
      }
      return
    case '?':
      out = QuantityToken {
        lower = 0,
        upper = 1,
      }
      return
    case '*':
      out = QuantityToken {
        lower = 0,
      }
      return
    case '+':
      out = QuantityToken {
        lower = 1,
      }
      return
    case '.':
      out = SetToken {
        pos_shorthands = {ShortHandClass.Flag_Dot},
      }
      return
    case:
      // just a plain literal
      out = LiteralToken {
        value = rn,
      }
      return
    }
    ok = false
    bytes_parsed = 0
    return
  }
  ok = false
  bytes_parsed = 0
  return
}

@(require_results)
parseTokensFromString :: proc(s: string, flags: RegexFlags = {}, allocator := context.allocator) -> (out: [dynamic]Token, ok: bool) {
  out = make([dynamic]Token, allocator)
  ok = true
  pout := &out
  // TODO handle other regex flags
  case_insensitive := .IGNORECASE in flags
  prev_token_is_quantifier := true // cannot add two quantifiers in a row
  head_idx := 0
  group_index := 0
  group_index_stack := make([dynamic]int, context.temp_allocator)
  defer delete(group_index_stack)
  loop: for head_idx < len(s) {
    token, bytes_parsed, token_ok := parseSingleTokenFromString(s[head_idx:])
    if !token_ok {
      ok = false
      return
    }
    head_idx += bytes_parsed

    if case_insensitive {
      switch tok in &token {
      case LiteralToken:
        token = makeCaseInsensitiveLiteral(&tok, allocator)
      case SetToken:
        updateSetTokenCaseInsensitive(&tok)
      case ZeroWidthToken:
      case QuantityToken:
      case GroupBeginToken:
      case GroupEndToken:
      // do nothing
      }
    }

    // Set Grouping Indices
    switch tok in &token {
    case GroupBeginToken:
      tok.index = group_index
      append(&group_index_stack, group_index)
      group_index += 1
    case GroupEndToken:
      pop_group_idx, pop_ok := pop_safe(&group_index_stack)
      if !pop_ok {
        // unbalanced levels
        ok = false
        break loop
      }
      tok.index = pop_group_idx
    case ZeroWidthToken:
    case QuantityToken:
    case SetToken:
    case LiteralToken:
    // do nothing
    }

    // Check that quantifier doesn't follow quantifier
    if _, q_ok := token.(QuantityToken); q_ok {
      if prev_token_is_quantifier {
        ok = false
      }
      prev_token_is_quantifier = true
    } else {
      prev_token_is_quantifier = false
    }
    append(&out, token)
  }
  if len(group_index_stack) != 0 {
    // unbalanced
    ok = false
  }
  if !ok {
    deleteTokens(&out)
  }
  return
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
