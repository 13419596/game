// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_argparse

@(private)
isequal_slice :: proc(lhs, rhs: $T/[]$S) -> bool {
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
