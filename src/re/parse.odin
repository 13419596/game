package re

import "core:log"

parseUnprefixedInt :: proc(str: string, n: ^int = nil) -> (value: int, ok: bool) {
  // okay if parsed int successfully. 
  // Does not care if there is trailing characters only that there was a valid
  // matches (0|[1-9][0-9]*)
  ok = false
  len_s := len(str)
  if len_s == 0 {
    log.debug("Unable to parse. String is empty")
    return
  } else if (len_s >= 2 && str[0:2] == "00") {
    // no length or multiple leading 0's
    log.debug("Unable to parse. Leading zeros are not allowed.")
    return
  }

  value = 0
  idx := 0
  for rn in str {
    v := u32(rn)
    if 48 <= v && v < 58 {
      if idx == 0 {
        // first char is non-zero, ok
        ok = true
      }
      value *= 10
      value += (int(v) - 48) // cast is okay because value is bounded
      idx += 1 // size of runes 0-9 == 1
    } else {
      // either end of number or never started
      if idx == 0 {
        log.debugf("Unable to parse. Invalid starting rune:'%v'.", rn)
        ok = false
        break
      } else {
        break
      }
    }
  }
  if n != nil {
    n^ = idx
  }
  return
}
