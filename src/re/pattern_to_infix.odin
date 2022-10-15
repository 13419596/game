package re

import "core:fmt"
import "core:log"
import "core:strconv"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"
import container_set "game:container/set"

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
      out = OperationToken {
        op = .CARET,
      }
      return
    case '$':
      out = OperationToken {
        op = .DOLLAR,
      }
      return
    case '|':
      out = OperationToken {
        op = .ALTERNATION,
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
parseTokensFromString :: proc(pattern: string, flags: RegexFlags = {}, allocator := context.allocator) -> (out: [dynamic]Token, ok: bool) {
  out = make([dynamic]Token, allocator)
  ok = true
  pout := &out
  // TODO handle other regex flags
  case_insensitive := .IGNORECASE in flags
  prev_token: Token = nil
  head_idx := 0
  group_index := 0
  group_index_stack := make([dynamic]int, context.temp_allocator)
  defer delete(group_index_stack)
  loop: for head_idx < len(pattern) {
    token, bytes_parsed, token_ok := parseSingleTokenFromString(pattern[head_idx:])
    if !token_ok {
      log.warnf("Unable to parse token at position:%v. pattern: \"%v\"", head_idx, pattern)
      ok = false
      break loop
    }

    if case_insensitive {
      switch tok in &token {
      case LiteralToken:
        token = makeCaseInsensitiveLiteral(&tok, allocator)
      case SetToken:
        updateSetTokenCaseInsensitive(&tok)
      case SpecialToken:
      case OperationToken:
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
        log.warnf("Extra group end ')' at index:%v. pattern: \"%v\"", head_idx, pattern)
        ok = false
        break loop
      }
      tok.index = pop_group_idx
    case SpecialToken:
    case OperationToken:
    case QuantityToken:
    case SetToken:
    case LiteralToken:
    // do nothing
    }

    // Check that quantifier can't quantifier, group begin, or op
    if qtok, qok := token.(QuantityToken); qok {
      // current is qtok
      qtok_is_01 := qtok == QuantityToken{0, 1}
      if prev_token == nil {
        // cannot have quantifier right at the beginning, 
        log.warnf("Nothing to repeat at position:%v. Quantifiers are not allowed at the beginning of a pattern. pattern: \"%v\"", head_idx, pattern)
        ok = false
        break loop
      } else {
        switch in prev_token {
        case QuantityToken:
          if qtok_is_01 {
            // TODO support lazy
            log.warnf("Lazy quantifier at position:%v is not currently supported. pattern: \"%v\"", head_idx, pattern)
          } else {
            log.warnf("Nothing to repeat at position:%v. pattern: \"%v\"", head_idx, pattern)
          }
          ok = false
          break loop
        case OperationToken:
          log.warnf("Nothing to repeat at position:%v. pattern: \"%v\"", head_idx, pattern)
          ok = false
          break loop
        case GroupBeginToken:
          log.warnf("Nothing to repeat at position:%v. Quantifier cannot appear at beginning of group. pattern: \"%v\"", head_idx, pattern)
          ok = false
          break loop
        case SpecialToken:
        case LiteralToken:
        case SetToken:
        case GroupEndToken:
        }
      }
    }
    head_idx += bytes_parsed
    append(&out, token)
    prev_token = token
  }
  if len(group_index_stack) != 0 {
    log.warnf("Too many group beginnings and not enough ends. pattern: \"%v\"", pattern)
    ok = false
  }
  if !ok {
    deleteTokens(&out)
  }
  return
}
