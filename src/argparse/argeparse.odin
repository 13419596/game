package argparse

import "core:os"
import "core:strings"
import "core:path/filepath"


ArgumentAction :: enum {
  Store,
  // This just stores the argument’s value. This is the default action. For example:
  StoreConst,
  // This stores the value specified by the const keyword argument. The 'store_const' action is most commonly used with optional arguments that specify some sort of flag. For example:
  StoreTrue,
  StoreFalse,
  // These are special cases of 'store_const' used for storing the values True and False respectively. In addition, they create default values of False and True respectively. For example:
  Append,
  // This stores a list, and appends each argument value to the list. This is useful to allow an option to be specified multiple times. Example usage:
  AppendConst,
  // This stores a list, and appends the value specified by the const keyword argument to the list. (Note that the const keyword argument defaults to None.) The 'append_const' action is typically useful when multiple arguments need to store constants to the same list. For example:
  Count,
  // This counts the number of times a keyword argument occurs. For example, this is useful for increasing verbosity levels:
  Help,
  // This prints a complete help message for all the options in the current parser and then exits. By default a help action is automatically added to the parser. See ArgumentParser for details of how the output is created.
  Version,
  // This expects a version= keyword argument in the add_argument() call, and prints version information and exits when invoked:
  Extend,
  // This stores a list, and extends each argument value to the list. Example usage:
}

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

makeArgumentOption :: proc(option_strings: []string, action: ArgumentAction = ArgumentAction.Store, required: bool = false) -> ArgumentOption {
  using strings
  out := ArgumentOption {
    option_strings = make([dynamic]string, 0, len(option_strings)),
    action         = action,
    required       = required,
    // help=strings.clone(strings),
  }
  // for option_string in option_strings {
  //   append(&out.option_strings, clone(option_string))
  // }
  return out
}

deleteArgumentOption :: proc(arg_option: ^ArgumentOption) {
  for _, index in arg_option.option_strings {
    option_string := arg_option.option_strings[index]
    delete(option_string)
  }
  delete(arg_option.option_strings)
  delete(arg_option.help)
}

//////////////////////////////////////////////////////////////////


ArgumentParser :: struct {
  prog:          string, // The name of the program (default: sys.argv[0])
  description:   string, // A usage message (default: auto-generated from arguments)
  epilog:        string, // Text following the argument descriptions
  prefix_chars:  rune, // Characters that prefix optional arguments
  add_help:      bool, // Add a -h/-help option
  allow_abbrev:  bool, // Allow long options to be abbreviated unambiguously
  exit_on_error: bool,
}

makeArgumentParser :: proc(
  prog: Maybe(string) = nil,
  description: string = "",
  epilog: string = "",
  prefix_chars: rune = '-',
  add_help: bool = true,
  allow_abbrev: bool = true,
  exit_on_error: bool = true,
) -> ArgumentParser {
  using strings
  out := ArgumentParser {
    prog = {},
    description = clone(description),
    epilog = clone(epilog),
    prefix_chars = prefix_chars,
    add_help = add_help,
    allow_abbrev = allow_abbrev,
  }
  if prog, ok := prog.(string); ok {
    out.prog = clone(prog)
  } else {
    out.prog = clone(filepath.stem(os.args[0]))
  }
  return out
}

deleteArgumentParser :: proc(parser: ^ArgumentParser) {
  delete(parser.prog)
  parser.prog = {}
  delete(parser.description)
  parser.description = {}
  delete(parser.epilog)
  parser.epilog = {}
}
