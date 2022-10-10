package gmath

import "core:math"
import "core:intrinsics"
import "core:fmt"

isfinite_bool :: #force_inline proc(x: $T) -> bool where intrinsics.type_is_boolean(T) {
  return true
}

isfinite_int :: #force_inline proc(x: $T) -> bool where intrinsics.type_is_integer(T) {
  return true
}

isfinite_float :: #force_inline proc(x: $T) -> bool where intrinsics.type_is_float(T) {
  fc := math.classify(x)
  return fc == math.Float_Class.Zero || fc == math.Float_Class.Neg_Zero || fc == math.Float_Class.Normal || fc == math.Float_Class.Subnormal
}

isfinite_complex :: #force_inline proc(x: $T) -> bool where intrinsics.type_is_complex(T) {
  return isfinite_float(real(x)) && isfinite_float(imag(x))
}

isfinite_quaternion :: #force_inline proc(x: $T) -> bool where intrinsics.type_is_quaternion(T) {
  return isfinite_float(real(x)) && isfinite_float(imag(x)) && isfinite_float(jmag(x)) && isfinite_float(kmag(x))
}

isfinite :: proc {
  isfinite_bool,
  isfinite_int,
  isfinite_float,
  isfinite_complex,
  isfinite_quaternion,
}
