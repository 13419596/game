package argparse

import "core:log"
import "core:strings"


_ArgumentFlagType :: enum {
  Invalid,
  Short,
  Long,
  Positional,
}

/////////////////////////////

_isPositionalFlag :: proc(flag: string, prefix: rune) -> bool {
  rn_idx := 0
  for rn in flag {
    return rn != prefix
  }
  return false
}

_isShortFlag :: proc(flag: string, prefix: rune) -> bool {
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

_isLongFlag :: proc(flag: string, prefix: rune) -> bool {
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

_getFlagType :: proc(flag: string, prefix: rune) -> _ArgumentFlagType {
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

@(require_results)
_cleanFlag :: proc(raw_flag: string, prefix: rune, allocator := context.allocator) -> string {
  context.allocator = allocator
  out := _normalizePrefix(s = raw_flag, old = []rune{prefix}, replacement = prefix)
  return out
}

@(require_results)
_cleanFlags :: proc(raw_flags: []string, prefix: rune, allocator := context.allocator) -> [dynamic]string {
  // Cleans all flag prefixes
  context.allocator = allocator
  flags := make([dynamic]string, len(raw_flags))
  for raw_flag, idx in raw_flags {
    flags[idx] = _cleanFlag(raw_flag, prefix)
  }
  return flags
}

/////////////////////////////

@(require_results)
_getDestFromFlags :: proc(flags: []string, prefix: rune) -> (out: string, ok: bool) {
  // Gets first long flag, (if none, then short or pos) and strips prefix
  using strings
  out = ""
  ok = false
  if len(flags) <= 0 {
    log.errorf("Option strings array is empty. Expected at least one flag string.")
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
    log.errorf("Could not determine first non-prefix index in flags array:%v", flags)
    return
  }
  out = flag[first_non_prefix_index:]
  ok = true
  return
}

/////////////////////////////

_areFlagsOkay :: proc(flags: []string, prefix: rune) -> bool {
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
      log.errorf("Invalid flag that is neither short, long, nor position flag. flags[%v]:%q", idx, flag)
      ok = false
    case .Positional:
      if has_short_or_long {
        log.errorf("Cannot mix positional and keyword flags in a single argument. flags[%v]:%q", idx, flag)
        ok = false
      } else if !has_positional {
        has_positional = true
        break
      } else {
        log.errorf("Only a single positional flag is allowed. flags[%v]:%q", idx, flag)
        ok = false
      }
      fallthrough
    case .Short:
      fallthrough
    case .Long:
      has_short_or_long = true
      if has_positional {
        log.errorf("Cannot mix positional and keyword flags in a single argument. flags[%v]:%q", idx, flag)
        ok = false
      }
    }
  }
  if has_positional && has_short_or_long {
    ok = false
  }
  return ok
}
