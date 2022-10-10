package gmath

import "core:math"
import "core:intrinsics"

isnormal_bool :: proc(x: $T) -> bool where intrinsics.type_is_boolean(T) {
  return true
}

isnormal_int :: proc(x: $T) -> bool where intrinsics.type_is_integer(T) {
  return true
}

isnormal_float :: proc(x: $T) -> bool where intrinsics.type_is_float(T) {
  // float normal is .Normal or ±.Zero, excludes subnormal numbers
  fc := math.classify(x)
  return fc == math.Float_Class.Zero || fc == math.Float_Class.Neg_Zero || fc == math.Float_Class.Normal
}

isnormal_complex :: proc(x: $T) -> bool where intrinsics.type_is_complex(T) {
  // normal if all parts are normal
  return isnormal_float(real(x)) && isnormal_float(imag(x))
}

isnormal_quaternion :: proc(x: $T) -> bool where intrinsics.type_is_quaternion(T) {
  // normal if all parts are normal
  return isnormal_float(real(x)) && isnormal_float(imag(x)) && isnormal_float(jmag(x)) && isnormal_float(kmag(x))
}

isnormal :: proc {
  isnormal_bool,
  isnormal_int,
  isnormal_float,
  isnormal_complex,
  isnormal_quaternion,
}
