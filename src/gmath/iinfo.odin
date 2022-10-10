// Int info for IEEE Inting point numbers
package gmath

import "core:fmt"
import "core:intrinsics"

IntOverflowBehavior :: enum {
  Wrap,
  Saturate,
}

IntCommonProperties :: struct {
  type:               typeid,
  is_big_endian:      bool, // true if type T is a big endian type
  is_signed:          bool,
  num_bits:           uint, // The number of num_bits occupied by the type.
  num_decimal_digits: uint, // number of decimal digits, (not including sign)
  underflow_behavior: IntOverflowBehavior, // probably implementation defined behvaior, but helpful to know
  overflow_behavior:  IntOverflowBehavior, // probably implementation defined behvaior, but helpful to know
}

IntInfo :: struct($T: typeid) {
  using properties: IntCommonProperties,
  max:              T, // The largest representable number.
  min:              T, // The smallest representable number
}

iinfo :: proc($T: typeid) -> IntInfo(T) where intrinsics.type_is_integer(T) {
  return _getCached_iinfo(T{})
}

printIntInfo :: proc(info: ^IntInfo($T)) {
  fmt.printf(
    "--------------------------------------------------------\n" +
    "Int Info for type %T\n" +
    "num bits      = % 8d  big endian? : % 8v\n" +
    "num digits    = % 8d  is signed?  : % 8v\n" +
    "underflow     = %8v  overflow    : %8v\n" +
    "min  = % 21d\n" +
    "max  = % 21d\n" +
    "--------------------------------------------------------\n",
    T{},
    info.num_bits,
    info.is_big_endian,
    info.num_decimal_digits,
    info.is_signed,
    info.underflow_behavior,
    info.overflow_behavior,
    info.min,
    info.max,
  )
}

discoverIntegerBigEndianess :: proc($T: typeid) -> bool where intrinsics.type_is_integer(T) {
  one := T(1)
  one_data := transmute([size_of(one)]byte)(one) // used for endian discover
  is_big_endian := one_data[0] != 0x01
  return is_big_endian
}

discoverIntegerSigned :: proc($T: typeid) -> bool where intrinsics.type_is_integer(T) {
  // Sign discovery should try using bitflip first, 
  // and then fallback on overflow behavior if the bitflip result is unreliable (not all ones)
  all_ones_data := [size_of(T)]byte{}
  for _, idx in all_ones_data {
    all_ones_data[idx] = 0xFF
  }
  all_ones := transmute(T)all_ones_data
  is_signed := all_ones < 0
  return is_signed
}

generateIntInfo :: proc($T: typeid, loc := #caller_location) -> IntInfo(T) {
  num_bits: uint = 8 * size_of(T{})
  is_signed := discoverIntegerSigned(T)

  min, max: T
  if is_signed {
    // calculating 1<<(num_bits-1) could overflow/cause a sign flip
    // max = 2^(N-1)-1
    //     = 2*(2^(N-2))-1
    //     = 2*(2^(N-2)) + 2*(1-1)-1
    //     = 2*(2^(N-2)-1) + 2*(1)-1
    //     = 2*(2^(N-2)-1) + 1
    //     = 2*x + 1
    x := (1 << (num_bits - 2)) - 1
    max = T(2 * x + 1)
    min = T(-2 * x - 2)
  } else {
    x := (1 << (num_bits - 1)) - 1
    max = T(2 * x + 1)
    min = 0
  }

  overflow_value := max + 1
  overflow_behavior: IntOverflowBehavior = overflow_value == max ? .Saturate : .Wrap

  underflow_value := min - 1
  underflow_behavior: IntOverflowBehavior = underflow_value == min ? .Saturate : .Wrap

  out := IntInfo(T) {
    properties = IntCommonProperties{
      type = T,
      is_big_endian = discoverIntegerBigEndianess(T),
      is_signed = is_signed,
      num_bits = num_bits,
      num_decimal_digits = uint(1 + LOG10_2 * f64(num_bits)),
      underflow_behavior = underflow_behavior,
      overflow_behavior = overflow_behavior,
    },
    max = max,
    min = min,
  }
  return out
}

/////////////////
// File private 

// Cached Finfo's
@(private = "file")
_iinfo_i8 := generateIntInfo(T = i8)
@(private = "file")
_iinfo_i16 := generateIntInfo(T = i16)
@(private = "file")
_iinfo_i32 := generateIntInfo(T = i32)
@(private = "file")
_iinfo_i64 := generateIntInfo(T = i64)
@(private = "file")
_iinfo_i16le := generateIntInfo(T = i16le)
@(private = "file")
_iinfo_i32le := generateIntInfo(T = i32le)
@(private = "file")
_iinfo_i64le := generateIntInfo(T = i64le)
@(private = "file")
_iinfo_i16be := generateIntInfo(T = i16be)
@(private = "file")
_iinfo_i32be := generateIntInfo(T = i32be)
@(private = "file")
_iinfo_i64be := generateIntInfo(T = i64be)

@(private = "file")
_iinfo_u8 := generateIntInfo(T = u8)
@(private = "file")
_iinfo_u16 := generateIntInfo(T = u16)
@(private = "file")
_iinfo_u32 := generateIntInfo(T = u32)
@(private = "file")
_iinfo_u64 := generateIntInfo(T = u64)
@(private = "file")
_iinfo_u16le := generateIntInfo(T = u16le)
@(private = "file")
_iinfo_u32le := generateIntInfo(T = u32le)
@(private = "file")
_iinfo_u64le := generateIntInfo(T = u64le)
@(private = "file")
_iinfo_u16be := generateIntInfo(T = u16be)
@(private = "file")
_iinfo_u32be := generateIntInfo(T = u32be)
@(private = "file")
_iinfo_u64be := generateIntInfo(T = u64be)

@(private = "file")
_getCached_iinfo_i8 :: proc(dummy: i8) -> IntInfo(i8) {return _iinfo_i8}
@(private = "file")
_getCached_iinfo_i16 :: proc(dummy: i16) -> IntInfo(i16) {return _iinfo_i16}
@(private = "file")
_getCached_iinfo_i32 :: proc(dummy: i32) -> IntInfo(i32) {return _iinfo_i32}
@(private = "file")
_getCached_iinfo_i64 :: proc(dummy: i64) -> IntInfo(i64) {return _iinfo_i64}
@(private = "file")
_getCached_iinfo_i16le :: proc(dummy: i16le) -> IntInfo(i16le) {return _iinfo_i16le}
@(private = "file")
_getCached_iinfo_i32le :: proc(dummy: i32le) -> IntInfo(i32le) {return _iinfo_i32le}
@(private = "file")
_getCached_iinfo_i64le :: proc(dummy: i64le) -> IntInfo(i64le) {return _iinfo_i64le}
@(private = "file")
_getCached_iinfo_i16be :: proc(dummy: i16be) -> IntInfo(i16be) {return _iinfo_i16be}
@(private = "file")
_getCached_iinfo_i32be :: proc(dummy: i32be) -> IntInfo(i32be) {return _iinfo_i32be}
@(private = "file")
_getCached_iinfo_i64be :: proc(dummy: i64be) -> IntInfo(i64be) {return _iinfo_i64be}

@(private = "file")
_getCached_iinfo_u8 :: proc(dummy: u8) -> IntInfo(u8) {return _iinfo_u8}
@(private = "file")
_getCached_iinfo_u16 :: proc(dummy: u16) -> IntInfo(u16) {return _iinfo_u16}
@(private = "file")
_getCached_iinfo_u32 :: proc(dummy: u32) -> IntInfo(u32) {return _iinfo_u32}
@(private = "file")
_getCached_iinfo_u64 :: proc(dummy: u64) -> IntInfo(u64) {return _iinfo_u64}
@(private = "file")
_getCached_iinfo_u16le :: proc(dummy: u16le) -> IntInfo(u16le) {return _iinfo_u16le}
@(private = "file")
_getCached_iinfo_u32le :: proc(dummy: u32le) -> IntInfo(u32le) {return _iinfo_u32le}
@(private = "file")
_getCached_iinfo_u64le :: proc(dummy: u64le) -> IntInfo(u64le) {return _iinfo_u64le}
@(private = "file")
_getCached_iinfo_u16be :: proc(dummy: u16be) -> IntInfo(u16be) {return _iinfo_u16be}
@(private = "file")
_getCached_iinfo_u32be :: proc(dummy: u32be) -> IntInfo(u32be) {return _iinfo_u32be}
@(private = "file")
_getCached_iinfo_u64be :: proc(dummy: u64be) -> IntInfo(u64be) {return _iinfo_u64be}

@(private = "file")
_getCached_iinfo :: proc {
  _getCached_iinfo_i8,
  _getCached_iinfo_i16,
  _getCached_iinfo_i32,
  _getCached_iinfo_i64,
  _getCached_iinfo_i16le,
  _getCached_iinfo_i32le,
  _getCached_iinfo_i64le,
  _getCached_iinfo_i16be,
  _getCached_iinfo_i32be,
  _getCached_iinfo_i64be,
  _getCached_iinfo_u8,
  _getCached_iinfo_u16,
  _getCached_iinfo_u32,
  _getCached_iinfo_u64,
  _getCached_iinfo_u16le,
  _getCached_iinfo_u32le,
  _getCached_iinfo_u64le,
  _getCached_iinfo_u16be,
  _getCached_iinfo_u32be,
  _getCached_iinfo_u64be,
}
