package gstrconv

import "core:strings"
import "core:strconv"
import "game:gmath"
import "core:fmt"

@(private = "file")
nan: f64
@(private = "file")
inf: f64

@(init, private = "file")
_initConstants :: proc() {
  using gmath
  info := finfo(f64)
  nan = info.nan
  inf = info.inf
}

parse_f64 :: proc(str: string, n: ^int = nil) -> (value: f64, ok: bool) {
  value, ok = strconv.parse_f64(str, n)
  if ok {
    return
  }
  if len(str) < 3 {
    ok = false
    return
  }
  lower_str := strings.to_lower(str, context.temp_allocator) // should I use the temp allocator thing here?
  // check for nan or inf
  if strings.compare(lower_str, "nan") == 0 {
    value = nan
    ok = true
    return
  }
  sign := (lower_str[0] == '-') ? -1. : +1.
  if lower_str[0] == '-' || lower_str[0] == '+' {
    lower_str = lower_str[1:]
  }
  if strings.compare(lower_str, "inf") == 0 || strings.compare(lower_str, "infinity") == 0 {
    value = sign * inf
    ok = true
    return
  }
  return
}

parse_f32 :: proc(str: string, n: ^int = nil) -> (value: f32, ok: bool) {
  value, ok = strconv.parse_f32(str, n)
  if ok {
    return
  }
  if len(str) < 3 {
    ok = false
    return
  }
  lower_str := strings.to_lower(str, context.temp_allocator) // should I use the temp allocator thing here?
  // check for nan or inf
  if strings.compare(lower_str, "nan") == 0 {
    value = type_of(value)(nan)
    ok = true
    return
  }
  sign := (lower_str[0] == '-') ? -1. : +1.
  if lower_str[0] == '-' || lower_str[0] == '+' {
    lower_str = lower_str[1:]
  }
  if strings.compare(lower_str, "inf") == 0 || strings.compare(lower_str, "infinity") == 0 {
    value = type_of(value)(sign * inf)
    ok = true
    return
  }
  return
}
