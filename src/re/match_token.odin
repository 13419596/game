package re

import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"
import container_set "game:container/set"

TokenOperation :: enum {
  CONCATENATION = 3, // IMPLICIT
  ALTERNATION   = 2, // |
  BEGINNING     = 1,
  END           = 0,
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
}

isequal_SetToken :: proc(lhs, rhs: ^SetToken) -> bool {
  return(
    (lhs.set_negated == rhs.set_negated) &&
    (lhs.pos_shorthands == rhs.pos_shorthands) &&
    (lhs.neg_shorthands == rhs.neg_shorthands) &&
    (container_set.isequal(&lhs.charset, &rhs.charset)) \
  )
}

isequal_GroupBeginToken :: proc(lhs, rhs: ^GroupBeginToken) -> bool {
  return(
    (lhs.index == rhs.index) &&
    (lhs.non_capturing == rhs.non_capturing) &&
    (lhs.mname== nil && rhs.mname==nil) || (lhs.mname==rhs.mname)
  )
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
      return ltok==rtok
    }
  case GroupEndToken:
    if rtok, ok := rhs.(GroupEndToken); ok {
      return ltok==rtok
    }
  case LiteralToken:
    if rtok, ok := rhs.(LiteralToken); ok {
      return ltok==rtok
    }
  case QuantityToken:
    if rtok, ok := rhs.(QuantityToken); ok {
      return ltok==rtok
    }
  }
  return false
}

parseLatterQuantityToken :: proc(unparsed_runes: string) -> (out: Token, bytes_parsed: int, ok: bool) {
  // parses starting after the first {
  ok = true
  defer if !ok { bytes_parsed = 0 }
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

parseLatterEscapedRune :: proc(rn: rune) -> (out: Token, bytes_parsed: int, ok: bool) {
  bytes_parsed = 1
  ok = true
  defer if !ok { bytes_parsed = 0 }
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


parseLatterSetToken :: proc(unparsed_runes: string, allocator:=context.allocator) -> (out: SetToken, bytes_parsed: int, ok: bool) {
  // starts parsing from first [
  using container_set
  ok = true
  defer if !ok { bytes_parsed = 0 }
  bytes_parsed = 0
  out.set_negated = false
  out.charset = makeSet(T=rune, allocator=allocator)
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

parseLatterGroupBeginToken :: proc(unparsed_runes: string, allocator:=context.allocator) -> (out: GroupBeginToken, bytes_parsed: int, ok: bool) {
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
  bytes_parsed += name_width
  out.mname = strings.clone(unparsed_runes[name_start_index:name_start_index + name_width], allocator)
  return
}

makeTokenFromString :: proc(unparsed_runes: string, allocator:=context.allocator) -> (out: Token, bytes_parsed: int, ok: bool) {
  using container_set
  defer if !ok { bytes_parsed = 0 }
  bytes_parsed = 0
  group_bytes_parsed := 0
  ok = true
  for rn in unparsed_runes {
    bytes_parsed += utf8.rune_size(rn)
    switch rn {
    case '[':
      out, group_bytes_parsed, ok = parseLatterSetToken(unparsed_runes[bytes_parsed:], allocator)
      bytes_parsed += group_bytes_parsed
      return
    case '\\':
      if len(unparsed_runes) <= bytes_parsed {
        // expects more to parse, but at end of string
        ok = false
    bytes_parsed = 0
        return
      }
      out, group_bytes_parsed, ok = parseLatterEscapedRune(rune(unparsed_runes[bytes_parsed]))
      bytes_parsed += group_bytes_parsed
      return
    case '(':
      out, group_bytes_parsed, ok = parseLatterGroupBeginToken(unparsed_runes[bytes_parsed:], allocator)
      bytes_parsed += group_bytes_parsed
      return
    case '{':
      out, group_bytes_parsed, ok = parseLatterQuantityToken(unparsed_runes[bytes_parsed:])
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


//////////////////////////////////////

// doesTokenMatch :: proc(
//   match_token: ^LiteralToken,
//   token: rune,
//   prev_token: rune = {},
//   at_beginning: bool = false,
//   at_end: bool = false,
//   flags: RegexFlags = {},
// ) -> bool {
//   using container_set
//   out := false
//   switch value in &match_token.value {
//   case rune:
//     if .IGNORECASE in flags {
//       out = value == unicode.to_lower(token)
//     } else {
//       out = value == token
//     }
//   case Set(rune):
//     if .IGNORECASE in flags {
//       out = contains(&value, unicode.to_lower(token))
//     } else {
//       out = contains(&value, token)
//     }
//   case ShortHandClass:
//     if value == .Flag_Dot && .DOTALL in flags {
//       out = true
//     } else {
//       out = matchesCharacterClass(token = token, prev_token = prev_token, sh_class = value, at_beginning = at_beginning, at_end = at_end)
//     }
//   }
//   return match_token.is_negated ? !out : out
// }
// 
