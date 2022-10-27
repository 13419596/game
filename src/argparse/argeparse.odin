package argparse

import "core:os"
import "core:runtime"
import "core:strings"
import "core:path/filepath"

import "game:trie"

ArgumentParser :: struct {
  prog:          string, // The name of the program (default: sys.argv[0])
  description:   string, // A usage message (default: auto-generated from arguments)
  epilog:        string, // Text following the argument descriptions
  prefix_chars:  rune, // Characters that prefix optional arguments
  add_help:      bool, // Add a -h/-help option
  allow_abbrev:  bool, // Allow long options to be abbreviated unambiguously
  exit_on_error: bool,
  _allocator:    runtime.Allocator,
}

@(require_results)
makeArgumentParser :: proc(
  prog: Maybe(string) = nil,
  description: string = "",
  epilog: string = "",
  prefix_chars: rune = '-',
  add_help: bool = true,
  allow_abbrev: bool = true,
  exit_on_error: bool = true,
  allocator := context.allocator,
) -> ArgumentParser {
  using strings
  out := ArgumentParser {
    prog = {},
    description = clone(description),
    epilog = clone(epilog),
    prefix_chars = prefix_chars,
    add_help = add_help,
    allow_abbrev = allow_abbrev,
    _allocator = allocator,
  }
  if prog, ok := prog.(string); ok {
    out.prog = clone(prog)
  } else {
    out.prog = clone(filepath.stem(os.args[0]))
  }
  return out
}

deleteArgumentParser :: proc(parser: ^$T/ArgumentParser) {
  delete(parser.prog)
  parser.prog = {}
  delete(parser.description)
  parser.description = {}
  delete(parser.epilog)
  parser.epilog = {}
}
