package gmath

import "core:math"
import "core:intrinsics"

////////////////////////
// exp
qexp :: proc(q: $Q) -> Q where intrinsics.type_is_quaternion(Q) {
  w := real(q)
  x := imag(q)
  y := jmag(q)
  z := kmag(q)
  norm_v := math.sqrt(x * x + y * y + z * z)
  ew := math.exp(w)
  ew_cos_v := ew * math.cos(norm_v)
  ew_sin_v := norm_v != 0 ? ew / norm_v * math.sin(norm_v) : 0.
  out := Q{}
  out.w = ew_cos_v
  out.x = ew_sin_v * x
  out.y = ew_sin_v * y
  out.z = ew_sin_v * z
  return out
}

////////////////////////
// ln -- odin math.log takes two arguments, so this is called ln instead
qln :: proc(q: $Q) -> Q where intrinsics.type_is_quaternion(Q) {
  w := real(q)
  x := imag(q)
  y := jmag(q)
  z := kmag(q)
  norm_q := math.sqrt(w * w + x * x + y * y + z * z)
  norm_v := math.sqrt(x * x + y * y + z * z)
  k := norm_v != 0 ? math.acos(w / norm_q) / norm_v : 0.
  out := Q{}
  out.w = math.ln(norm_q)
  if norm_v == 0 && w < 0 {
    out.x = math.PI
  } else {
    out.x = x * k
  }
  out.y = y * k
  out.z = z * k
  return out
}


////////////////////////
// pow
qpow :: proc(z: $Q, power: $T) -> Q where intrinsics.type_is_quaternion(Q) && intrinsics.type_is_numeric(T) {
  if z == 0. {
    out := Q{}
    if power == 0. {
      out.w = 1.
    }
    return out
  }
  qpower := Q{}
  when intrinsics.type_is_integer(T) {
    qpower.w = power
  } else when intrinsics.type_is_complex(T) {
    qpower.w = real(power)
    qpower.x = imag(power)
  } else {
    qpower = power
  }
  return qexp(qpower * qln(z))
}

////////////////////////
// sqrt
qsqrt :: proc(q: $Q) -> Q where intrinsics.type_is_quaternion(Q) {
  // q^(.5) = (exp(ln(q^.5))) = exp(.5*ln(q))
  if q == 0. {
    return Q{}
  }
  w := q.w
  x := q.x
  y := q.y
  z := q.z
  if x == 0. && y == 0. && z == 0. {
    // pure real - ensure more exactness of results
    out := Q{}
    if w > 0 {
      out.w = math.sqrt(w)
    } else {
      out.x = math.sqrt(-w)
    }
    return out
  }
  return qexp(.5 * qln(q))
}

////////////////////////
// cbrt
qcbrt :: proc(q: $Q) -> Q where intrinsics.type_is_quaternion(Q) {
  // q^(1./3.) = (exp(ln(q^(1./3.)))) = exp(ln(q)/3.)
  if q == 0. {
    return Q{}
  } else {
    return qexp(qln(q) / 3.)
  }
}

////////////////////////
// arg
qarg :: proc(q: $Q) -> intrinsics.type_elem_type(Q) where intrinsics.type_is_quaternion(Q) {
  // q = a + b*qhat = sqrt(a^2 + b^2)*exp(atan2(b,a)*qhat)
  a := real(q)
  x := imag(q)
  y := jmag(q)
  z := kmag(q)
  b := math.sqrt(x * x + y * y + z * z)
  th := math.atan2(b, a)
  return th
}
