package gmath

import "core:intrinsics"
import "core:math"
import "game:util"

powIntegerExponent :: proc(base: $T, power: int) -> T {
  // calculates powers of integers wihtout relying on core:math pow definitions
  using util
  if power == 1 {
    // if power is 1, return base
    return base
  } else if base == 0 {
    // 0^+ = 0
    // 0^0 = 1  (technically an error, but in the limit it equals this)
    // 0^- = nan
    if power > 0 {
      when intrinsics.type_is_float(T) {
        return initFloat(0., T) // odin float init workaround
      } else {
        return T(0)
      }
    } else if power == 0 {
      when intrinsics.type_is_float(T) {
        return initFloat(1., T) // odin float init workaround
      } else {
        return T(1.)
      }
    } else {   // 0^-
      when intrinsics.type_is_float(T) {
        return initFloat(math.nan_f64(), T) // odin float init workaround
      } else {
        return T(math.nan_f64())
      }
    }
  } else if isnan(base) {
    return base
  } else if isinf(base) {
    if power < 0 {
      when intrinsics.type_is_float(T) {
        return initFloat(0., T) // odin float init workaround
      } else {
        return T(0.)
      }
    } else if power == 0 {
      when intrinsics.type_is_float(T) {
        return initFloat(math.nan_f64(), T) // odin float init workaround
      } else {
        return T(math.nan_f64())
      }
    }
  } else if power == 0 {
    when intrinsics.type_is_float(T) {
      return initFloat(1., T)
    } else {
      return T(1.)
    }
  }
  when intrinsics.type_is_integer(T) {
    if power < 0 {
      return T(0)
    }
  }
  when intrinsics.type_is_float(T) || intrinsics.type_is_complex(T) || intrinsics.type_is_quaternion(T) {
    if isinf(base) && power <= 0 {
      return power < 0 ? T(0) : T(math.nan_f64())
    }
  }
  non_neg_power := power >= 0
  scale := non_neg_power ? base : 1. / base
  power := non_neg_power ? power : -power
  when intrinsics.type_is_float(T) {
    scale = initFloat(non_neg_power ? f64(base) : f64(1.) / f64(base), T) // odin float init workaround
  }
  out := scale
  for n in 2 ..= power {
    out *= scale
  }
  return out
}

pow2int :: proc(power: int) -> f64 {
  return powIntegerExponent(2., power)
}

pow10int :: proc(power: int) -> f64 {
  return powIntegerExponent(10., power)
}
