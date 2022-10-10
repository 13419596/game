package gmath

import "core:math"
import "core:c/libc"
import "core:intrinsics"
import "game:util"

////////////////////////
// arg 
arg_f :: proc(x: $T) -> T where (intrinsics.type_is_integer(T) || intrinsics.type_is_float(T)) {
  out: T = 0.
  if x < 0 {
    out = util.initFloat(math.PI, T)
  }
  return out
}

arg :: proc {
  arg_f,
  carg_c64,
  carg_c128,
  qarg,
}


////////////////////////
// arccos

acos :: proc {
  math.acos,
  cacos_c64,
  cacos_c128,
}

////////////////////////
// arcsin

asin :: proc {
  math.asin,
  casin_c64,
  casin_c128,
}

////////////////////////
// arctan

atan :: proc {
  math.atan,
  catan_c64,
  catan_c128,
}

////////////////////////
// cos

cos :: proc {
  math.cos_f16,
  math.cos_f16le,
  math.cos_f16be,
  math.cos_f32,
  math.cos_f32le,
  math.cos_f32be,
  math.cos_f64,
  math.cos_f64le,
  math.cos_f64be,
  ccos_c64,
  ccos_c128,
}

////////////////////////
// sin

sin :: proc {
  math.sin_f16,
  math.sin_f16le,
  math.sin_f16be,
  math.sin_f32,
  math.sin_f32le,
  math.sin_f32be,
  math.sin_f64,
  math.sin_f64le,
  math.sin_f64be,
  csin_c64,
  csin_c128,
}

////////////////////////
// tan

tan :: proc {
  math.tan_f16,
  math.tan_f16le,
  math.tan_f16be,
  math.tan_f32,
  math.tan_f32le,
  math.tan_f32be,
  math.tan_f64,
  math.tan_f64le,
  math.tan_f64be,
  ctan_c64,
  ctan_c128,
}

////////////////////////
// arccosh

acosh :: proc {
  math.acosh,
  cacosh_c64,
  cacosh_c128,
}

////////////////////////
// arcsinh

asinh :: proc {
  math.asinh,
  casinh_c64,
  casinh_c128,
}

////////////////////////
// arctanh

atanh :: proc {
  math.atanh,
  catanh_c64,
  catanh_c128,
}

////////////////////////
// cosh

cosh :: proc {
  math.cosh,
  ccosh_c64,
  ccosh_c128,
}

////////////////////////
// sinh 

sinh :: proc {
  math.sinh,
  csinh_c64,
  csinh_c128,
}

////////////////////////
// tan

tanh :: proc {
  math.tanh,
  ctanh_c64,
  ctanh_c128,
}

////////////////////////
// exp

exp :: proc {
  math.exp_f16,
  math.exp_f16le,
  math.exp_f16be,
  math.exp_f32,
  math.exp_f32le,
  math.exp_f32be,
  math.exp_f64,
  math.exp_f64le,
  math.exp_f64be,
  cexp_c64,
  cexp_c128,
  qexp,
}

////////////////////////
// ln -- odin math.log takes two arguments, so this is called ln instead

ln :: proc {
  math.ln_f16,
  math.ln_f16le,
  math.ln_f16be,
  math.ln_f32,
  math.ln_f32le,
  math.ln_f32be,
  math.ln_f64,
  math.ln_f64le,
  math.ln_f64be,
  cln_c64,
  cln_c128,
  qln,
}

////////////////////////
// pow

pow :: proc {
  math.pow_f16,
  math.pow_f16le,
  math.pow_f16be,
  math.pow_f32,
  math.pow_f32le,
  math.pow_f32be,
  math.pow_f64,
  math.pow_f64le,
  math.pow_f64be,
  cpow,
  qpow,
}

////////////////////////
// sqrt

sqrt :: proc {
  math.sqrt_f16,
  math.sqrt_f16le,
  math.sqrt_f16be,
  math.sqrt_f32,
  math.sqrt_f32le,
  math.sqrt_f32be,
  math.sqrt_f64,
  math.sqrt_f64le,
  math.sqrt_f64be,
  csqrt_c64,
  csqrt_c128,
  qsqrt,
}

////////////////////////
// cbrt
cbrt :: proc(x: $T) -> T {
  // no builtins for this, so just do it using pow
  if x == 0 {
    return T(0)
  }
  E :: intrinsics.type_elem_type(T)
  nn_x := x / T(abs(x))
  when intrinsics.type_is_float(T) {
    return nn_x * pow(abs(x), util.initFloat(1. / 3., T))
  } else when intrinsics.type_is_complex(T) {
    return ccbrt(x)
  } else when intrinsics.type_is_quaternion(T) {
    return qcbrt(x)
  } else {
    assert(false, "unimplemented")
  }
}
