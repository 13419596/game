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
_DEFAULT_PREFIX_RUNE: rune = '-'

ArgumentParser :: struct {
  prog:          string, // The name of the program (default: sys.argv[0])
  description:   string, // A usage message (default: auto-generated from arguments)
  epilog:        string, // Text following the argument descriptions
  prefix_rune:   rune, // Character that prefix optional arguments
  add_help:      bool, // Add a -h/-help option
  allow_abbrev:  bool, // Allow long options to be abbreviated unambiguously
  exit_on_error: bool,
  options:       [dynamic]ArgumentOption,
  _allocator:    runtime.Allocator,
  _option_trie:  trie.Trie(int, int), // int(rune) -> int option index
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
    options = make([dynamic]ArgumentOption, allocator),
    _allocator = allocator,
    _option_trie = trie.makeTrie(int, int, allocator),
  }
  if prog, ok := prog.(string); ok {
    out.prog = clone(prog, allocator)
  } else {
    out.prog = clone(filepath.stem(os.args[0]), allocator)
  }
  if add_help {
    ok = addArgument(
      self = &out,
      flags = {fmt.tprintf("%vh", prefix_rune), fmt.tprintf("%v%vhelp", prefix_rune, prefix_rune)},
      action = .Help,
      help = "show this help message and exit",
    )
    if !ok {
      deleteArgumentParser(&out)
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
  for _, idx in self.options {
    deleteArgumentOption(&self.options[idx])
  }
  delete(self.options)
  self.options = {}
  trie.deleteTrie(&self._option_trie)
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
  required := false,
  dest := Maybe(string){},
  help := Maybe(string){},
) -> bool {
  arg_option, arg_ok := makeArgumentOption(
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
    deleteArgumentOption(&arg_option)
    return false
  }
  ok := true
  for flag, flag_idx in arg_option.flags {
    found_value, found_ok := trie.getValue(&self._option_trie, flag)
    if !found_ok {
      continue
    }
    if found_value < 0 || found_value >= len(self.options) {
      log.errorf("Found conflicting value that corresponds to invalid index:%v.", found_value)
      ok = false
      break
    }
    conflicting_option := &self.options[found_value]
    log.errorf("New option flag:\"%v\" conflicts with existing option flags:%v", flag, conflicting_option.flags)
    ok = false
    break
  }
  if !ok {
    deleteArgumentOption(&arg_option)
    return false
  }
  new_index := len(self.options)
  append(&self.options, arg_option)
  for flag in arg_option.flags {
    trie.setValue(&self._option_trie, flag, new_index)
  }
  return true
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
  for option in &self.options {
    if !option._is_positional {
      append(&usage_pieces, _getUsageString(&option))
    }
  }
  // print then positionals
  for option in &self.options {
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
    for option in &self.options {
      if !option._is_positional {
        any_keywords = true
        break
      }
    }
    // print then positionals
    for option in &self.options {
      if option._is_positional {
        any_positionals = true
        break
      }
    }
  }
  lines := make([dynamic]string)
  append(&lines, getUsage(self))
  if any_positionals {
    append(&lines, "")
    append(&lines, "positional arguments:")
    for option in &self.options {
      if option._is_positional {
        append(&lines, _getHelpCache(&option))
      }
    }
  }
  if any_keywords {
    append(&lines, "")
    append(&lines, "keyword arguments:")
    for option in &self.options {
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

@(require_results)
parseKnownArgs :: proc(self: $T/^ArgumentParser, args: []string, allocator := context.allocator) -> (out: map[string]string, ok: bool) {
  context.allocator = context.temp_allocator
  out := make(map[string]string, allocator)
  arg_idx := 0
  unknown_args := make([dynamic]string, allocator)
  ok = true
  arg_loop: for arg_idx < len(args) {
    arg := args[arg_idx]
    arg_idx += 1
    found_values := trie.getAllValuesWithPrefix(&self._option_trie, arg)
    found_arg_idx := -1
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
