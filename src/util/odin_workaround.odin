package util

import "core:intrinsics"

initFloat :: proc(value: f64, $T: typeid) -> T {
  // casts float to correct value
  // Non-native endian floats do not work right, this is a necessary hack
  // to assign values or compare to literals, eg.
  // `x : f32be = 42.` or
  // `x < 32`
  return T(value)
}

initQuaternion :: proc(x: $X, y: $Y, z: $Z, w: $W, $Q: typeid) -> Q where (intrinsics.type_is_integer(X) || intrinsics.type_is_float(X)) &&
  (intrinsics.type_is_integer(Y) || intrinsics.type_is_float(Y)) &&
  (intrinsics.type_is_integer(Z) || intrinsics.type_is_float(Z)) &&
  (intrinsics.type_is_integer(W) || intrinsics.type_is_float(W)) &&
  intrinsics.type_is_quaternion(Q) {
  F :: intrinsics.type_elem_type(Q) // get f32/f64 from Q
  out: Q = Q{}
  out.x = F(x) // cast to base type
  out.y = F(y)
  out.z = F(z)
  out.w = F(w)
  return out
}
