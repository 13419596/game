package re

Pattern :: struct($T: typeid) {
  raw_pattern: T,
  flags:       RegexFlags,
}

compile :: proc(pattern: $T, flags: RegexFlag) -> Pattern(T) {
  out := Pattern {
    raw_pattern = pattern,
    flags       = flags,
  }
  return out
}

// 'findall', 'finditer', 'flags', 'fullmatch', 'groupindex', 'groups', 'match', 'pattern', 'scanner', 'search', 'split', 'sub', 'subn'
