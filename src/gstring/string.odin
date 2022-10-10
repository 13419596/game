package gstring

import "core:strings"

removeSuffix :: proc(s, suffix: string) -> string {
  // returns slice
  if len(s) < len(suffix) {
    return s[0:0]
  }
  return s[:len(s) - len(suffix)]
}

endswith :: proc(s, suffix: string) -> bool {
  if len(s) < len(suffix) {
    return false
  }
  return strings.compare(s[len(s) - len(suffix):], suffix) == 0
}
