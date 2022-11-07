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
_DEFAULT_EQUALITY_RUNE: rune : '='

@(private)
_TrieValueType :: string

ArgumentParser :: struct {
  prog:           string, // The name of the program (default: sys.argv[0])
  description:    string, // A usage message (default: auto-generated from arguments)
  epilog:         string, // Text following the argument descriptions
  allow_abbrev:   bool, // Allow long options to be abbreviated unambiguously
  exit_on_error:  bool,
  options:        map[string]ArgumentOption,
  _allocator:     runtime.Allocator,
  _kw_trie:       trie.Trie(int, _TrieValueType), // int(rune) -> int option index
  _equality_rune: rune, // Character that separates arguments from value typically '='
  _prefix_rune:   rune, // Character that prefix optional arguments
  _cache_usage:   Maybe(string),
  _cache_help:    Maybe(string),
}

@(require_results)
makeArgumentParser :: proc(
  prog := Maybe(string){},
  description: string = "",
  epilog: string = "",
  prefix_rune: rune = _DEFAULT_PREFIX_RUNE,
  equality_rune: rune = _DEFAULT_EQUALITY_RUNE,
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
    allow_abbrev = allow_abbrev,
    options = make(map[string]ArgumentOption, 0, allocator),
    _prefix_rune = prefix_rune,
    _equality_rune = equality_rune,
    _allocator = allocator,
    _kw_trie = trie.makeTrie(int, _TrieValueType, allocator),
  }
  if prog, ok := prog.?; ok {
    out.prog = clone(prog, allocator)
  } else {
    out.prog = clone(filepath.base(os.args[0]), allocator)
  }
  if add_help {
    option, opt_ok := addArgument(
      self = &out,
      flags = {fmt.tprintf("%vh", prefix_rune), fmt.tprintf("%v%vhelp", prefix_rune, prefix_rune)},
      action = .Help,
      help = "show this help message and exit",
    )
    if option == nil || !opt_ok {
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
) -> (
  out: ^ArgumentOption,
  ok: bool,
) {
  out = nil
  ok = false
  option, arg_ok := makeArgumentOption(
    flags = flags,
    dest = dest,
    nargs = nargs,
    action = action,
    required = required,
    help = help,
    prefix = self._prefix_rune,
    allocator = self._allocator,
  )
  if !arg_ok {
    deleteArgumentOption(&option)
    return
  }
  ok = true
  if !option._is_positional {
    for flag, flag_idx in option.flags {
      found_value, found_ok := trie.getValue(&self._kw_trie, flag)
      if !found_ok || found_value not_in self.options {
        continue
      }
      log.errorf("New option flag:%q conflicts with existing option flags:%v", flag, found_value)
      ok = false
      break
    }
  }
  // Check if dest conflicts
  if option.dest in self.options {
    // TODO(feature) allow for overriding options
    log.errorf("New option dest:%q conflicts with existing options", option.dest)
    ok = false
  }
  if !ok {
    deleteArgumentOption(&option)
    return
  }
  self.options[option.dest] = option
  for flag in option.flags {
    trie.setValue(&self._kw_trie, flag, option.dest)
  }
  out = &self.options[option.dest]
  ok = true
  return
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

ParsedData :: union {
  bool,
  int,
  string,
  [dynamic]string,
  [dynamic][dynamic]string,
}

ParsedOuptut :: struct {
  data:        map[string]ParsedData,
  unknown:     [dynamic]string,
  should_quit: bool,
  _allocator:  runtime.Allocator,
}


@(require_results)
_makeParseOutput :: proc(allocator := context.allocator) -> ParsedOuptut {
  out := ParsedOuptut {
    _allocator = allocator,
  }
  return out
}

deleteParsedOutput :: proc(self: $T/^ParsedOuptut) {
  if self == nil {
    return
  }
  for _, any_data in &self.data {
    switch data in &any_data {
    case bool:
    case int:
    case string:
      delete(data)
    case [dynamic]string:
      for str in data {
        delete(str)
      }
      delete(data)
    case [dynamic][dynamic]string:
      for strs in data {
        for str in strs {
          delete(str)
        }
        delete(strs)
      }
      delete(data)
    }
  }
  for unk in &self.unknown {
    delete(unk)
  }
  delete(self.unknown)
}

@(require_results, private = "file")
_cloneSlice :: proc(data: []$T, allocator := context.allocator) -> [dynamic]T {
  using strings
  out := make([dynamic]T, len(data), allocator)
  when T == string {
    // clone strings specfically
    for d, idx in data {
      out[idx] = clone(d, allocator)
    }
  } else {
    for d, idx in data {
      out[idx] = d
    }
  }
  return out
}

@(require_results, private = "file")
_cloneSliceDymamic :: proc(data: [][dynamic]$T, allocator := context.allocator) -> [dynamic][dynamic]T {
  out := make([dynamic][dynamic]T, len(data), allocator)
  for dat, idx in data {
    out[idx] = _cloneSlice(dat[:], allocator)
  }
  return out
}


@(require_results)
parseKnownArgs :: proc(self: $T/^ArgumentParser, args: []string, allocator := context.allocator) -> (out: ParsedOuptut, ok: bool) {
  context.allocator = context.temp_allocator
  dest2proc := make(map[string]_OptionProcessingState)
  defer {
    for k, v in &dest2proc {
      _deleteOptionProcessingState(&v)
    }
    delete(dest2proc)
  }
  tmp_unknown := make([dynamic]string)
  mtrailer := Maybe(string){}
  ok = true
  arg_idx := 0
  arg_loop: for arg_idx < len(args) {
    initial_arg_idx := arg_idx
    arg_or_trailer := args[arg_idx]
    log.infof("ARG[%v]:%q", arg_idx, arg_or_trailer)
    arg_idx += 1
    // if trailer, trailer_ok := mtrailer.?; trailer_ok {
    //   // TOOD check if short flag previously processed & had trailer
    // } else {
    //   arg_idx += 1
    // }
    fko, fko_ok := _determineKeywordOption(
      kw_trie = &self._kw_trie,
      arg = arg_or_trailer,
      prefix_rune = self._prefix_rune,
      equality_rune = self._equality_rune,
    )
    log.debugf("FKO: %v", fko)
    if !fko_ok {
      append(&tmp_unknown, arg_or_trailer)
      continue
    }
    dest := fko.value
    option, option_found := self.options[dest]
    if !option_found {
      ok = false
      break arg_loop
    }
    if fko.removed_equal_prefix {
      // log warnings for args that don't expect this kind of thing
      if upper, upper_ok := option.num_tokens.upper.?; upper_ok && upper == 0 {
        // expects no argument, but the -arg=trailer indicates user set something
        log.warnf(
          "Option %q takes no arguments, but arg[%v]=%q indicates otherwise. The trailing section will be ignored.",
          dest,
          initial_arg_idx,
          args[initial_arg_idx],
        )
      }
    }
    if dest not_in dest2proc {
      // create processing state
      proc_found_ok: bool
      dest2proc[dest], proc_found_ok = _makeOptionProcessingState_fromArgumentOption(&option)
      if !proc_found_ok {
        ok = false
        break arg_loop
      }
    }
    proc_state := &dest2proc[dest]
    proc_out, proc_ok := _processKeywordOption(option = &option, state = proc_state, trailer = fko.trailer, args = args[:arg_idx])
    if !proc_ok {
      ok = false
      break arg_loop
    }
    arg_idx += proc_out.num_consumed
  }
  for _, option in self.options {
    if option.required && option.dest not_in dest2proc {
      log.errorf("Required argument:%q was specified", option.dest)
      ok = false
      break
    }
  }
  for dest, proc_state in dest2proc {
    option, option_ok := self.options[dest]
    if !option_ok {
      ok = false
      break
    }
    switch option.action {
    case .Help:
      fmt.printf("%v\n", getHelp(self))
      out.should_quit = true
    case .Version:
      // TODO print version
      out.should_quit = true
    case .Extend:
    case .Append:
    case .Store:
    case .StoreFalse:
    case .StoreTrue:
    case .Count:
    }
  }
  log.warnf("proc states:%v", dest2proc)
  if out.should_quit || !ok {
    return
  }

  // Clone final results using specified allocator
  out.unknown = make([dynamic]string, len(tmp_unknown))
  out.unknown = _cloneSlice(tmp_unknown[:], allocator)
  out.data = make(map[string]ParsedData)
  for dest, proc_state in &dest2proc {
    switch data in proc_state.data {
    case bool:
      out.data[dest] = data
    case int:
      out.data[dest] = data
    case string:
      out.data[dest] = strings.clone(data, allocator)
    case [dynamic]string:
      out.data[dest] = _cloneSlice(data[:], allocator)
    case [dynamic][dynamic]string:
      out.data[dest] = _cloneSliceDymamic(data[:], allocator)
    }
  }
  return
}
