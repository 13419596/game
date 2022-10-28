package argparse

import "core:fmt"
import "core:log"
import "core:os"
import "core:runtime"
import "core:strings"
import "core:path/filepath"
import "core:unicode/utf8"

import "game:trie"

ArgumentOptionType :: enum {
  Invalid,
  Short,
  Long,
  Positional,
}

ArgumentOption :: struct {
  flags:          []string,
  dest:           string,
  nargs:          int,
  constant_value: any,
  default:        any,
  // type
  choices:        []any,
  action:         ArgumentAction,
  required:       bool,
  help:           string,
  _allocator:     runtime.Allocator,
  _is_positional: bool,
  _cache_usage:   Maybe(string),
  _cache_help:    Maybe(string),
}

@(require_results)
makeArgumentOption :: proc(
  flags: []string,
  dest: Maybe(string) = nil,
  nargs: Maybe(int) = nil,
  action := ArgumentAction.Store,
  required: bool = false,
  help: Maybe(string) = nil,
  prefix := _DEFAULT_PREFIX_RUNE,
  allocator := context.allocator,
) -> (
  out: ArgumentOption,
  ok: bool,
) {
  ok = _areOptionStringsOkay(flags, prefix)
  if !ok {
    return
  }
  ok = false
  out = ArgumentOption {
    action     = action,
    required   = required,
    _allocator = allocator,
  }
  if opt_nargs, nargs_ok := nargs.?; nargs_ok {
    out.nargs = opt_nargs
  } else {
    // unspecified so set to default
    switch out.action {
    case .StoreTrue:
      fallthrough
    case .StoreFalse:
      fallthrough
    case .StoreConst:
      fallthrough
    case .AppendConst:
      fallthrough
    case .Count:
      fallthrough
    case .Help:
      fallthrough
    case .Version:
      out.nargs = 0
    case .Append:
      fallthrough
    case .Extend:
      fallthrough
    case .Store:
      out.nargs = 1
    }
  }
  if out.nargs < 0 {
    log.errorf("Nargs is invalid. Got:%v", out.nargs)
    return
  }
  {
    tmp_flags := make([dynamic]string, 0, len(flags), allocator)
    for _, idx in flags {
      append(&tmp_flags, _replaceRunes(flags[idx], {prefix}, prefix, allocator))
    }
    out.flags = tmp_flags[:]
  }
  if dest_string, mdest_ok := dest.?; mdest_ok {
    out.dest = dest_string
  } else {
    out.dest, ok = _getDestFromOptions(out.flags, prefix)
    if !ok {
      deleteArgumentOption(&out)
      return
    }
  }
  if shelp, ok := help.?; ok {
    out.help = strings.clone(shelp, allocator)
  }
  out._is_positional = _isPositionalOption(out.flags[0])
  if out._is_positional {
    if out.nargs <= 0 {
      log.errorf("Argument is positional, but nargs is invalid. Expected >0. Got:%v", out.nargs)
      deleteArgumentOption(&out)
      return
    }
    if !out.required {
      log.warnf("`required` is an invalid argument for positional argument. Defaulting to true")
      out.required = true
    }
  } else {
    switch out.action {
    case .StoreTrue:
      fallthrough
    case .StoreFalse:
      fallthrough
    case .StoreConst:
      fallthrough
    case .AppendConst:
      fallthrough
    case .Count:
      fallthrough
    case .Help:
      fallthrough
    case .Version:
      if out.nargs != 0 {
        log.errorf("Argument action is %v, so expected narg==0. Got:%v", out.action, out.nargs)
        deleteArgumentOption(&out)
        return
      }
    case .Append:
      fallthrough
    case .Extend:
      fallthrough
    case .Store:
      if out.nargs == 0 {
        deleteArgumentOption(&out)
        log.errorf("Argument action is %v, so expected narg>0. Got:%v", out.action, out.nargs)
        return
      }
    }
  }
  ok = true
  return
}

deleteArgumentOption :: proc(self: $T/^ArgumentOption) {
  if self == nil {
    return
  }
  for _, idx in self.flags {
    delete(self.flags[idx], self._allocator)
  }
  delete(self.flags, self._allocator)
  self.flags = {}
  delete(self.dest, self._allocator)
  self.dest = {}
  delete(self.help, self._allocator)
  self.help = {}
  if usage, ok := self._cache_usage.?; ok {
    delete(usage, self._allocator)
    self._cache_usage = nil
  }
}

/////////////////////////////

_isPositionalOption :: proc(option: string, prefix: rune = _DEFAULT_PREFIX_RUNE) -> bool {
  using utf8
  r0 := rune_at_pos(option, 0)
  out := ((r0 != prefix && r0 != RUNE_ERROR))
  return out
}

_isShortOption :: proc(option: string, prefix: rune = _DEFAULT_PREFIX_RUNE) -> bool {
  using utf8
  r0 := rune_at_pos(option, 0)
  r1 := rune_at_pos(option, 1)
  r2 := rune_at_pos(option, 2)
  out := ((r0 == prefix) && (r1 != prefix && r1 != RUNE_ERROR) && (r2 == RUNE_ERROR))
  return out
}

_isLongOption :: proc(option: string, prefix: rune = _DEFAULT_PREFIX_RUNE) -> bool {
  using utf8
  r0 := rune_at_pos(option, 0)
  r1 := rune_at_pos(option, 1)
  r2 := rune_at_pos(option, 2)
  out := ((r0 == prefix) && ((r1 == prefix) && (r2 != prefix && r2 != RUNE_ERROR)) || ((r1 != prefix) && (r2 == prefix && r2 != RUNE_ERROR)))
  return out
}

_getOptionType :: proc(option: string, prefix := _DEFAULT_PREFIX_RUNE) -> ArgumentOptionType {
  if _isShortOption(option, prefix) {
    return .Short
  } else if _isLongOption(option, prefix) {
    return .Long
  } else if _isPositionalOption(option, prefix) {
    return .Positional
  }
  return .Invalid
}

_areOptionStringsOkay :: proc(options: []string, prefix := _DEFAULT_PREFIX_RUNE) -> bool {
  if len(options) <= 0 {
    log.errorf("Expected at least one option.")
    return false
  }
  has_positional := false
  has_short_or_long := false
  ok := true
  for option, idx in options {
    opt_type := _getOptionType(option, prefix)
    switch opt_type {
    case .Invalid:
      log.errorf("Invalid option that is neither short, long, nor position option. options[%v]:\"%v\"", idx, option)
      ok = false
    case .Positional:
      if has_short_or_long {
        log.errorf("Cannot mix positional and keyword options in a single argument. options[%v]:\"%v\"", idx, option)
        ok = false
      } else if !has_positional {
        has_positional = true
        break
      } else {
        log.errorf("Only a single positional option is allowed. options[%v]:\"%\"", idx, option)
        ok = false
      }
      fallthrough
    case .Short:
      fallthrough
    case .Long:
      has_short_or_long = true
      if has_positional {
        log.errorf("Cannot mix positional and keyword options in a single argument. options[%v]:\"%v\"", idx, option)
        ok = false
      }
    }
  }
  if has_positional && has_short_or_long {
    ok = false
  }
  return ok
}

/////////////////////////////

@(require_results)
_replaceRunes :: proc(s: string, old_runes: []rune, replacement: $R, allocator := context.allocator) -> string {
  context.allocator = context.temp_allocator
  replacement_str := fmt.tprintf("%v", replacement)
  line := make([dynamic]string)
  for rn, idx in s {
    added_rn := false
    for old_rn in old_runes {
      if rn == old_rn {
        append(&line, replacement_str)
        added_rn = true
        break
      }
    }
    if !added_rn {
      append(&line, s[idx:idx + 1])
    }
  }
  out := strings.join(line[:], "", allocator)
  return out
}

/////////////////////////////

@(require_results)
_getDestFromOptions :: proc(options: []string, prefix: rune = _DEFAULT_PREFIX_RUNE, allocator := context.allocator) -> (out: string, ok: bool) {
  // Assumes that options is non-empty
  out = ""
  ok = false
  if len(options) <= 0 {
    log.errorf("Option strings is empty. Expected at least one option string.")
    return
  }
  long_option_index := -1
  for option, idx in options {
    if _isLongOption(option, prefix) {
      long_option_index = idx
      break
    }
  }
  option_index := long_option_index >= 0 ? long_option_index : 0
  option := options[option_index]
  first_non_prefix_index := -1
  for rn, idx in option {
    if rn != prefix {
      first_non_prefix_index = idx
      break
    }
  }
  if first_non_prefix_index == -1 {
    log.errorf("Could not determine first non-prefix index in option:\"%v\"", option)
    return
  }
  option = option[first_non_prefix_index:]
  // Now replace every [^a-zA-Z_] with "_"
  pieces := make([dynamic]string, context.temp_allocator)
  start_idx := 0
  for rn, idx in option {
    val := int(rn)
    if (48 <= val && val < 58) || (65 <= val && val < 91) || (97 <= val && val < 123) {
      append(&pieces, option[idx:idx + 1])
    } else {
      append(&pieces, "_")
    }
  }
  out = strings.join(pieces[:], "", allocator)
  ok = true
  return
}

/////////////////////////////////////////////////////////

_getUsageString :: proc(self: $T/^ArgumentOption, prefix := _DEFAULT_PREFIX_RUNE) -> string {
  using strings
  if usage, ok := self._cache_usage.?; ok {
    return usage
  }
  context.allocator = self._allocator
  option0 := len(self.flags) > 0 ? self.flags[0] : ""
  out: string = ""
  if self._is_positional {
    pieces := make([dynamic]string, self.nargs)
    for idx in 0 ..< self.nargs {
      pieces[idx] = option0
    }
    out = join(pieces[:], " ", self._allocator)
  } else {
    line := make([dynamic]string)
    if !self.required {
      append(&line, "[")
    }
    append(&line, option0)
    if self.nargs > 0 {
      opt_u := fmt.tprintf(" %v", strings.to_upper(self.dest))
      append(&line, strings.repeat(opt_u, self.nargs))
    }
    if !self.required {
      append(&line, "]")
    }
    out = strings.join(line[:], "")
  }
  self._cache_usage = out
  return out
}

_getHelpCache :: proc(self: $T/^ArgumentOption, indent := "  ", option_field_width: int = 22, allocator := context.allocator) -> string {
  if help_cache, ok := self._cache_help.?; ok {
    return help_cache
  }
  using strings
  context.allocator = context.temp_allocator
  vars := ""
  if self.nargs > 0 && !self._is_positional {
    dest_u := fmt.tprintf(" %v", to_upper(self.dest))
    vars = repeat(dest_u, self.nargs)
  }
  opt_vars := make([dynamic]string)
  for option, idx in self.flags {
    append(&opt_vars, fmt.tprintf("%v%v", option, vars))
  }
  all_opt_vars := join(opt_vars[:], ", ")
  first_line_pieces := make([dynamic]string)
  append(&first_line_pieces, all_opt_vars)

  help_lines := split(self.help, "\n")
  help_start_index := 0
  if len(all_opt_vars) <= option_field_width {
    // add first help line to opt vars line
    append(&first_line_pieces, repeat(" ", option_field_width - len(all_opt_vars)))
    append(&first_line_pieces, help_lines[0])
    help_start_index += 1
  }

  out_lines := make([dynamic]string)
  append(&out_lines, concatenate({indent, join(first_line_pieces[:], "")}))
  help_indent := repeat(" ", option_field_width)
  for idx in help_start_index ..< len(help_lines) {
    append(&out_lines, concatenate({indent, help_indent, help_lines[idx]}))
  }

  out := join(out_lines[:], "\n", self._allocator)
  self._cache_help = out
  return out
}
