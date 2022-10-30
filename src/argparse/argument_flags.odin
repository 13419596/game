package argparse

import "core:fmt"
import "core:log"
import "core:os"
import "core:runtime"
import "core:strings"
import "core:path/filepath"

import "game:trie"


_ArgumentFlagType :: enum {
  Invalid,
  Short,
  Long,
  Positional,
}

/////////////////////////////

_isPositionalFlag :: proc(flag: string, prefix: rune = _DEFAULT_PREFIX_RUNE) -> bool {
  rn_idx := 0
  for rn in flag {
    return rn != prefix
  }
  return false
}

_isShortFlag :: proc(flag: string, prefix: rune = _DEFAULT_PREFIX_RUNE) -> bool {
  rn_idx := 0
  for rn in flag {
    switch rn_idx {
    case 0:
      if rn != prefix {
        return false
      }
    case 1:
      return rn != prefix
    }
    rn_idx += 1
  }
  return false
}

_isLongFlag :: proc(flag: string, prefix: rune = _DEFAULT_PREFIX_RUNE) -> bool {
  rn_idx := 0
  for rn in flag {
    switch rn_idx {
    case 0:
      if rn != prefix {
        return false
      }
    case 1:
      if rn != prefix {
        return false
      }
    case 2:
      return rn != prefix
    }
    rn_idx += 1
  }
  return false
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
  arg:                 string,
  flag_without_prefix: string,
  flag_with_prefix:    string,
  tail:                string,
}

_getShortFlagParts :: proc(arg: string, prefix := _DEFAULT_PREFIX_RUNE) -> (out: _ShortFlagParts, ok: bool) #optional_ok {
  out.arg = arg
  flag_start_idx := -1 // string slice index for start of flag
  // -a -> 1
  // -äb -> 1
  tail_start_idx := -1 // string slice index for start of trail e.g. -ab -> 2  
  // -a -> 2
  // -äb -> 3
  rn_idx := 0 // rune count index
  loop: for rn, idx in arg {
    switch rn_idx {
    case 0:
      if rn != prefix {
        //invalid
        ok = false
        break loop
      }
    case 1:
      if rn == prefix {
        // invalid
        ok = false
        break loop
      }
      flag_start_idx = idx
    case 2:
      tail_start_idx = idx
      ok = true
      break loop
    }
    rn_idx += 1
  }
  if ok {
    out.flag_with_prefix = arg[:tail_start_idx]
    out.flag_without_prefix = arg[flag_start_idx:tail_start_idx]
    out.tail = arg[tail_start_idx:]
  }
  return
}

/////////////////////////////

_cleanFlags :: proc(raw_flags: []string, prefix: rune = _DEFAULT_PREFIX_RUNE, allocator := context.allocator) -> []string {
  // Cleans all flag prefixes
  context.allocator = allocator
  flags := make([dynamic]string, len(raw_flags))
  for raw_flag, idx in raw_flags {
    flags[idx] = _normalizePrefix(s = raw_flag, old = []rune{prefix}, replacement = prefix)
  }
  return flags[:]
}

/////////////////////////////

_getDestFromFlags :: proc(flags: []string, prefix: rune = _DEFAULT_PREFIX_RUNE) -> (out: string, ok: bool) {
  // Gets first long flag, (if none, then short or pos) and strips prefix
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
  // Checks that
  // - flags list is non-empty
  // - only one positional
  // - positional doesn't mix with keyword
  // - no-invalid flags eg. '--'
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
