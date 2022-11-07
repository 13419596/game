package argparse

import "core:fmt"
import "core:log"
import "core:runtime"
import "core:strings"

ArgumentOption :: struct {
  flags:          [dynamic]string, // list wont change length, but [dyanmic] is nice because it remembers allocator
  dest:           string,
  const:          any,
  action:         ArgumentAction,
  required:       bool,
  help:           string,
  num_tokens:     _NumTokens,
  _is_positional: bool,
  _cache_usage:   Maybe(string),
  _cache_help:    Maybe(string),
  _allocator:     runtime.Allocator,
}

@(require_results)
makeArgumentOption :: proc(
  flags: []string,
  dest: Maybe(string) = nil,
  nargs := NargsType{},
  action := ArgumentAction.Store,
  required := Maybe(bool){},
  help: Maybe(string) = nil,
  prefix := _DEFAULT_PREFIX_RUNE,
  allocator := context.allocator,
) -> (
  out: ArgumentOption,
  ok: bool,
) {
  ok = false
  if !_areFlagsOkay(flags, prefix) {
    ok = false
    return
  }
  out = ArgumentOption {
    action     = action,
    flags      = _cleanFlags(flags, prefix, allocator),
    _allocator = allocator,
  }
  out._is_positional = _isPositionalFlag(out.flags[0])
  if num_tokens, num_tokens_ok := _parseNargs(out.action, nargs); num_tokens_ok {
    out.num_tokens = num_tokens
  } else {
    ok = false
    deleteArgumentOption(&out)
    return
  }
  if !_isOptionNumTokensValid(out._is_positional, out.action, out.num_tokens) {
    ok = false
    deleteArgumentOption(&out)
    return
  }
  if dest_string, mdest_ok := dest.?; mdest_ok {
    out.dest = dest_string
  } else {
    if dest, dest_ok := _getDestFromFlags(out.flags[:], prefix); dest_ok {
      out.dest = dest
    } else {
      ok = false
      deleteArgumentOption(&out)
      return
    }
  }
  if shelp, ok := help.?; ok {
    out.help = strings.clone(shelp, allocator)
  }
  if req, req_ok := required.?; req_ok {
    // specified
    if req {
      out.required = true
    } else {
      if out._is_positional {
        log.warnf("`required` is an invalid argument for positional argument. Defaulting to true")
        out.required = true
      } else {
        out.required = false
      }
    }
  } else {
    // unspecified
    out.required = out._is_positional ? true : false
  }
  ok = true
  return
}

deleteArgumentOption :: proc(self: $T/^ArgumentOption) {
  if self == {} {
    return
  }
  for _, idx in self.flags {
    delete(self.flags[idx], self._allocator)
  }
  delete(self.flags)
  self.flags = {}
  self.dest = ""
  delete(self.help, self._allocator)
  self.help = {}
  if usage, ok := self._cache_usage.?; ok {
    delete(usage, self._allocator)
    self._cache_usage = {}
  }
  if help, ok := self._cache_help.?; ok {
    delete(help, self._allocator)
    self._cache_help = {}
  }
}

_clearCache :: proc(self: $T/^ArgumentOption) {
  if usage, ok := self._cache_usage.?; ok {
    delete(usage, self._allocator)
    self._cache_usage = {}
  }
  if help, ok := self._cache_help.?; ok {
    delete(help, self._allocator)
    self._cache_help = {}
  }
}

/////////////////////////////////////////////////////////

_makeUsageString :: proc(
  self: $T/^ArgumentOption,
  flag: string,
  disable_keyword_brackets: bool = false,
  prefix := _DEFAULT_PREFIX_RUNE,
  allocator := context.allocator,
) -> string {
  using strings
  context.allocator = context.temp_allocator
  out: string = ""
  if self._is_positional {
    pieces := make([dynamic]string)
    for idx in 0 ..< self.num_tokens.lower {
      append(&pieces, flag)
    }
    if upper, upper_ok := self.num_tokens.upper.?; upper_ok {
      extra_optional := max(0, upper - self.num_tokens.lower)
      for idx in 0 ..< extra_optional {
        append(&pieces, concatenate({"[", flag}))
      }
      if len(pieces) > 0 {
        tmp := clone(pieces[len(pieces) - 1])
        pieces[len(pieces) - 1] = concatenate({tmp, repeat("]", extra_optional)})
      }
    } else {
      // no bound
      append(&pieces, concatenate({"[", flag}))
      append(&pieces, "...]")
    }
    out = join(pieces[:], " ", allocator)
  } else {
    line := make([dynamic]string)
    add_surrounding_brackets := (!self.required || (self.num_tokens.lower == 0 && self.num_tokens.upper == 0)) && !disable_keyword_brackets
    if add_surrounding_brackets {
      append(&line, "[")
    }
    append(&line, flag)
    udest := to_upper(self.dest)
    if self.num_tokens.lower > 0 {
      append(&line, concatenate({"", repeat(concatenate({" ", udest}), self.num_tokens.lower)}))
    }
    if upper, upper_ok := self.num_tokens.upper.?; upper_ok {
      extra_optional := max(0, upper - self.num_tokens.lower)
      for idx in 0 ..< extra_optional {
        append(&line, concatenate({" [", udest}))
      }
      if len(line) > 0 {
        tmp := clone(line[len(line) - 1])
        line[len(line) - 1] = concatenate({tmp, repeat("]", extra_optional)})
      }
    } else {
      // no bound
      append(&line, concatenate({"[", udest}))
      append(&line, "...]")
    }
    if add_surrounding_brackets {
      append(&line, "]")
    }
    out = strings.join(line[:], "", allocator)
  }
  return out
}

_getUsageString :: proc(self: $T/^ArgumentOption, prefix := _DEFAULT_PREFIX_RUNE) -> string {
  if usage, ok := self._cache_usage.?; ok {
    return usage
  }
  flag0 := len(self.flags) > 0 ? self.flags[0] : ""
  out := _makeUsageString(self = self, prefix = prefix, flag = flag0, allocator = self._allocator)
  self._cache_usage = out
  return out
}

_getHelpCache :: proc(self: $T/^ArgumentOption, indent := "  ", flag_field_width: int = 22, prefix := _DEFAULT_PREFIX_RUNE) -> string {
  if help_cache, ok := self._cache_help.?; ok {
    return help_cache
  }
  using strings
  context.allocator = context.temp_allocator
  vars := ""
  if !self._is_positional {
    if self.num_tokens.lower > 0 {
      vars = repeat(concatenate({" ", to_upper(self.dest)}), self.num_tokens.lower)
    }
  }
  opt_vars := make([dynamic]string)
  if self._is_positional {
    append(&opt_vars, self.flags[0])
  } else {
    for flag, idx in self.flags {
      tmp_usage := _makeUsageString(self = self, flag = flag, disable_keyword_brackets = true, prefix = prefix, allocator = context.temp_allocator)
      append(&opt_vars, tmp_usage)
    }
  }
  all_opt_vars := join(opt_vars[:], ", ")
  first_line_pieces := make([dynamic]string)
  append(&first_line_pieces, all_opt_vars)

  help_lines := split(self.help, "\n")
  help_start_index := 0
  if len(all_opt_vars) <= flag_field_width {
    // add first help line to opt vars line
    append(&first_line_pieces, repeat(" ", flag_field_width - len(all_opt_vars)))
    append(&first_line_pieces, help_lines[0])
    help_start_index += 1
  }

  out_lines := make([dynamic]string)
  append(&out_lines, concatenate({indent, join(first_line_pieces[:], "")}))
  help_indent := repeat(" ", flag_field_width)
  for idx in help_start_index ..< len(help_lines) {
    append(&out_lines, concatenate({indent, help_indent, help_lines[idx]}))
  }

  out := join(out_lines[:], "\n", self._allocator)
  self._cache_help = out
  return out
}

/////////////////////////////////////////////////////////
