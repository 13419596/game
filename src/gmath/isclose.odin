package gmath

import "core:fmt"
import "core:intrinsics"
import "core:math"

DEFAULT_RTOL :: 1.e-5
DEFAULT_ATOL :: 1.e-8
DEFAULT_EQUAL_NAN :: true

isclose :: proc(
  lhs, rhs: $T,
  rtol: f64 = DEFAULT_RTOL,
  atol: f64 = DEFAULT_ATOL,
  equal_nan: bool = DEFAULT_EQUAL_NAN,
) -> bool where intrinsics.type_is_boolean(T) ||
  intrinsics.type_is_integer(T) ||
  intrinsics.type_is_float(T) ||
  intrinsics.type_is_complex(T) ||
  intrinsics.type_is_quaternion(T) {
  // absolute(lhs - rhs) <= (atol + rtol * absolute(rhs))
  when intrinsics.type_is_boolean(T) {
    return lhs == rhs
  } else when intrinsics.type_is_integer(T) || intrinsics.type_is_float(T) {
    isnan_lhs := isnan(lhs)
    isnan_rhs := isnan(rhs)
    if isnan_lhs != isnan_rhs {
      return false
    } else if equal_nan && (isnan_lhs && isnan_rhs) {
      return true
    } else if (lhs == 0. && rhs == 0.) {
      return true
    }
    isinf_lhs := isinf(lhs)
    isinf_rhs := isinf(rhs)
    if isinf_lhs || isinf_rhs {
      // if either is inf, the must be equal to be close
      return lhs == rhs
    }
    adiff := f64(abs(lhs - rhs))
    out := adiff <= (atol + rtol * f64(abs(rhs)))
    return out
  } else when intrinsics.type_is_complex(T) {
    isnan_lhs := isnan(lhs)
    isnan_rhs := isnan(rhs)
    if isnan_lhs != isnan_rhs {
      return false
    } else if equal_nan && (isnan_lhs && isnan_rhs) {
      return true
    }
    return isclose(f64(real(lhs)), f64(real(rhs)), rtol, atol, equal_nan) && isclose(f64(imag(lhs)), f64(imag(rhs)), rtol, atol, equal_nan)
  } else when intrinsics.type_is_quaternion(T) {
    isnan_lhs := isnan(lhs)
    isnan_rhs := isnan(rhs)
    if isnan_lhs != isnan_rhs {
      return false
    } else if equal_nan && (isnan_lhs && isnan_rhs) {
      return true
    }
    return(
      isclose(f64(real(lhs)), f64(real(rhs)), rtol, atol, equal_nan) &&
      isclose(f64(imag(lhs)), f64(imag(rhs)), rtol, atol, equal_nan) &&
      isclose(f64(jmag(lhs)), f64(jmag(rhs)), rtol, atol, equal_nan) &&
      isclose(f64(kmag(lhs)), f64(kmag(rhs)), rtol, atol, equal_nan) \
    )
  } else {
    assert(false, "unimplmented")
  }
}

@(private = "file")
allclose_array :: proc(
  lhs, rhs: $A/[]$T,
  rtol: f64 = DEFAULT_RTOL,
  atol: f64 = DEFAULT_ATOL,
  equal_nan: bool = DEFAULT_EQUAL_NAN,
) -> bool where (intrinsics.type_is_boolean(T) ||
    intrinsics.type_is_integer(T) ||
    intrinsics.type_is_float(T) ||
    intrinsics.type_is_complex(T) ||
    intrinsics.type_is_quaternion(T)) {
  when intrinsics.type_is_boolean(T) {
    return lhs == rhs
  } else {
    if len(lhs) != len(rhs) {
      // todo should assert here?
      return false
    }
    for _, idx in lhs {
      lhs_v := lhs[idx]
      rhs_v := rhs[idx]
      if !isclose(lhs_v, rhs_v, rtol, atol, equal_nan) {
        return false
      }
    }
    return true
  }
}

@(private = "file")
allclose_matrix :: proc(
  lhs, rhs: ^matrix[$M, $N]$T,
  rtol: f64 = DEFAULT_RTOL,
  atol: f64 = DEFAULT_ATOL,
  equal_nan: bool = DEFAULT_EQUAL_NAN,
) -> bool where (intrinsics.type_is_boolean(T) ||
    intrinsics.type_is_integer(T) ||
    intrinsics.type_is_float(T) ||
    intrinsics.type_is_complex(T) ||
    intrinsics.type_is_quaternion(T)) {
  when intrinsics.type_is_boolean(T) {
    return lhs == rhs
  } else {
    for m in 0 ..< M {
      for n in 0 ..< N {
        lhs_v := lhs[m, n]
        rhs_v := rhs[m, n]
        if !isclose(lhs_v, rhs_v, rtol, atol, equal_nan) {
          return false
        }
      }
    }
    return true
  }
}

allclose :: proc {
  isclose,
  allclose_array,
  allclose_matrix,
}
