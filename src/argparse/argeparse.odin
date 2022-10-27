package argparse

import "core:os"
import "core:runtime"
import "core:strings"
import "core:path/filepath"

import "game:trie"

@(private = "file")
_DEFAULT_DESCRIPTION: string = ""

@(private = "file")
_DEFAULT_EPILOG: string = ""

@(private = "file")
_DEFAULT_PREFIX_RUNE: rune = '-'

@(private = "file")
_DEFAULT_ALLOW_ABBREV: bool = true

@(private = "file")
_DEFAULT_ADD_HELP: bool = true

@(private = "file")
_DEFAULT_EXIT_ON_ERROR: bool = true

ArgumentParser :: struct {
  prog:          string, // The name of the program (default: sys.argv[0])
  description:   string, // A usage message (default: auto-generated from arguments)
  epilog:        string, // Text following the argument descriptions
  prefix_char:   rune, // Character that prefix optional arguments
  add_help:      bool, // Add a -h/-help option
  allow_abbrev:  bool, // Allow long options to be abbreviated unambiguously
  exit_on_error: bool,
  _allocator:    runtime.Allocator,
  options:       [dynamic]ArgumentOption,
}

@(require_results)
makeArgumentParser :: proc(
  prog: Maybe(string) = nil,
  description: string = _DEFAULT_DESCRIPTION,
  epilog: string = _DEFAULT_EPILOG,
  prefix_char: rune = _DEFAULT_PREFIX_RUNE,
  add_help: bool = _DEFAULT_ADD_HELP,
  allow_abbrev: bool = _DEFAULT_ALLOW_ABBREV,
  exit_on_error: bool = _DEFAULT_EXIT_ON_ERROR,
  allocator := context.allocator,
) -> ArgumentParser {
  using strings
  out := ArgumentParser {
    prog = {},
    description = clone(description, allocator),
    epilog = clone(epilog),
    prefix_char = prefix_char,
    add_help = add_help,
    allow_abbrev = allow_abbrev,
    options = make([dynamic]ArgumentOption, allocator),
    _allocator = allocator,
  }
  if prog, ok := prog.(string); ok {
    out.prog = clone(prog, allocator)
  } else {
    out.prog = clone(filepath.stem(os.args[0]), allocator)
  }
  return out
}

deleteArgumentParser :: proc(parser: $T/^ArgumentParser) {
  delete(parser.prog)
  parser.prog = {}
  delete(parser.description)
  parser.description = {}
  delete(parser.epilog)
  parser.epilog = {}
  delete(parser.options)
  parser.options = {}
}
