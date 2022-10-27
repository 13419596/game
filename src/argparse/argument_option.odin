package argparse

import "core:os"
import "core:runtime"
import "core:strings"
import "core:path/filepath"

import "game:trie"

ArgumentOption :: struct {
  option_strings: [dynamic]string,
  dest:           string,
  nargs:          int,
  constant_value: any,
  default:        any,
  // type
  choices:        [dynamic]any,
  action:         ArgumentAction,
  required:       bool,
  help:           string,
}

@(require_results)
makeArgumentOption :: proc(
  option_strings: []string,
  action: ArgumentAction = ArgumentAction.Store,
  required: bool = false,
  help: Maybe(string) = nil,
  allocator := context.allocator,
) -> ArgumentOption {
  using strings
  out_help: string = ""
  if shelp, ok := help.?; ok {
    out_help = clone(shelp, allocator)
  }
  out := ArgumentOption {
    option_strings = make([dynamic]string, 0, len(option_strings), allocator),
    action         = action,
    required       = required,
    help           = out_help,
  }
  for option_string in option_strings {
    append(&out.option_strings, clone(option_string, allocator))
  }
  return out
}

deleteArgumentOption :: proc(arg_option: $T/^ArgumentOption) {
  for _, idx in arg_option.option_strings {
    delete(arg_option.option_strings[idx])
  }
  delete(arg_option.option_strings)
  arg_option.option_strings = {}
  delete(arg_option.help)
  arg_option.help = {}
}
