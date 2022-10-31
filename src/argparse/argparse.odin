package argparse

import "core:fmt"
import "core:log"
import "core:os"
import "core:path/filepath"
import "core:runtime"
import "core:strings"
import "core:unicode/utf8"
import "game:trie"

@(private)
_DEFAULT_PREFIX_RUNE: rune : '-'

@(private)
_FLAG_EQUALITY_RUNE: rune : '='

@(private)
_TrieValueType :: string

ArgumentParser :: struct {
  prog:          string, // The name of the program (default: sys.argv[0])
  description:   string, // A usage message (default: auto-generated from arguments)
  epilog:        string, // Text following the argument descriptions
  prefix_rune:   rune, // Character that prefix optional arguments
  add_help:      bool, // Add a -h/-help option
  allow_abbrev:  bool, // Allow long options to be abbreviated unambiguously
  exit_on_error: bool,
  options:       map[string]ArgumentOption,
  _allocator:    runtime.Allocator,
  _kw_trie:      trie.Trie(int, _TrieValueType), // int(rune) -> int option index
  _cache_usage:  Maybe(string),
  _cache_help:   Maybe(string),
}

@(require_results)
makeArgumentParser :: proc(
  prog := Maybe(string){},
  description: string = "",
  epilog: string = "",
  prefix_rune: rune = _DEFAULT_PREFIX_RUNE,
  add_help: bool = true,
  allow_abbrev: bool = true,
  exit_on_error: bool = true,
  allocator := context.allocator,
) -> (
  out: ArgumentParser,
  ok: bool,
) {
  using strings
  out = ArgumentParser {
    prog = {},
    description = clone(description, allocator),
    epilog = clone(epilog),
    prefix_rune = prefix_rune,
    allow_abbrev = allow_abbrev,
    options = make(map[string]ArgumentOption, 0, allocator),
    _allocator = allocator,
    _kw_trie = trie.makeTrie(int, _TrieValueType, allocator),
  }
  if prog, ok := prog.?; ok {
    out.prog = clone(prog, allocator)
  } else {
    out.prog = clone(filepath.base(os.args[0]), allocator)
  }
  if add_help {
    option := addArgument(
      self = &out,
      flags = {fmt.tprintf("%vh", prefix_rune), fmt.tprintf("%v%vhelp", prefix_rune, prefix_rune)},
      action = .Help,
      help = "show this help message and exit",
    )
    if option == nil {
      deleteArgumentParser(&out)
      ok = false
      return
    }
  }
  ok = true
  return
}

deleteArgumentParser :: proc(self: $T/^ArgumentParser) {
  if self == nil {
    return
  }
  delete(self.prog, self._allocator)
  self.prog = {}
  delete(self.description, self._allocator)
  self.description = {}
  delete(self.epilog, self._allocator)
  self.epilog = {}
  for k, v in &self.options {
    deleteArgumentOption(&v)
  }
  delete(self.options)
  self.options = {}
  trie.deleteTrie(&self._kw_trie)
  if usage, ok := self._cache_usage.?; ok {
    delete(usage, self._allocator)
    self._cache_usage = nil
  }
  if help, ok := self._cache_help.?; ok {
    delete(help, self._allocator)
    self._cache_help = nil
  }
}

////////////////////////////////////////

addArgument :: proc(
  self: $T/^ArgumentParser,
  flags: []string,
  action := ArgumentAction.Store,
  nargs := NargsType{},
  required := Maybe(bool){},
  dest := Maybe(string){},
  help := Maybe(string){},
) -> ^ArgumentOption {
  option, arg_ok := makeArgumentOption(
    flags = flags,
    dest = dest,
    nargs = nargs,
    action = action,
    required = required,
    help = help,
    prefix = self.prefix_rune,
    allocator = self._allocator,
  )
  if !arg_ok {
    deleteArgumentOption(&option)
    return nil
  }
  ok := true
  if !option._is_positional {
    for flag, flag_idx in option.flags {
      found_value, found_ok := trie.getValue(&self._kw_trie, flag)
      if !found_ok || found_value not_in self.options {
        continue
      }
      log.errorf("New option flag:\"%v\" conflicts with existing option flags:%v", flag, found_value)
      ok = false
      break
    }
  }
  // Check if dest conflicts
  if option.dest in self.options {
    // TODO(feature) allow for overriding options
    log.errorf("New option dest:\"%v\" conflicts with existing options", option.dest)
    ok = false
  }
  if !ok {
    deleteArgumentOption(&option)
    return nil
  }
  self.options[option.dest] = option
  for flag in option.flags {
    trie.setValue(&self._kw_trie, flag, option.dest)
  }
  return &self.options[option.dest]
}

////////////////////////////////////////

getUsage :: proc(self: $T/^ArgumentParser) -> string {
  using strings
  if usage, ok := self._cache_usage.?; ok {
    return usage
  }
  context.allocator = context.temp_allocator
  lines := make([dynamic]string)
  // print keywords first
  usage_pieces := make([dynamic]string)
  append(&usage_pieces, fmt.tprintf("usage %v", self.prog))
  for _, option in &self.options {
    if !option._is_positional {
      append(&usage_pieces, _getUsageString(&option))
    }
  }
  // print then positionals
  for _, option in &self.options {
    if option._is_positional {
      append(&usage_pieces, _getUsageString(&option))
    }
  }
  out := join(usage_pieces[:], " ", self._allocator)
  self._cache_usage = out
  return out
}


getHelp :: proc(self: $T/^ArgumentParser) -> string {
  using strings
  if usage, ok := self._cache_help.?; ok {
    return usage
  }
  context.allocator = context.temp_allocator
  any_positionals := false
  any_keywords := false
  {
    // print keywords first
    for _, option in &self.options {
      if !option._is_positional {
        any_keywords = true
        break
      }
    }
    // print then positionals
    for _, option in &self.options {
      if option._is_positional {
        any_positionals = true
        break
      }
    }
  }
  lines := make([dynamic]string)
  append(&lines, getUsage(self))
  if len(self.description) > 0 {
    append(&lines, "")
    append(&lines, self.description)
  }
  if any_positionals {
    append(&lines, "")
    append(&lines, "positional arguments:")
    for _, option in &self.options {
      if option._is_positional {
        append(&lines, _getHelpCache(&option))
      }
    }
  }
  if any_keywords {
    append(&lines, "")
    append(&lines, "keyword arguments:")
    for _, option in &self.options {
      if !option._is_positional {
        append(&lines, _getHelpCache(&option))
      }
    }
  }
  if len(self.epilog) > 0 {
    append(&lines, "")
    append(&lines, self.epilog)
  }
  out := join(lines[:], "\n", self._allocator)
  self._cache_help = out
  return out
}

////////////////////////////////////////

/*
ParsedArgumentOption :: struct {
  arg:          string,
  arg_type:     ArgumentFlagType,
  trailing_arg: string,
  option:       ^ArgumentOption,
}

_determineArgumentOption :: proc(self: $T/^ArgumentParser, arg: string) -> (out: ^ArgumentOption, arg_is_short: bool, trailing_arg: string) {
  out := ParsedArgumentOption {
    arg      = arg,
    arg_type = _getFlagType(arg, self.flag),
  }
  // switch out.arg_type {
  //   case .Short:

  //   case .Long:
  //   case .Invalid:
  //     case .
  // }
  // if out.arg_type == .Short || out.arg_type == .Long {
  //   fuko := _getUnambiguousKeywordOption(self, arg)
  //   out.option = fuko.option
  // } else {

  // }
  return out
}
*/

/*
ParsedArgs :: struct {
  known:      map[string][dynamic]string,
  unknown:    [dynamic]string,
  _allocator: runtime.Allocator,
}

makeParsedArgs :: proc(allocator := context.allocator) -> ParsedArgs {
  out := ParsedArgs {
    known      = make(map[string][dynamic]string, 0, allocator),
    unknown    = make([dynamic]string, allocator),
    _allocator = allocator,
  }
  return out
}

deleteParsedArgs :: proc(self: $T/^ParsedArgs) {
  if self == nil {
    return
  }
  for k, v in &self.known {
    delete(v, self._allocator)
  }
  delete(self.known)
  delete(self.unknown, self._allocator)
}
*/


/*
@(require_results)
parseKnownArgs :: proc(self: $T/^ArgumentParser, args: []string, allocator := context.allocator) -> (out: map[string]string, ok: bool) {
  context.allocator = context.temp_allocator
  out := makeParsedArgs(allocator=allocator)
  ok = true
  arg_idx := 0
  used_args :=
  arg_loop: for arg_idx < len(args) {
    arg := args[arg_idx]
    arg_idx += 1
    // found_values := trie.getAllValuesWithPrefix(&self._kw_trie, arg)
    // found_arg_idx := -1
    flag_type := _getFlagType(arg, )
    opt_type := _getOp
    option := _getUnambiguousOption(self, arg)
    if option==nil {
      append(&out.unknown_args)
    }
    switch len(found_values) {
    case 0:
      log.debugf("Unknown argument:\"%v\"", arg)
      append(&unknown_args, arg)
      ok = false
    case 1:
      found_arg_idx = found_values[0]
    case:
      // TODO re-address bounds here....
      append(&unknown_args, arg)
      {
        ambiguous_args := make([dynamic]string)
        append(&line, "Ambiguous arguments:[")
        for found_idx, idx in found_values {
          if found_idx < 0 || found_idx >= len(self.options) {
            log.warnf("Found invalid index. Skipping")
            continue
          }
          option := &self.options[found_idx]
          for flag in option.flags {
            if len(ambiguous_args) == 0 {
              append(&ambiguous_args, fmt.tprintf("\"%v\"", flag))
            } else {
              append(&ambiguous_args, fmt.tprintf(", \"%v\"", flag))
            }
          }
        }
        log.errorf("Found amgiguous arguments for arg:\"%v\". Options:%v", arg, ambiguous_args)
      }
      ok = false
    case:
      log.errorf("Invalid arg:\"%v\"", arg)
      append(&unknown_args, arg)
      ok = false
    }
    if found_arg_idx < 0 || found_arg_idx >= len(self.options) {
      log.warnf("Found invalid index. Skipping")
      ok = false
      continue
    }
    option := &self.options[found_arg_idx]
    switch option.action {
    case .StoreTrue:
      out[option.dest] = true
    case .StoreFalse:
      out[option.dest] = false
    case .StoreConst:
      out[option.dest] = "const" // TODO: option.constant_value
    case .Help:
      fmt.print(getHelp(self))
      ok = false
      break arg_loop
    case .Version:
    // TODO
    case .Store:
    // TODO
    }
  }
  if !ok {
    delete(out)
    delete(unknown_args)
  }
  return
}
*/
