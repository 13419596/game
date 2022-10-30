package argparse

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

isArgumentActionComposed :: proc(action: ArgumentAction) -> bool {
  switch action {
  case .Store:
    fallthrough
  case .StoreConst:
    fallthrough
  case .StoreTrue:
    fallthrough
  case .StoreFalse:
    fallthrough
  case .Help:
    return false
  ///////////////////
  case .Append:
    fallthrough
  case .AppendConst:
    fallthrough
  case .Count:
    fallthrough
  case .Version:
    fallthrough
  case .Extend:
    return true
  }
  return false
}
