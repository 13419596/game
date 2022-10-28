package argparse

import "core:fmt"
import "core:log"
import "core:os"
import "core:runtime"
import "core:strings"
import "core:path/filepath"
import "core:unicode/utf8"

import "game:trie"

_ArgumentFlagType :: enum {
  Invalid,
  Short,
  Long,
  Positional,
}

/////////////////////////////

_isPositionalFlag :: proc(flag: string, prefix: rune = _DEFAULT_PREFIX_RUNE) -> bool {
  using utf8
  r0 := rune_at_pos(flag, 0)
  out := ((r0 != prefix && r0 != RUNE_ERROR))
  return out
}

_isShortFlag :: proc(flag: string, prefix: rune = _DEFAULT_PREFIX_RUNE) -> bool {
  using utf8
  r0 := rune_at_pos(flag, 0)
  r1 := rune_at_pos(flag, 1)
  out := ((r0 == prefix) && (r1 != prefix && r1 != RUNE_ERROR))
  return out
}

_isLongFlag :: proc(flag: string, prefix: rune = _DEFAULT_PREFIX_RUNE) -> bool {
  using utf8
  r0 := rune_at_pos(flag, 0)
  r1 := rune_at_pos(flag, 1)
  r2 := rune_at_pos(flag, 2)
  out := ((r0 == prefix) && (r1 == prefix) && (r2 != prefix && r2 != RUNE_ERROR))
  return out
}

_getFlagType :: proc(flag: string, prefix := _DEFAULT_PREFIX_RUNE) -> _ArgumentFlagType {
  if _isShortFlag(flag, prefix) {
    return .Short
  } else if _isLongFlag(flag, prefix) {
    return .Long
  } else if _isPositionalFlag(flag, prefix) {
    return .Positional
  }
  return .Invalid
}

/////////////////////////////

_ShortFlagParts :: struct {
  arg:      string,
  prefix:   rune,
  flag:     string,
  trailing: string,
}

_getShortFlagParts :: proc(arg: string, prefix := _DEFAULT_PREFIX_RUNE) -> _ShortFlagParts {
  using utf8
  r0 := rune_at_pos(arg, 0)
  r1 := rune_at_pos(arg, 1)
  idx := rune_size(r0) + rune_size(r1)
  out := _ShortFlagParts {
    arg      = arg,
    prefix   = r0,
    flag     = arg[:idx],
    trailing = arg[idx:],
  }
  return out
}

/////////////////////////////

_cleanFlags :: proc(raw_flags: []string, prefix: rune = _DEFAULT_PREFIX_RUNE, allocator := context.allocator) -> []string {
  flags := make([dynamic]string, len(raw_flags), allocator)
  for raw_flag, idx in raw_flags {
    flags[idx] = _replaceRunes(raw_flag, {prefix}, prefix, allocator)
  }
  return flags[:]
}

/////////////////////////////

_getDestFromFlags :: proc(flags: []string, prefix: rune = _DEFAULT_PREFIX_RUNE) -> (out: string, ok: bool) {
  // Gets first long flag and strips prefix
  using strings
  out = ""
  ok = false
  if len(flags) <= 0 {
    log.errorf("Option strings is empty. Expected at least one flag string.")
    return
  }
  long_flag_index := -1
  for flag, idx in flags {
    if _isLongFlag(flag, prefix) {
      long_flag_index = idx
      break
    }
  }
  flag_index := long_flag_index >= 0 ? long_flag_index : 0
  flag := flags[flag_index]
  first_non_prefix_index := -1
  for rn, idx in flag {
    if rn != prefix {
      first_non_prefix_index = idx
      break
    }
  }
  if first_non_prefix_index == -1 {
    log.errorf("Could not determine first non-prefix index in flag:\"%v\"", flag)
    return
  }
  out = flag[first_non_prefix_index:]
  ok = true
  return
}

/////////////////////////////

_areFlagsOkay :: proc(flags: []string, prefix := _DEFAULT_PREFIX_RUNE) -> bool {
  if len(flags) <= 0 {
    log.errorf("Expected at least one flag.")
    return false
  }
  has_positional := false
  has_short_or_long := false
  ok := true
  for flag, idx in flags {
    opt_type := _getFlagType(flag, prefix)
    switch opt_type {
    case .Invalid:
      log.errorf("Invalid flag that is neither short, long, nor position flag. flags[%v]:\"%v\"", idx, flag)
      ok = false
    case .Positional:
      if has_short_or_long {
        log.errorf("Cannot mix positional and keyword flags in a single argument. flags[%v]:\"%v\"", idx, flag)
        ok = false
      } else if !has_positional {
        has_positional = true
        break
      } else {
        log.errorf("Only a single positional flag is allowed. flags[%v]:\"%v\"", idx, flag)
        ok = false
      }
      fallthrough
    case .Short:
      fallthrough
    case .Long:
      has_short_or_long = true
      if has_positional {
        log.errorf("Cannot mix positional and keyword flags in a single argument. flags[%v]:\"%v\"", idx, flag)
        ok = false
      }
    }
  }
  if has_positional && has_short_or_long {
    ok = false
  }
  return ok
}
