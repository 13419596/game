package gmath

import "core:math"
import "core:intrinsics"

isnan_bool :: proc(x: $T) -> bool where intrinsics.type_is_boolean(T) {
  return false
}

isnan_int :: proc(x: $T) -> bool where intrinsics.type_is_integer(T) {
  return false
}

isnan_float :: proc(x: $T) -> bool where intrinsics.type_is_float(T) {
  fc := math.classify(x)
  return fc == math.Float_Class.NaN
}

isnan_complex :: proc(x: $T) -> bool where intrinsics.type_is_complex(T) {
  // true if any part is nan
  return isnan_float(real(x)) || isnan_float(imag(x))
}

isnan_quaternion :: proc(x: $T) -> bool where intrinsics.type_is_quaternion(T) {
  // true if any part is nan
  return isnan_float(real(x)) || isnan_float(imag(x)) || isnan_float(jmag(x)) || isnan_float(kmag(x))
}

isnan :: proc {
  isnan_bool,
  isnan_int,
  isnan_float,
  isnan_complex,
  isnan_quaternion,
}
