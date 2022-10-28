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
  prog: Maybe(string) = nil,
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
  nargs := Maybe(int){},
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
    // no de-alloc is necessary in this case, nothing should have been allocated
    return false
  }
  if trie.containsKey(&self._option_trie, arg_option.dest) {
    log.errorf("Conflicting option \"%v\"", arg_option.dest)
    // no de-alloc is necessary in this case, nothing should have been allocated
    return false
  }
  new_index := len(self.options)
  trie.setItem(&self._option_trie, arg_option.dest, new_index)
  append(&self.options, arg_option)
  return true
}

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
        append(&usage_pieces, _getHelpCache(&option))
      }
    }
  }
  if any_keywords {
    append(&lines, "")
    append(&lines, "keyword arguments:")
    for option in &self.options {
      if !option._is_positional {
        append(&usage_pieces, _getHelpCache(&option))
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
