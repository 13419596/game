package argparse

import "core:fmt"
import "core:log"
import "core:os"
import "core:runtime"
import "core:strings"
import "core:path/filepath"
import "core:unicode/utf8"

import "game:trie"

NumTokens :: struct {
  lower: int,
  upper: Maybe(int),
}

NargsType :: union {
  int,
  string,
  // rune,
}

ArgumentFlagType :: enum {
  Invalid,
  Short,
  Long,
  Positional,
}

ArgumentOption :: struct {
  flags:          []string,
  dest:           string,
  constant_value: any,
  default:        any,
  // type
  choices:        []any,
  action:         ArgumentAction,
  required:       bool,
  help:           string,
  num_tokens:     NumTokens,
  /*
  // In header: <boost/program_flags/value_semantic.hpp>


class value_semantic {
public:
  // construct/copy/destruct
  ~value_semantic();

  // public member functions
  virtual std::string name() const = 0;
  virtual unsigned min_tokens() const = 0;
  virtual unsigned max_tokens() const = 0;
  virtual bool is_composing() const = 0;
  virtual bool is_required() const = 0;
  virtual void 
  parse(boost::any &, const std::vector< std::string > &, bool) const = 0;
  virtual bool apply_default(boost::any &) const = 0;
  virtual void notify(const boost::any &) const = 0;
};
  */
  _allocator:     runtime.Allocator,
  _is_positional: bool,
  _is_composed:   bool, // multipart
  _cache_usage:   Maybe(string),
  _cache_help:    Maybe(string),
}

@(require_results)
makeArgumentOption :: proc(
  flags: []string,
  dest: Maybe(string) = nil,
  nargs := NargsType{},
  action := ArgumentAction.Store,
  required: bool = false,
  help: Maybe(string) = nil,
  prefix := _DEFAULT_PREFIX_RUNE,
  allocator := context.allocator,
) -> (
  out: ArgumentOption,
  ok: bool,
) {
  if !_areFlagsOkay(flags, prefix) {
    ok = false
    return
  }
  ok = false
  out = ArgumentOption {
    action       = action,
    required     = required,
    flags        = _cleanFlags(flags, prefix, allocator),
    _allocator   = allocator,
    _is_composed = isArgumentActionComposed(action),
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
    if dest, dest_ok := _getDestFromFlags(out.flags, prefix); dest_ok {
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
  if out._is_positional && !out.required {
    log.warnf("`required` is an invalid argument for positional argument. Defaulting to true")
    out.required = true
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
  delete(self.flags, self._allocator)
  self.flags = {}
  delete(self.dest, self._allocator)
  self.dest = {}
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
  r2 := rune_at_pos(flag, 2)
  out := ((r0 == prefix) && (r1 != prefix && r1 != RUNE_ERROR) && (r2 == RUNE_ERROR))
  return out
}

_isLongFlag :: proc(flag: string, prefix: rune = _DEFAULT_PREFIX_RUNE) -> bool {
  using utf8
  r0 := rune_at_pos(flag, 0)
  r1 := rune_at_pos(flag, 1)
  r2 := rune_at_pos(flag, 2)
  out := ((r0 == prefix) && ((r1 == prefix) && (r2 != prefix && r2 != RUNE_ERROR)) || ((r1 != prefix) && (r2 == prefix && r2 != RUNE_ERROR)))
  return out
}

_getFlagType :: proc(flag: string, prefix := _DEFAULT_PREFIX_RUNE) -> ArgumentFlagType {
  if _isShortFlag(flag, prefix) {
    return .Short
  } else if _isLongFlag(flag, prefix) {
    return .Long
  } else if _isPositionalFlag(flag, prefix) {
    return .Positional
  }
  return .Invalid
}

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
_getDestFromFlags :: proc(flags: []string, prefix: rune = _DEFAULT_PREFIX_RUNE, allocator := context.allocator) -> (out: string, ok: bool) {
  // Assumes that flags is non-empty
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
  flag = flag[first_non_prefix_index:]
  // Now replace every [^a-zA-Z_] with "_"
  pieces := make([dynamic]string, context.temp_allocator)
  start_idx := 0
  for rn, idx in flag {
    val := int(rn)
    if (48 <= val && val < 58) || (65 <= val && val < 91) || (97 <= val && val < 123) {
      append(&pieces, flag[idx:idx + 1])
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
  flag0 := len(self.flags) > 0 ? self.flags[0] : ""
  out: string = ""
  if self._is_positional {
    pieces := make([dynamic]string)
    for idx in 0 ..< self.num_tokens.lower {
      append(&pieces, flag0)
    }
    if upper, upper_ok := self.num_tokens.upper.?; upper_ok {
      // TODO ---- 
    } else {
      // no bound
      append(&pieces, concatenate({"[", flag0}))
      append(&pieces, "...]")
    }
    out = join(pieces[:], " ", self._allocator)
  } else {
    line := make([dynamic]string)
    if !self.required {
      append(&line, "[")
    }
    append(&line, flag0)
    if self.num_tokens.lower > 0 {
      log.warnf("num tokens:%v ;; ", self.num_tokens)
      append(&line, strings.repeat(concatenate({" ", to_upper(self.dest)}), self.num_tokens.lower))
    }
    if !self.required {
      append(&line, "]")
    }
    out = strings.join(line[:], "")
  }
  self._cache_usage = out
  return out
}

_getHelpCache :: proc(self: $T/^ArgumentOption, indent := "  ", flag_field_width: int = 22, allocator := context.allocator) -> string {
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
  for flag, idx in self.flags {
    append(&opt_vars, fmt.tprintf("%v%v", flag, vars))
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

_parseNargs :: proc(action: ArgumentAction, vnargs: NargsType) -> (out: NumTokens, ok: bool) {
  out = NumTokens{}
  ok = true
  if vnargs != nil {
    switch nargs in vnargs {
    case int:
      if nargs < 0 {
        log.errorf("If nargs is an int, it must be >=0. Got:%v", nargs)
        ok = false
      } else {
        out.lower = nargs
        out.upper = nargs
      }
    // case rune:
    //   switch nargs {
    //   case '?':
    //     out.lower = 0
    //     out.upper = 1
    //   case '*':
    //     out.lower = 0
    //     out.upper = {}
    //   case '+':
    //     out.lower = 1
    //     out.upper = {}
    //   case:
    //     log.errorf("If nargs is a string, it must be in the set {'?', '*', '+'}. Got:'%v'", nargs)
    //     ok = false
    //   }
    case string:
      switch nargs {
      case "?":
        out.lower = 0
        out.upper = 1
      case "*":
        out.lower = 0
        out.upper = {}
      case "+":
        out.lower = 1
        out.upper = {}
      case:
        log.errorf("If nargs is a string, it must be in the set {{\"?\", \"*\", \"+\"}}. Got:\"%v\"", nargs)
        ok = false
      }
    }
  } else {
    // use default 
    switch action {
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
      out.lower = 0
      out.upper = 0
    ///////////////
    case .Append:
      out.lower = 0
      out.upper = 1
    case .Extend:
      out.lower = 0
      out.upper = {}
    case .Store:
      out.lower = 1
      out.upper = 1
    }
  }
  return
}

_cleanFlags :: proc(raw_flags: []string, prefix: rune = _DEFAULT_PREFIX_RUNE, allocator := context.allocator) -> []string {
  flags := make([dynamic]string, len(raw_flags), allocator)
  for raw_flag, idx in raw_flags {
    flags[idx] = _replaceRunes(raw_flag, {prefix}, prefix, allocator)
  }
  return flags[:]
}

_isPositionalOptionNumTokensValid :: proc(action: ArgumentAction, num_tokens: NumTokens) -> bool {
  switch action {
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
    fallthrough
  case .Append:
    fallthrough
  case .Extend:
    log.errorf("Argument is positional, but action is %v. This is invalid.", action)
    return false
  case .Store:
  // okay
  }
  if num_tokens.lower <= 0 {
    log.errorf("Argument is positional, but nargs is invalid. Expected >0. Got:%v", num_tokens)
    return false
  }
  return true
}

_isKeywordOptionNumTokensValid :: proc(action: ArgumentAction, num_tokens: NumTokens) -> bool {
  switch action {
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
    if num_tokens.lower != 0 || num_tokens.upper != 0 {
      log.errorf("Argument action is %v, so expected num args==0. Got:%v", action, num_tokens)
      return false
    }
  //////////////////
  case .Append:
    fallthrough
  case .Extend:
    fallthrough
  case .Store:
    if upper, upper_ok := num_tokens.upper.?; upper_ok {
      if upper < num_tokens.lower {
        log.errorf("Argument action is %v, so expected upper > lower. Got upper:%v lower:%v", action, upper, num_tokens.lower)
        return false
      }
    }
  }
  return true
}

_isOptionNumTokensValid :: proc(is_positional: bool, action: ArgumentAction, num_tokens: NumTokens) -> bool {
  if is_positional {
    return _isPositionalOptionNumTokensValid(action, num_tokens)
  }
  return _isKeywordOptionNumTokensValid(action, num_tokens)
}
