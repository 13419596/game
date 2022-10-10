package gmath

import "core:fmt"
import "core:intrinsics"
import "core:math"

@(private = "file")
_cnan := complex128(complex(math.nan_f64(), math.nan_f64()))

solveQuadratic :: proc(a: $A, b: $B, c: $C) -> [2]complex128 where intrinsics.type_is_numeric(A) &&
  intrinsics.type_is_numeric(B) &&
  intrinsics.type_is_numeric(C) {
  out: [2]complex128 = {_cnan, _cnan}
  if !(isfinite(a) && isfinite(b) && isfinite(c)) {
    fmt.printf("a:%v b:%v c:%v\n", a, b, c)
    return out
  }
  a := toComplex(a)
  b := toComplex(b)
  c := toComplex(c)
  if a != 0 {
    // 2 roots
    d: complex128 = b * b - 4 * a * c
    sd := sqrt(d)
    a *= 2
    out = {(-b + sd) / a, (-b - sd) / a}
  } else if b != 0 {
    // 1 root
    out[0] = -c / b
  }
  return out
}

// _xi_3_0 = 1.
@(private = "file")
_xi_3_1: complex128 = -.5 + math.SQRT_THREE / 2. * 1i
@(private = "file")
_xi_3_2: complex128 = -.5 - math.SQRT_THREE / 2. * 1i
// note that xi_3_1 = 1/xi_3_2

solveCubic :: proc(a: $A, b: $B, c: $C, d: $D) -> [3]complex128 where intrinsics.type_is_numeric(A) &&
  intrinsics.type_is_numeric(B) &&
  intrinsics.type_is_numeric(C) &&
  intrinsics.type_is_numeric(D) {
  out: [3]complex128 = {_cnan, _cnan, _cnan}
  if !(isfinite(a) && isfinite(b) && isfinite(c) && isfinite(d)) {
    return out
  }
  if a == 0 {
    quadratic_roots := solveQuadratic(b, c, d)
    out[0] = quadratic_roots[0]
    out[1] = quadratic_roots[1]
    return out
  }
  a := toComplex(a)
  b := toComplex(b)
  c := toComplex(c)
  d := toComplex(d)
  delta0 := b * b - 3 * a * c
  delta1 := 2 * (b * b * b) - 9 * (a * b * c) + 27 * (a * a) * d
  if delta0 == 0 && delta1 == 0 {
    //three roots all same
    out[0] = -b / (3 * a)
    out[1] = out[0]
    out[2] = out[0]
    return out
  }
  C := delta0 == 0 ? cbrt(delta1) : cbrt((delta1 + sqrt((delta1 * delta1) - 4 * (delta0 * delta0 * delta0))) / 2.)
  k := -1. / (3. * a)
  out[0] = k * (b + C + delta0 / C)
  out[1] = k * (b + _xi_3_1 * C + _xi_3_2 * delta0 / C)
  out[2] = k * (b + _xi_3_2 * C + _xi_3_1 * delta0 / C)
  return out
}
