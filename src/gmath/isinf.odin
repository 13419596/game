package gmath

import "core:math"
import "core:intrinsics"

//////////////

isinf_bool :: proc(x: $T) -> bool where intrinsics.type_is_boolean(T) {
  return false
}

isinf_int :: proc(x: $T) -> bool where intrinsics.type_is_integer(T) {
  return false
}

isinf_float :: proc(x: $T) -> bool where intrinsics.type_is_float(T) {
  // true if ±inf
  fc := math.classify(x)
  return fc == math.Float_Class.Inf || fc == math.Float_Class.Neg_Inf
}

isinf_complex :: proc(x: $T) -> bool where intrinsics.type_is_complex(T) {
  // true if any part is ±inf
  return isinf_float(real(x)) || isinf_float(imag(x))
}

isinf_quaternion :: proc(x: $T) -> bool where intrinsics.type_is_quaternion(T) {
  // true if any part is ±inf
  return isinf_float(real(x)) || isinf_float(imag(x)) || isinf_float(jmag(x)) || isinf_float(kmag(x))
}

isinf :: proc {
  isinf_bool,
  isinf_int,
  isinf_float,
  isinf_complex,
  isinf_quaternion,
}

//////////////

isposinf_bool :: proc(x: $T) -> bool where intrinsics.type_is_boolean(T) {
  return false
}

isposinf_int :: proc(x: $T) -> bool where intrinsics.type_is_integer(T) {
  return false
}

isposinf_float :: proc(x: $T) -> bool where intrinsics.type_is_float(T) {
  // true if +inf
  fc := math.classify(x)
  return fc == math.Float_Class.Inf
}

isposinf_complex :: proc(x: $T) -> bool where intrinsics.type_is_complex(T) {
  // true if any part is +inf
  return isposinf_float(real(x)) || isposinf_float(imag(x))
}

isposinf_quaternion :: proc(x: $T) -> bool where intrinsics.type_is_complex(T) {
  // true if any part is +inf
  return isposinf_float(real(x)) || isposinf_float(imag(x)) || isposinf_float(jmag(x)) || isposinf_float(kmag(x))
}

isposinf :: proc {
  isposinf_bool,
  isposinf_int,
  isposinf_float,
  isposinf_complex,
  isposinf_quaternion,
}

//////////////

isneginf_bool :: proc(x: $T) -> bool where intrinsics.type_is_boolean(T) {
  return false
}

isneginf_int :: proc(x: $T) -> bool where intrinsics.type_is_integer(T) {
  return false
}

isneginf_float :: proc(x: $T) -> bool where intrinsics.type_is_float(T) {
  // true if -inf
  fc := math.classify(x)
  return fc == math.Float_Class.Neg_Inf
}

isneginf_complex :: proc(x: $T) -> bool where intrinsics.type_is_complex(T) {
  // true if any part is -inf
  return isneginf_float(real(x)) || isneginf_float(imag(x))
}

isneginf_quaternion :: proc(x: $T) -> bool where intrinsics.type_is_complex(T) {
  // true if any part is -inf
  return isneginf_float(real(x)) || isneginf_float(imag(x)) || isneginf_float(jmag(x)) || isneginf_float(kmag(x))
}

isneginf :: proc {
  isneginf_bool,
  isneginf_int,
  isneginf_float,
  isneginf_complex,
  isneginf_quaternion,
}
