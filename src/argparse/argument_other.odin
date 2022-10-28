package argparse

import "core:fmt"
import "core:log"
import "core:os"
import "core:runtime"
import "core:strings"
import "core:path/filepath"
import "core:unicode/utf8"

import "game:trie"

@(require_results)
_replaceRunes :: proc(s: string, old_runes: []rune, replacement: $R, allocator := context.allocator) -> string {
  context.allocator = context.temp_allocator
  replacement_str := fmt.tprintf("%v", replacement)
  line := make([dynamic]string)
  for rn, idx in s {
    added_rn := false
    for old_rn in old_runes {
      if rn == old_rn {
        append(&line, replacement_str)
        added_rn = true
        break
      }
    }
    if !added_rn {
      append(&line, s[idx:idx + 1])
    }
  }
  out := strings.join(line[:], "", allocator)
  return out
}
