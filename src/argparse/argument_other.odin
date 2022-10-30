package argparse

import "core:fmt"
import "core:strings"

@(require_results, private = "file")
_runesFromString :: proc(s: string, allocator := context.allocator) -> []rune {
  out := make([dynamic]rune, allocator)
  for rn in s {
    append(&out, rn)
  }
  return out[:]
}

@(require_results)
_normalizePrefix :: proc(s: string, old: union #no_nil {
    []rune,
    string,
  }, replacement: $R, max_prefix_len := 2, allocator := context.allocator) -> string {
  // replaces prefix runes in set with replacement rune
  context.allocator = context.temp_allocator
  using strings
  old_runes: []rune
  switch val in old {
  case []rune:
    old_runes = val
  case string:
    old_runes = _runesFromString(val)
  }
  tail_start_idx := -1
  prefix_rn_count := 0
  loop: for rn, idx in s {
    for old_rn in old_runes {
      if rn == old_rn {
        prefix_rn_count += 1
        continue loop
      }
    }
    tail_start_idx = idx
    break
  }
  pieces := make([dynamic]string)
  if prefix_rn_count > 0 {
    replacement_str := fmt.tprintf("%v", replacement)
    append(&pieces, repeat(replacement_str, prefix_rn_count))
  }
  if tail_start_idx != -1 {
    append(&pieces, s[tail_start_idx:])
  }
  out := join(pieces[:], "", allocator)
  return out
}
