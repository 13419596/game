// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_argparse

@(private)
_isequal_slice :: proc(lhs, rhs: $T/[]$S) -> bool {
  if len(lhs) != len(rhs) {
    return false
  }
  for lv, idx in lhs {
    if lv != rhs[idx] {
      return false
    }
  }
  return true
}

@(private)
_isequal_dynamic :: proc(lhs, rhs: $T/[dynamic]$S) -> bool {
  return _isequal_slice(lhs[:], rhs[:])
}


@(private)
isequal_slice :: proc {
  _isequal_slice,
  _isequal_dynamic,
}

@(private)
_isequal_slice2 :: proc(lhs, rhs: $T/[][]$S) -> bool {
  if len(lhs) != len(rhs) {
    return false
  }
  for lv, idx in lhs {
    if !isequal_slice(lv, rhs[idx]) {
      return false
    }
  }
  return true
}

@(private)
_isequal_dynamic2 :: proc(lhs, rhs: $T/[][dynamic]$S) -> bool {
  if len(lhs) != len(rhs) {
    return false
  }
  for lv, idx in lhs {
    if !isequal_slice(lv[:], rhs[idx][:]) {
      return false
    }
  }
  return true
}

@(private)
isequal_slice2 :: proc {
  _isequal_slice2,
  _isequal_dynamic2,
}
