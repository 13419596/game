// Float info for IEEE floating point numbers
package gmath

import "core:fmt"
import "core:intrinsics"
import "game:util"

FloatCommonProperties :: struct {
  type:                    typeid,
  is_big_endian:           bool, // true if type T is a big endian type
  num_bits:                uint, // The number of num_bits occupied by the type.
  num_mantissa_bits:       uint, // The number of num_bits in the mantissa.
  num_exponent_bits:       uint, // The number of num_bits in the exponent including its sign and bias (of the exponent).
  decimal_digit_precision: uint, // The approximate number of decimal digits to which this kind of float is precise.
  max_exp:                 int, // The smallest positive power of the base (2) that causes overflow.
  min_exp:                 int, // The most negative power of the base (2) consistent with there being no leading 0’s in the mantissa.
  exponent_bias:           int,
  eps_exponent:            int, // The exponent that yields eps.
  epsneg_exponent:         int, // The exponent that yields epsneg.
}

FloatInfo :: struct($T: typeid) {
  using properties:   FloatCommonProperties,
  resolution:         T, // The approximate decimal resolution of this type, i.e., 10^(-decimal_digit_precision)
  eps:                T, // The difference between 1.0 and the next smallest representable float larger than 1.0. For example, for 64-bit binary floats in the IEEE-754 standard, eps = 2**-52, approximately 2.22e-16.
  epsneg:             T, // The difference between 1.0 and the next smallest representable float less than 1.0. For example, for 64-bit binary floats in the IEEE-754 standard, epsneg = 2**-53, approximately 1.11e-16.
  max:                T, // The largest representable number.
  min:                T, // The smallest representable number, typically -max.
  smallest_normal:    T, // Return the value for the smallest normal.
  smallest_subnormal: T, // The smallest positive floating point number with 0 as leading bit in the mantissa following IEEE-754.
  inf:                T, // +infinity
  nan:                T, // a single nan value - noting that there are many representations of nan in the floating point standard
}

finfo :: proc($T: typeid) -> FloatInfo(T) where intrinsics.type_is_float(T) {
  return _getCached_finfo(T{})
}

getFloatParts :: proc(x: f64) -> (f64, int, bool) {
  // at the moment float printing doesn't work right for large numbers. Use float parts to get more accurate float printing
  if !isfinite(x) || x == 0. {
    return x, 0, true
  }
  x_sign: f64 = x >= 0 ? +1. : -1.
  tens_mantissa := abs(x)
  tens_power: int = 0
  for tens_mantissa < +1. {
    tens_mantissa *= 10.
    if !isfinite(tens_mantissa) || tens_mantissa == 0. {
      // this is an error - TODO log this
      return (x_sign * tens_mantissa), 0, false
    }
    tens_power -= 1
  }
  for 10. <= tens_mantissa {
    tens_mantissa /= 10.
    if !isfinite(tens_mantissa) || tens_mantissa == 0. {
      // this is an error - TODO log this
      return (x_sign * tens_mantissa), 0, false
    }
    tens_power += 1
  }
  return (x_sign * tens_mantissa), tens_power, true
}

printFloatInfo :: proc(info: ^FloatInfo($T)) {
  // at the moment float printing doesn't work right for large numbers. Use float parts to get more accurate float printing
  resolution_m, resolution_e, res_ok := getFloatParts(f64(info.resolution))
  eps_m, eps_e, eps_ok := getFloatParts(f64(info.eps))
  epsneg_m, epsneg_e, epsneg_ok := getFloatParts(f64(info.epsneg))
  max_m, max_e, max_ok := getFloatParts(f64(info.max))
  smallest_normal_m, smallest_normal_e, smallest_normal_ok := getFloatParts(f64(info.smallest_normal))
  fmt.printf(
    "--------------------------------------------------------\n" +
    "Float Info for type %T\n" +
    "decimal_digit_precision =% 5d  resolution         = % 4ve%+d\n" +
    "eps_exponent            =% 5d  eps                = % 4ve%+d\n" +
    "epsneg_exponent         =% 5d  epsneg             = % 4ve%+d\n" +
    "min_exp                 =% 5d  smallest normal    = % 4ve%+d\n" +
    "max_exp                 =% 5d  max                = % 4ve%+d\n" +
    "exponent_bias           =% 5d  smallest subnormal = % 4.4e\n" +
    "num exp bits            =% 5d  inf                = % f\n" +
    "num mantissa            =% 5d  nan                = % f\n" +
    "big endian?             = %v\n" +
    "--------------------------------------------------------\n",
    T{},
    info.decimal_digit_precision,
    resolution_m,
    resolution_e,
    info.eps_exponent,
    eps_m,
    eps_e,
    info.epsneg_exponent,
    epsneg_m,
    epsneg_e,
    info.min_exp,
    smallest_normal_m,
    smallest_normal_e,
    info.max_exp,
    max_m,
    max_e,
    info.exponent_bias,
    info.smallest_subnormal,
    info.num_exponent_bits,
    info.inf,
    info.num_mantissa_bits,
    info.nan,
    info.is_big_endian,
  )
}

generateFloatInfo :: proc($T: typeid, num_mantissa_bits: uint, loc := #caller_location) -> FloatInfo(T) {
  using util
  t0 := T{}
  num_bytes: uint = size_of(t0)
  num_bits: uint = 8 * num_bytes
  num_exponent_bits := num_bits - 1 - num_mantissa_bits
  num_precision_decimal_digits := uint(LOG10_2 * f64(num_mantissa_bits))
  max_exponent: int = 1 << (num_exponent_bits - 1)
  min_exponent: int = -(1 << (num_exponent_bits - 1) - 2)
  exponent_bias: int = min_exponent - 1
  // Definition of maximum value: max val == 2^(max_exponent)*(1-2^(-mantissa_bits))
  // However the formulation uses the inf value, so some algebra is done to make it not overflow in the intermediary
  // max = 2^(max_exponent)*(1-2^(-mantissa_bits))
  //     = 2^(max_exponent)-2^(max_expoennt-mantissa_bits)
  //     = 2*(2^(max_exponent-1)-2^(max_expoennt-mantissa_bits-1))
  max_value_64: f64 = 2 * (pow2int(max_exponent - 1) - pow2int(max_exponent - int(num_mantissa_bits) - 1))
  smallest_normal_64: f64 = pow2int(min_exponent)
  inf := T(2. * max_value_64) // should cause overflow

  neg0: T = initFloat(-0., T)
  neg0_data := transmute([size_of(neg0)]byte)(neg0)

  out := FloatInfo(T) {
    properties = FloatCommonProperties{
      type = T,
      is_big_endian = neg0_data[0] == 0x80,
      num_bits = num_bits,
      num_mantissa_bits = num_mantissa_bits,
      num_exponent_bits = num_exponent_bits,
      decimal_digit_precision = num_precision_decimal_digits,
      max_exp = max_exponent,
      min_exp = min_exponent,
      exponent_bias = exponent_bias,
      eps_exponent = -int(num_mantissa_bits),
      epsneg_exponent = -int(num_mantissa_bits + 1),
    },
    resolution = T(pow10int(-int(num_precision_decimal_digits))),
    eps = T(pow2int(-int(num_mantissa_bits))),
    epsneg = -T(pow2int(-int(num_mantissa_bits + 1))),
    max = T(max_value_64),
    min = -T(max_value_64),
    smallest_normal = T(smallest_normal_64),
    smallest_subnormal = T(smallest_normal_64 * pow2int(-int(num_mantissa_bits))),
    inf = inf,
    nan = inf -
    inf, // should be nan
  }
  return out
}

/////////////////
// File private 
// Cached Finfo's
@(private = "file")
_finfo_f16 := generateFloatInfo(T = f16, num_mantissa_bits = 10)
@(private = "file")
_finfo_f32 := generateFloatInfo(T = f32, num_mantissa_bits = 23)
@(private = "file")
_finfo_f64 := generateFloatInfo(T = f64, num_mantissa_bits = 52)
@(private = "file")
_finfo_f16le := generateFloatInfo(T = f16le, num_mantissa_bits = 10)
@(private = "file")
_finfo_f32le := generateFloatInfo(T = f32le, num_mantissa_bits = 23)
@(private = "file")
_finfo_f64le := generateFloatInfo(T = f64le, num_mantissa_bits = 52)
@(private = "file")
_finfo_f16be := generateFloatInfo(T = f16be, num_mantissa_bits = 10)
@(private = "file")
_finfo_f32be := generateFloatInfo(T = f32be, num_mantissa_bits = 23)
@(private = "file")
_finfo_f64be := generateFloatInfo(T = f64be, num_mantissa_bits = 52)


@(private = "file")
_getCached_finfo_f16 :: proc(dummy: f16) -> FloatInfo(f16) {return _finfo_f16}
@(private = "file")
_getCached_finfo_f32 :: proc(dummy: f32) -> FloatInfo(f32) {return _finfo_f32}
@(private = "file")
_getCached_finfo_f64 :: proc(dummy: f64) -> FloatInfo(f64) {return _finfo_f64}
@(private = "file")
_getCached_finfo_f16le :: proc(dummy: f16le) -> FloatInfo(f16le) {return _finfo_f16le}
@(private = "file")
_getCached_finfo_f32le :: proc(dummy: f32le) -> FloatInfo(f32le) {return _finfo_f32le}
@(private = "file")
_getCached_finfo_f64le :: proc(dummy: f64le) -> FloatInfo(f64le) {return _finfo_f64le}
@(private = "file")
_getCached_finfo_f16be :: proc(dummy: f16be) -> FloatInfo(f16be) {return _finfo_f16be}
@(private = "file")
_getCached_finfo_f32be :: proc(dummy: f32be) -> FloatInfo(f32be) {return _finfo_f32be}
@(private = "file")
_getCached_finfo_f64be :: proc(dummy: f64be) -> FloatInfo(f64be) {return _finfo_f64be}

@(private = "file")
_getCached_finfo :: proc {
  _getCached_finfo_f16,
  _getCached_finfo_f32,
  _getCached_finfo_f64,
  _getCached_finfo_f16le,
  _getCached_finfo_f32le,
  _getCached_finfo_f64le,
  _getCached_finfo_f16be,
  _getCached_finfo_f32be,
  _getCached_finfo_f64be,
}
