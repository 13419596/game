package gmath

import "core:math"
import "core:c/libc"
import "core:intrinsics"

////////////////////////
// to Complex 
toComplex_complex :: proc(x: $T) -> complex128 where intrinsics.type_is_complex(T) {
  return x
}

toComplex_int :: proc(x: $T) -> complex128 where !intrinsics.type_is_float(T) && !intrinsics.type_is_complex(T) {
  out := complex(f64(x), 0)
  return out
}

toComplex_other :: proc(x: $T) -> complex128 where intrinsics.type_is_float(T) {
  return complex128(x)
}

toComplex :: proc {
  toComplex_complex,
  toComplex_int,
  toComplex_other,
}

////////////////////////
// arccos
cacos_c64 :: proc(x: complex64) -> complex64 {
  return complex64(libc.cacosf(libc.complex_float(x)))
}

cacos_c128 :: proc(x: complex128) -> complex128 {
  return complex128(libc.cacos(libc.complex_double(x)))
}

cacos :: proc {
  math.acos,
  cacos_c64,
  cacos_c128,
}


////////////////////////
// arcsin
casin_c64 :: proc(x: complex64) -> complex64 {
  return complex64(libc.casinf(libc.complex_float(x)))
}

casin_c128 :: proc(x: complex128) -> complex128 {
  return complex128(libc.casin(libc.complex_double(x)))
}

casin :: proc {
  math.asin,
  casin_c64,
  casin_c128,
}


////////////////////////
// arctan
catan_c64 :: proc(x: complex64) -> complex64 {
  return complex64(libc.catanf(libc.complex_float(x)))
}

catan_c128 :: proc(x: complex128) -> complex128 {
  return complex128(libc.catan(libc.complex_double(x)))
}

catan :: proc {
  math.atan,
  catan_c64,
  catan_c128,
}


////////////////////////
// cos
ccos_c64 :: proc(x: complex64) -> complex64 {
  return complex64(libc.ccosf(libc.complex_float(x)))
}

ccos_c128 :: proc(x: complex128) -> complex128 {
  return complex128(libc.ccos(libc.complex_double(x)))
}

ccos :: proc {
  ccos_c64,
  ccos_c128,
}


////////////////////////
// sin
csin_c64 :: proc(x: complex64) -> complex64 {
  return complex64(libc.csinf(libc.complex_float(x)))
}

csin_c128 :: proc(x: complex128) -> complex128 {
  return complex128(libc.csin(libc.complex_double(x)))
}

csin :: proc {
  csin_c64,
  csin_c128,
}


////////////////////////
// tan
ctan_c64 :: proc(x: complex64) -> complex64 {
  return complex64(libc.ctanf(libc.complex_float(x)))
}

ctan_c128 :: proc(x: complex128) -> complex128 {
  return complex128(libc.ctan(libc.complex_double(x)))
}

ctan :: proc {
  ctan_c64,
  ctan_c128,
}

////////////////////////
// arccosh
cacosh_c64 :: proc(x: complex64) -> complex64 {
  return complex64(libc.cacoshf(libc.complex_float(x)))
}

cacosh_c128 :: proc(x: complex128) -> complex128 {
  return complex128(libc.cacosh(libc.complex_double(x)))
}

cacosh :: proc {
  cacosh_c64,
  cacosh_c128,
}

////////////////////////
// arcsinh
casinh_c64 :: proc(x: complex64) -> complex64 {
  return complex64(libc.casinhf(libc.complex_float(x)))
}

casinh_c128 :: proc(x: complex128) -> complex128 {
  return complex128(libc.casinh(libc.complex_double(x)))
}

casinh :: proc {
  casinh_c64,
  casinh_c128,
}

////////////////////////
// arctanh
catanh_c64 :: proc(x: complex64) -> complex64 {
  return complex64(libc.catanhf(libc.complex_float(x)))
}

catanh_c128 :: proc(x: complex128) -> complex128 {
  return complex128(libc.catanh(libc.complex_double(x)))
}

catanh :: proc {
  catanh_c64,
  catanh_c128,
}

////////////////////////
// cosh
ccosh_c64 :: proc(x: complex64) -> complex64 {
  return complex64(libc.ccoshf(libc.complex_float(x)))
}

ccosh_c128 :: proc(x: complex128) -> complex128 {
  return complex128(libc.ccosh(libc.complex_double(x)))
}

ccosh :: proc {
  ccosh_c64,
  ccosh_c128,
}

////////////////////////
// sinh 
csinh_c64 :: proc(x: complex64) -> complex64 {
  return complex64(libc.csinhf(libc.complex_float(x)))
}

csinh_c128 :: proc(x: complex128) -> complex128 {
  return complex128(libc.csinh(libc.complex_double(x)))
}

csinh :: proc {
  math.sinh,
  csinh_c64,
  csinh_c128,
}

////////////////////////
// tan
ctanh_c64 :: proc(x: complex64) -> complex64 {
  return complex64(libc.ctanhf(libc.complex_float(x)))
}

ctanh_c128 :: proc(x: complex128) -> complex128 {
  return complex128(libc.ctanh(libc.complex_double(x)))
}

ctanh :: proc {
  math.tanh,
  ctanh_c64,
  ctanh_c128,
}

////////////////////////
// exp
cexp_c64 :: proc(x: complex64) -> complex64 {
  return complex64(libc.cexpf(libc.complex_float(x)))
}

cexp_c128 :: proc(x: complex128) -> complex128 {
  return complex128(libc.cexp(libc.complex_double(x)))
}

cexp :: proc {
  cexp_c64,
  cexp_c128,
}

////////////////////////
// ln -- odin math.log takes two arguments, so this is called ln instead
cln_c64 :: proc(x: complex64) -> complex64 {
  return complex64(libc.clogf(libc.complex_float(x)))
}

cln_c128 :: proc(x: complex128) -> complex128 {
  return complex128(libc.clog(libc.complex_double(x)))
}

cln :: proc {
  cln_c64,
  cln_c128,
}


////////////////////////
// pow
cpow :: proc(base: $T, power: $P) -> T where intrinsics.type_is_complex(T) {
  when intrinsics.type_is_integer(P) {
    return powIntegerExponent(base, power)
  } else when T == complex64 {
    return T(libc.cpowf(libc.complex_float(base), libc.complex_float(power)))
  } else {
    return T(libc.cpow(libc.complex_double(base), libc.complex_double(power)))
  }
}

////////////////////////
// sqrt
csqrt_c64 :: proc(x: complex64) -> complex64 {
  return complex64(libc.csqrtf(libc.complex_float(x)))
}

csqrt_c128 :: proc(x: complex128) -> complex128 {
  return complex128(libc.csqrt(libc.complex_double(x)))
}

csqrt :: proc {
  csqrt_c64,
  csqrt_c128,
}

////////////////////////
// arg
// equivalent to atan2(imag(z), real(z))
carg_c64 :: proc(x: complex64) -> f32 {
  return f32(libc.cargf(libc.complex_float(x)))
}

carg_c128 :: proc(x: complex128) -> f64 {
  return f64(libc.carg(libc.complex_double(x)))
}

carg :: proc {
  carg_c64,
  carg_c128,
}

////////////////////////
// proj
cproj_c64 :: proc(x: complex64) -> complex64 {
  return complex64(libc.cprojf(libc.complex_float(x)))
}

cproj_c128 :: proc(x: complex128) -> complex128 {
  return complex128(libc.cproj(libc.complex_double(x)))
}

cproj :: proc {
  cproj_c64,
  cproj_c128,
}

////////////////////////
// cbrt
ccbrt :: proc(z: $C) -> C where intrinsics.type_is_comparable(C) {
  // q^(1./3.) = (exp(ln(q^(1./3.)))) = exp(ln(q)/3.)
  if z == 0. {
    return C{}
  } else {
    return cexp(cln(z) / 3.)
  }
}
