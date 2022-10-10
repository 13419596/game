// subpackage for running `gmath` tests
package test_gmath

import "core:fmt"
import "core:math"
import "core:testing"
import tc "tests:common"
import gm "game:gmath"
import "game:util"

@(test)
runTests_pow_int :: proc(t: ^testing.T) {
  test_pow2int(t)
  test_pow10int(t)
  {
    test_int_negative_powers(t)
  }
  {
    test_pow3int_float(t)
    test_zero_float(t)
    test_nan_float(t)
    test_inf_float(t)
  }
  {
    test_pow3_complex(t)
    test_zero_complex(t)
    test_nan_complex(t)
    test_inf_power_complex(t)
  }
  {
    test_pow3_quaternion(t)
    test_zero_quat(t)
    test_nan_quat(t)
    test_inf_power_quat(t)
  }
}

///////////////////////////////////////////////////////
// Test simplified power functions 2^n, 10^n

@(test, private = "file")
test_pow2int :: proc(t: ^testing.T) {
  using gm
  using util
  // Can check for exactness because power of twos are exact in floating point numbers
  {
    n := 0
    expected := 1.
    result := pow2int(n)
    tc.expect(t, expected == result, fmt.tprintf("Expected 2^(%v) == %v, got %v instead.", n, expected, result))
  }
  {
    n := 1
    expected := 2.
    result := pow2int(n)
    tc.expect(t, expected == result, fmt.tprintf("Expected 2^(%v) == %v, got %v instead.", n, expected, result))
  }
  {
    n := 2
    expected := 4.
    result := pow2int(n)
    tc.expect(t, expected == result, fmt.tprintf("Expected 2^(%v) == %v, got %v instead.", n, expected, result))
  }
  {
    n := 22
    expected := 4194304.
    result := pow2int(n)
    tc.expect(t, expected == result, fmt.tprintf("Expected 2^(%v) == %v, got %v instead.", n, expected, result))
  }
  {
    n := -1
    expected := 1. / 2
    result := pow2int(n)
    tc.expect(t, expected == result, fmt.tprintf("Expected 2^(%v) == %v, got %v instead.", n, expected, result))
  }
  {
    n := -2
    expected := 1. / 4
    result := pow2int(n)
    tc.expect(t, expected == result, fmt.tprintf("Expected 2^(%v) == %v, got %v instead.", n, expected, result))
  }
  {
    n := -22
    expected := 1. / 4194304
    result := pow2int(n)
    tc.expect(t, expected == result, fmt.tprintf("Expected 2^(%v) == %v, got %v instead.", n, expected, result))
  }
}

@(test, private = "file")
test_pow10int :: proc(t: ^testing.T) {
  using gm
  tc.expect(t, pow10int(0) == 1.)
  tc.expect(t, pow10int(1) == 10.)
  tc.expect(t, pow10int(2) == 100.)
  tc.expect(t, pow10int(14) == 100_000_000_000_000.)
  tc.expect(t, isclose(pow10int(-1), 1. / 10.))
  tc.expect(t, isclose(pow10int(-2), 1. / 100.))
  tc.expect(t, isclose(pow10int(-22), 1. / 10_000_000_000_000.))
}

///////////////////////////////////////////////////////
// Edge cases for int

@(test, private = "file")
test_int_negative_powers :: proc(t: ^testing.T) {
  using gm
  powers := [?]int{-1, -2, -200, 0}
  signs := [?]int{+1, -1}
  base := 5
  for power in powers {
    expected := power < 0 ? 0 : 1
    for sign in signs {
      tc.expect(
        t,
        powIntegerExponent(i8(sign * base), power) == i8(expected),
        fmt.tprintf(
          "(%v)^%v expected to be equal to %v, but got %v instead.",
          i8(sign * base),
          power,
          i8(expected),
          powIntegerExponent(i8(sign * base), power),
        ),
      )
      tc.expect(t, powIntegerExponent(u8(sign * base), power) == u8(expected))
      tc.expect(t, powIntegerExponent(i16(sign * base), power) == i16(expected))
      tc.expect(t, powIntegerExponent(i16le(sign * base), power) == i16le(expected))
      tc.expect(t, powIntegerExponent(i16be(sign * base), power) == i16be(expected))
      tc.expect(t, powIntegerExponent(u16(sign * base), power) == u16(expected))
      tc.expect(t, powIntegerExponent(u16le(sign * base), power) == u16le(expected))
      tc.expect(t, powIntegerExponent(u16be(sign * base), power) == u16be(expected))
      tc.expect(t, powIntegerExponent(i32(sign * base), power) == i32(expected))
      tc.expect(t, powIntegerExponent(i32le(sign * base), power) == i32le(expected))
      tc.expect(t, powIntegerExponent(i32be(sign * base), power) == i32be(expected))
      tc.expect(t, powIntegerExponent(u32(sign * base), power) == u32(expected))
      tc.expect(t, powIntegerExponent(u32le(sign * base), power) == u32le(expected))
      tc.expect(t, powIntegerExponent(u32be(sign * base), power) == u32be(expected))
      tc.expect(t, powIntegerExponent(i64(sign * base), power) == i64(expected))
      tc.expect(t, powIntegerExponent(i64le(sign * base), power) == i64le(expected))
      tc.expect(t, powIntegerExponent(i64be(sign * base), power) == i64be(expected))
      tc.expect(t, powIntegerExponent(u64(sign * base), power) == u64(expected))
      tc.expect(t, powIntegerExponent(u64le(sign * base), power) == u64le(expected))
      tc.expect(t, powIntegerExponent(u64be(sign * base), power) == u64be(expected))
    }
  }
}

///////////////////////////////////////////////////////

@(test, private = "file")
test_pow3int_float :: proc(t: ^testing.T) {
  using gm
  using util
  {
    base := initFloat(-3., f32)
    tc.expect(t, isclose(base, -3.), "assignment sanity check")
    tc.expect(t, powIntegerExponent(base, 0) == initFloat(1., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 1) == initFloat(-3., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 2) == initFloat(9., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 15) == initFloat(-14348907., type_of(base)))
    tc.expect(t, isclose(powIntegerExponent(base, -1), initFloat(1. / -3., type_of(base))))
    tc.expect(t, isclose(powIntegerExponent(base, -2), initFloat(1. / 9., type_of(base))))
    tc.expect(t, isclose(powIntegerExponent(base, -15), initFloat(1. / -14348907., type_of(base))))
  }
  {
    base := initFloat(-3., f64)
    tc.expect(t, isclose(base, -3.), "assignment sanity check")
    tc.expect(t, powIntegerExponent(base, 0) == initFloat(1., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 1) == initFloat(-3., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 2) == initFloat(9., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 15) == initFloat(-14348907., type_of(base)))
    tc.expect(t, isclose(powIntegerExponent(base, -1), initFloat(1. / -3., type_of(base))))
    tc.expect(t, isclose(powIntegerExponent(base, -2), initFloat(1. / 9., type_of(base))))
    tc.expect(t, isclose(powIntegerExponent(base, -15), initFloat(1. / -14348907., type_of(base))))
  }
  {
    base := initFloat(-3., f32be)
    tc.expect(t, isclose(base, initFloat(-3., type_of(base))), "assignment sanity check")
    tc.expect(t, powIntegerExponent(base, 0) == initFloat(1., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 1) == initFloat(-3., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 2) == initFloat(9., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 15) == initFloat(-14348907., type_of(base)))
    tc.expect(t, isclose(powIntegerExponent(base, -1), initFloat(1. / -3., type_of(base))))
    tc.expect(t, isclose(powIntegerExponent(base, -2), initFloat(1. / 9., type_of(base))))
    tc.expect(t, isclose(powIntegerExponent(base, -15), initFloat(1. / -14348907., type_of(base))))
  }
  {
    base := initFloat(-3., f64be)
    tc.expect(t, isclose(base, -3.), "assignment sanity check")
    tc.expect(t, powIntegerExponent(base, 0) == initFloat(1., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 1) == initFloat(-3., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 2) == initFloat(9., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 15) == initFloat(-14348907., type_of(base)))
    tc.expect(t, isclose(powIntegerExponent(base, -1), initFloat(1. / -3., type_of(base))))
    tc.expect(t, isclose(powIntegerExponent(base, -2), initFloat(1. / 9., type_of(base))))
    tc.expect(t, isclose(powIntegerExponent(base, -15), initFloat(1. / -14348907., type_of(base))))
  }
  {
    base := initFloat(-3., f32le)
    tc.expect(t, isclose(base, -3.), "assignment sanity check")
    tc.expect(t, powIntegerExponent(base, 0) == initFloat(1., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 0) == initFloat(1., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 1) == initFloat(-3., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 2) == initFloat(9., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 15) == initFloat(-14348907., type_of(base)))
    tc.expect(t, isclose(powIntegerExponent(base, -1), initFloat(1. / -3., type_of(base))))
    tc.expect(t, isclose(powIntegerExponent(base, -2), initFloat(1. / 9., type_of(base))))
    tc.expect(t, isclose(powIntegerExponent(base, -15), initFloat(1. / -14348907., type_of(base))))
  }
  {
    base := initFloat(-3., f64le)
    tc.expect(t, isclose(base, -3.), "assignment sanity check")
    tc.expect(t, powIntegerExponent(base, 0) == initFloat(1., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 1) == initFloat(-3., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 2) == initFloat(9., type_of(base)))
    tc.expect(t, powIntegerExponent(base, 15) == initFloat(-14348907., type_of(base)))
    tc.expect(t, isclose(powIntegerExponent(base, -1), initFloat(1. / -3., type_of(base))))
    tc.expect(t, isclose(powIntegerExponent(base, -2), initFloat(1. / 9., type_of(base))))
    tc.expect(t, isclose(powIntegerExponent(base, -15), initFloat(1. / -14348907., type_of(base))))
  }
}

// Edge cases for float
@(test, private = "file")
test_zero_float :: proc(t: ^testing.T) {
  using gm
  using util
  powers := [?]int{-1, -2, -200, 0, 1, 200}
  for power in powers {
    if power >= 0 {
      expected := power == 0 ? 1. : 0.
      tc.expect(
        t,
        powIntegerExponent(initFloat(0., f16), power) == initFloat(expected, f16),
        fmt.tprintf("Expected 0^%v to be %v, but got %v instead.", power, expected, powIntegerExponent(initFloat(0., f16), power)),
      )
      tc.expect(t, powIntegerExponent(initFloat(0., f16le), power) == initFloat(expected, f16le))
      tc.expect(t, powIntegerExponent(initFloat(0., f16be), power) == initFloat(expected, f16be))
      tc.expect(t, powIntegerExponent(initFloat(0., f32), power) == initFloat(expected, f32))
      tc.expect(t, powIntegerExponent(initFloat(0., f32le), power) == initFloat(expected, f32le))
      tc.expect(t, powIntegerExponent(initFloat(0., f32be), power) == initFloat(expected, f32be))
      tc.expect(t, powIntegerExponent(initFloat(0., f64), power) == initFloat(expected, f64))
      tc.expect(t, powIntegerExponent(initFloat(0., f64le), power) == initFloat(expected, f64le))
      tc.expect(t, powIntegerExponent(initFloat(0., f64be), power) == initFloat(expected, f64be))
    } else {
      tc.expect(t, isnan(powIntegerExponent(initFloat(0., f16), power)))
      tc.expect(t, isnan(powIntegerExponent(initFloat(0., f16le), power)))
      tc.expect(t, isnan(powIntegerExponent(initFloat(0., f16be), power)))
      tc.expect(t, isnan(powIntegerExponent(initFloat(0., f32), power)))
      tc.expect(t, isnan(powIntegerExponent(initFloat(0., f32le), power)))
      tc.expect(t, isnan(powIntegerExponent(initFloat(0., f32be), power)))
      tc.expect(t, isnan(powIntegerExponent(initFloat(0., f64), power)))
      tc.expect(t, isnan(powIntegerExponent(initFloat(0., f64le), power)))
      tc.expect(t, isnan(powIntegerExponent(initFloat(0., f64be), power)))
    }
  }
}

@(test, private = "file")
test_nan_float :: proc(t: ^testing.T) {
  using gm
  using util
  powers := [?]int{-1, -2, -200, 0, 1, 200}
  base := math.nan_f64()
  for power in powers {
    tc.expect(
      t,
      isnan(powIntegerExponent(initFloat(base, f16), power)),
      fmt.tprintf("Expected nan^%d to be nan, but got %v instead", power, powIntegerExponent(initFloat(base, f16), power)),
    )
    tc.expect(t, isnan(powIntegerExponent(initFloat(base, f16le), power)))
    tc.expect(t, isnan(powIntegerExponent(initFloat(base, f16be), power)))
    tc.expect(t, isnan(powIntegerExponent(initFloat(base, f32), power)))
    tc.expect(t, isnan(powIntegerExponent(initFloat(base, f32le), power)))
    tc.expect(t, isnan(powIntegerExponent(initFloat(base, f32be), power)))
    tc.expect(t, isnan(powIntegerExponent(initFloat(base, f64), power)))
    tc.expect(t, isnan(powIntegerExponent(initFloat(base, f64le), power)))
    tc.expect(t, isnan(powIntegerExponent(initFloat(base, f64be), power)))
  }
}

@(test, private = "file")
test_inf_float :: proc(t: ^testing.T) {
  using gm
  using util
  powers := [?]int{-1, -2, -3, -200, 0, 1, 2, 3, 200}
  inf := finfo(f64).inf
  bases := [?]f64{-inf, +inf}
  for base in bases {
    should_be_inf := isinf(base)
    tc.expect(t, should_be_inf, "should be infinity sanity check")
    if !should_be_inf {
      // skip the tests because already wrong
      continue
    }
    for power in powers {
      if power == 0 {
        tc.expect(
          t,
          isnan(powIntegerExponent(initFloat(base, f16), power)),
          fmt.tprintf("Expected (%v)^%v to be nan, but got %v instead", base, power, powIntegerExponent(initFloat(base, f16), power)),
        )
        tc.expect(t, isnan(powIntegerExponent(initFloat(base, f16le), power)))
        tc.expect(t, isnan(powIntegerExponent(initFloat(base, f16be), power)))
        tc.expect(t, isnan(powIntegerExponent(initFloat(base, f32), power)))
        tc.expect(t, isnan(powIntegerExponent(initFloat(base, f32le), power)))
        tc.expect(t, isnan(powIntegerExponent(initFloat(base, f32be), power)))
        tc.expect(t, isnan(powIntegerExponent(initFloat(base, f64), power)))
        tc.expect(t, isnan(powIntegerExponent(initFloat(base, f64le), power)))
        tc.expect(t, isnan(powIntegerExponent(initFloat(base, f64be), power)))
      } else if power < 0 {
        tc.expect(t, powIntegerExponent(initFloat(base, f16), power) == initFloat(0., f16))
        tc.expect(t, powIntegerExponent(initFloat(base, f16le), power) == initFloat(0., f16le))
        tc.expect(t, powIntegerExponent(initFloat(base, f16be), power) == initFloat(0., f16be))
        tc.expect(t, powIntegerExponent(initFloat(base, f32), power) == initFloat(0., f32))
        tc.expect(t, powIntegerExponent(initFloat(base, f32le), power) == initFloat(0., f32le))
        tc.expect(t, powIntegerExponent(initFloat(base, f32be), power) == initFloat(0., f32be))
        tc.expect(t, powIntegerExponent(initFloat(base, f64), power) == initFloat(0., f64))
        tc.expect(t, powIntegerExponent(initFloat(base, f64le), power) == initFloat(0., f64le))
        tc.expect(t, powIntegerExponent(initFloat(base, f64be), power) == initFloat(0., f64be))
      } else {
        // determine sign
        sign := base < 0 ? (power % 2 == 0 ? -1. : +1.) : +1.
        tc.expect(t, powIntegerExponent(initFloat(base, f16), power) == initFloat(sign * base, f16))
        tc.expect(t, powIntegerExponent(initFloat(base, f16le), power) == initFloat(sign * base, f16le))
        tc.expect(t, powIntegerExponent(initFloat(base, f16be), power) == initFloat(sign * base, f16be))
        tc.expect(t, powIntegerExponent(initFloat(base, f32), power) == initFloat(sign * base, f32))
        tc.expect(t, powIntegerExponent(initFloat(base, f32le), power) == initFloat(sign * base, f32le))
        tc.expect(t, powIntegerExponent(initFloat(base, f32be), power) == initFloat(sign * base, f32be))
        tc.expect(t, powIntegerExponent(initFloat(base, f64), power) == initFloat(sign * base, f64))
        tc.expect(t, powIntegerExponent(initFloat(base, f64le), power) == initFloat(sign * base, f64le))
        tc.expect(t, powIntegerExponent(initFloat(base, f64be), power) == initFloat(sign * base, f64be))
      }
    }
  }
}

///////////////////////////////////////////////////////

@(test, private = "file")
test_pow3_complex :: proc(t: ^testing.T) {
  using gm
  using util
  {
    // base == -3
    {
      base := complex64(complex(-3, 0))
      tc.expect(t, isclose(base, -3.), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == 1.)
      tc.expect(t, powIntegerExponent(base, 1) == -3.)
      tc.expect(t, powIntegerExponent(base, 2) == 9., fmt.tprintf("Expected (-3)^2 == 9, but got %v instead.", powIntegerExponent(base, 2)))
      tc.expect(t, powIntegerExponent(base, 3) == -27.)
      tc.expect(t, powIntegerExponent(base, 4) == 81.)
      tc.expect(t, powIntegerExponent(base, 15) == -14348907.)
      tc.expect(t, isclose(powIntegerExponent(base, -1), 1. / -3.))
      tc.expect(t, isclose(powIntegerExponent(base, -2), 1. / 9.))
      tc.expect(t, isclose(powIntegerExponent(base, -3), 1. / -27.))
      tc.expect(t, isclose(powIntegerExponent(base, -4), 1. / 81.))
      tc.expect(t, isclose(powIntegerExponent(base, -15), 1. / -14348907.))
    }
    {
      base := complex128(complex(-3, 0))
      tc.expect(t, isclose(base, -3.), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == 1.)
      tc.expect(t, powIntegerExponent(base, 1) == -3.)
      tc.expect(t, powIntegerExponent(base, 2) == 9.)
      tc.expect(t, powIntegerExponent(base, 3) == -27.)
      tc.expect(t, powIntegerExponent(base, 4) == 81.)
      tc.expect(t, powIntegerExponent(base, 15) == -14348907.)
      tc.expect(t, isclose(powIntegerExponent(base, -1), 1. / -3.))
      tc.expect(t, isclose(powIntegerExponent(base, -2), 1. / 9.))
      tc.expect(t, isclose(powIntegerExponent(base, -3), 1. / -27.))
      tc.expect(t, isclose(powIntegerExponent(base, -4), 1. / 81.))
      tc.expect(t, isclose(powIntegerExponent(base, -15), 1. / -14348907.))
    }
  }
  {
    // base == 3i
    {
      base := complex64(complex(0, 3))
      tc.expect(t, isclose(base, type_of(base)(complex(0, 3))), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == complex(1., 0.))
      tc.expect(t, powIntegerExponent(base, 1) == complex(0., 3.))
      tc.expect(t, powIntegerExponent(base, 2) == complex(-9, 0.))
      tc.expect(t, powIntegerExponent(base, 3) == complex(0., -27.))
      tc.expect(t, powIntegerExponent(base, 4) == complex(81, 0.))
      tc.expect(t, powIntegerExponent(base, 15) == complex(0, -14348907.))
      tc.expect(t, isclose(powIntegerExponent(base, -1), type_of(base)(1. / complex(0., 3.))))
      tc.expect(t, isclose(powIntegerExponent(base, -2), type_of(base)(1. / complex(-9., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -3), type_of(base)(1. / complex(0., -27.))))
      tc.expect(t, isclose(powIntegerExponent(base, -4), type_of(base)(1. / complex(81., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -15), type_of(base)(1. / complex(0, -14348907.))))
    }
    {
      base := complex128(complex(0, 3))
      tc.expect(t, isclose(base, complex(0, 3)), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == complex(1., 0.))
      tc.expect(t, powIntegerExponent(base, 1) == complex(0., 3.))
      tc.expect(t, powIntegerExponent(base, 2) == complex(-9, 0.))
      tc.expect(t, powIntegerExponent(base, 3) == complex(0., -27.))
      tc.expect(t, powIntegerExponent(base, 4) == complex(81, 0.))
      tc.expect(t, powIntegerExponent(base, 15) == complex(0, -14348907.))
      tc.expect(t, isclose(powIntegerExponent(base, -1), 1. / complex(0., 3.)))
      tc.expect(t, isclose(powIntegerExponent(base, -2), 1. / complex(-9., 0.)))
      tc.expect(t, isclose(powIntegerExponent(base, -3), 1. / complex(0., -27.)))
      tc.expect(t, isclose(powIntegerExponent(base, -4), 1. / complex(81., 0.)))
      tc.expect(t, isclose(powIntegerExponent(base, -15), 1. / complex(0, -14348907.)))
    }
  }
  {
    // base == 1+1i
    {
      base := complex64(complex(1, 1))
      tc.expect(t, isclose(base, type_of(base)(complex(1, 1))), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == complex(1., 0.))
      tc.expect(t, powIntegerExponent(base, 1) == complex(1., 1.))
      tc.expect(t, powIntegerExponent(base, 2) == complex(0, 2.))
      tc.expect(t, powIntegerExponent(base, 3) == complex(-2., 2.))
      tc.expect(t, powIntegerExponent(base, 4) == complex(-4, 0.))
      tc.expect(t, powIntegerExponent(base, 15) == complex(128, -128.))
      tc.expect(t, isclose(powIntegerExponent(base, -1), type_of(base)(1. / complex(1., 1.))))
      tc.expect(t, isclose(powIntegerExponent(base, -2), type_of(base)(1. / complex(0., 2.))))
      tc.expect(t, isclose(powIntegerExponent(base, -3), type_of(base)(1. / complex(-2., 2.))))
      tc.expect(t, isclose(powIntegerExponent(base, -4), type_of(base)(1. / complex(-4., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -15), type_of(base)(1. / complex(128, -128.))))
    }
    {
      base := complex128(complex(1, 1))
      tc.expect(t, isclose(base, type_of(base)(complex(1, 1))), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == complex(1., 0.))
      tc.expect(t, powIntegerExponent(base, 1) == complex(1., 1.))
      tc.expect(t, powIntegerExponent(base, 2) == complex(0, 2.))
      tc.expect(t, powIntegerExponent(base, 3) == complex(-2., 2.))
      tc.expect(t, powIntegerExponent(base, 4) == complex(-4, 0.))
      tc.expect(t, powIntegerExponent(base, 15) == complex(128, -128.))
      tc.expect(t, isclose(powIntegerExponent(base, -1), type_of(base)(1. / complex(1., 1.))))
      tc.expect(t, isclose(powIntegerExponent(base, -2), type_of(base)(1. / complex(0., 2.))))
      tc.expect(t, isclose(powIntegerExponent(base, -3), type_of(base)(1. / complex(-2., 2.))))
      tc.expect(t, isclose(powIntegerExponent(base, -4), type_of(base)(1. / complex(-4., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -15), type_of(base)(1. / complex(128, -128.))))
    }
  }
}

// Test edge cases for complex
@(test, private = "file")
test_zero_complex :: proc(t: ^testing.T) {
  using gm
  using util
  powers := [?]int{-1, -2, -200, 0, 1, 200}
  base := complex128(complex(0., 0.))
  for power in powers {
    if power >= 0 {
      expected := power == 0 ? complex(1., 0) : complex(0., 0.)
      tc.expect(t, powIntegerExponent(complex64(complex(0., 0.)), power) == complex64(expected))
      tc.expect(t, powIntegerExponent(complex128(complex(0., 0.)), power) == complex128(expected))
    } else {
      tc.expect(t, isnan(powIntegerExponent(complex64(complex(0., 0.)), power)))
      tc.expect(t, isnan(powIntegerExponent(complex128(complex(0., 0.)), power)))
    }
  }
}

@(test, private = "file")
test_nan_complex :: proc(t: ^testing.T) {
  using gm
  using util
  powers := [?]int{-1, -2, -200, 0, 1, 200}
  nan := math.nan_f64()
  bases := [?]complex128{complex(nan, 0), complex(0, nan), complex(nan, nan)}
  for base in bases {
    tc.expect(t, isnan(base), "isnan sanity check")
    for power in powers {
      tc.expect(t, isnan(powIntegerExponent(complex64(base), power)))
      tc.expect(t, isnan(powIntegerExponent(complex128(base), power)))
    }
  }
}

@(test, private = "file")
test_inf_power_complex :: proc(t: ^testing.T) {
  using gm
  using util
  powers := [?]int{-1, -2, -200, 0, 1, 2, 200}
  inf := finfo(f64).inf
  simple_inf_bases := [?]complex128{
    complex(inf, 0),
    complex(0, inf),
    complex(inf, inf),
    complex(inf, -inf),
    complex(-inf, 0),
    complex(0, -inf),
    complex(-inf, inf),
    complex(-inf, inf),
  }
  for base in simple_inf_bases {
    tc.expect(t, isinf(base), "isnan sanity check")
    for power in powers {
      c64 := powIntegerExponent(complex64(base), power)
      c128 := powIntegerExponent(complex128(base), power)
      if power < 0 {
        tc.expect(t, powIntegerExponent(complex64(base), power) == 0)
        tc.expect(t, powIntegerExponent(complex128(base), power) == 0)
      } else if power == 0 {
        tc.expect(t, isnan(powIntegerExponent(complex64(base), power)))
        tc.expect(t, isnan(powIntegerExponent(complex128(base), power)))
      } else if power == 1 {
        // should be same
        tc.expect(t, complex64(base) == complex64(base))
        tc.expect(t, powIntegerExponent(complex64(base), power) == complex64(base))
        tc.expect(t, powIntegerExponent(complex128(base), power) == complex128(base))
      } else {
        // can be inf or nan
        tc.expect(t, isinf(c64) || isnan(c64))
        tc.expect(t, isinf(c128) || isnan(c64))
      }
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////

@(test, private = "file")
test_pow3_quaternion :: proc(t: ^testing.T) {
  using gm
  using util
  {
    // base == -3
    {
      base := quaternion128(quaternion(-3, 0, 0, 0))
      tc.expect(t, isclose(base, -3.), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == 1.)
      tc.expect(t, powIntegerExponent(base, 1) == -3.)
      tc.expect(t, powIntegerExponent(base, 2) == 9.)
      tc.expect(t, powIntegerExponent(base, 3) == -27.)
      tc.expect(t, powIntegerExponent(base, 4) == 81.)
      tc.expect(t, powIntegerExponent(base, 15) == -14348907.)
      tc.expect(t, isclose(powIntegerExponent(base, -1), 1. / -3.))
      tc.expect(t, isclose(powIntegerExponent(base, -2), 1. / 9.))
      tc.expect(t, isclose(powIntegerExponent(base, -3), 1. / -27.))
      tc.expect(t, isclose(powIntegerExponent(base, -4), 1. / 81.))
      tc.expect(t, isclose(powIntegerExponent(base, -15), 1. / -14348907.))
    }
    {
      base := quaternion256(quaternion(-3, 0, 0, 0))
      tc.expect(t, isclose(base, -3.), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == 1.)
      tc.expect(t, powIntegerExponent(base, 1) == -3.)
      tc.expect(t, powIntegerExponent(base, 2) == 9.)
      tc.expect(t, powIntegerExponent(base, 3) == -27.)
      tc.expect(t, powIntegerExponent(base, 4) == 81.)
      tc.expect(t, powIntegerExponent(base, 15) == -14348907.)
      tc.expect(t, isclose(powIntegerExponent(base, -1), 1. / -3.))
      tc.expect(t, isclose(powIntegerExponent(base, -2), 1. / 9.))
      tc.expect(t, isclose(powIntegerExponent(base, -3), 1. / -27.))
      tc.expect(t, isclose(powIntegerExponent(base, -4), 1. / 81.))
      tc.expect(t, isclose(powIntegerExponent(base, -15), 1. / -14348907.))
    }
  }
  {
    // base == 3i
    {
      base := quaternion128(quaternion(0, 3, 0, 0))
      tc.expect(t, isclose(base, type_of(base)(quaternion(0, 3, 0, 0))), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == quaternion(1., 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 1) == quaternion(0., 3., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 2) == quaternion(-9, 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 3) == quaternion(0., -27., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 4) == quaternion(81, 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 15) == quaternion(0, -14348907., 0., 0.))
      tc.expect(t, isclose(powIntegerExponent(base, -1), type_of(base)(1. / quaternion(0., 3., 0., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -2), type_of(base)(1. / quaternion(-9., 0., 0., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -3), type_of(base)(1. / quaternion(0., -27., 0., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -4), type_of(base)(1. / quaternion(81., 0., 0., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -15), type_of(base)(1. / quaternion(0, -14348907., 0., 0.))))
    }
    {
      base := quaternion256(quaternion(0, 3, 0., 0.))
      tc.expect(t, isclose(base, quaternion(0, 3, 0., 0.)), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == quaternion(1., 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 1) == quaternion(0., 3., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 2) == quaternion(-9, 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 3) == quaternion(0., -27., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 4) == quaternion(81, 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 15) == quaternion(0, -14348907., 0., 0.))
      tc.expect(t, isclose(powIntegerExponent(base, -1), 1. / quaternion(0., 3., 0., 0.)))
      tc.expect(t, isclose(powIntegerExponent(base, -2), 1. / quaternion(-9., 0., 0., 0.)))
      tc.expect(t, isclose(powIntegerExponent(base, -3), 1. / quaternion(0., -27., 0., 0.)))
      tc.expect(t, isclose(powIntegerExponent(base, -4), 1. / quaternion(81., 0., 0., 0.)))
      tc.expect(t, isclose(powIntegerExponent(base, -15), 1. / quaternion(0, -14348907., 0., 0.)))
    }
  }
  {
    // base == 3j
    {
      base := quaternion128(quaternion(0, 0, 3, 0))
      tc.expect(t, isclose(base, type_of(base)(quaternion(0, 0, 3, 0))), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == quaternion(1., 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 1) == quaternion(0., 0., 3., 0.))
      tc.expect(t, powIntegerExponent(base, 2) == quaternion(-9, 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 3) == quaternion(0., 0., -27., 0.))
      tc.expect(t, powIntegerExponent(base, 4) == quaternion(81, 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 15) == quaternion(0, 0., -14348907., 0.))
      tc.expect(t, isclose(powIntegerExponent(base, -1), type_of(base)(1. / quaternion(0., 0., 3., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -2), type_of(base)(1. / quaternion(-9., 0., 0., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -3), type_of(base)(1. / quaternion(0., 0., -27., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -4), type_of(base)(1. / quaternion(81., 0., 0., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -15), type_of(base)(1. / quaternion(0, 0., -14348907., 0.))))
    }
    {
      base := quaternion256(quaternion(0, 0., 3, 0.))
      tc.expect(t, isclose(base, quaternion(0, 0., 3, 0.)), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == quaternion(1., 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 1) == quaternion(0., 0., 3., 0.))
      tc.expect(t, powIntegerExponent(base, 2) == quaternion(-9, 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 3) == quaternion(0., 0., -27., 0.))
      tc.expect(t, powIntegerExponent(base, 4) == quaternion(81, 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 15) == quaternion(0, 0., -14348907., 0.))
      tc.expect(t, isclose(powIntegerExponent(base, -1), 1. / quaternion(0., 0., 3., 0.)))
      tc.expect(t, isclose(powIntegerExponent(base, -2), 1. / quaternion(-9., 0., 0., 0.)))
      tc.expect(t, isclose(powIntegerExponent(base, -3), 1. / quaternion(0., 0., -27., 0.)))
      tc.expect(t, isclose(powIntegerExponent(base, -4), 1. / quaternion(81., 0., 0., 0.)))
      tc.expect(t, isclose(powIntegerExponent(base, -15), 1. / quaternion(0, 0., -14348907., 0.)))
    }
  }
  {
    // base == 3k
    {
      base := quaternion128(quaternion(0, 0, 0, 3))
      tc.expect(t, isclose(base, type_of(base)(quaternion(0, 0, 0, 3))), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == quaternion(1., 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 1) == quaternion(0., 0., 0., 3.))
      tc.expect(t, powIntegerExponent(base, 2) == quaternion(-9, 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 3) == quaternion(0., 0., 0., -27.))
      tc.expect(t, powIntegerExponent(base, 4) == quaternion(81, 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 15) == quaternion(0, 0., 0., -14348907.))
      tc.expect(t, isclose(powIntegerExponent(base, -1), type_of(base)(1. / quaternion(0., 0., 0., 3.))))
      tc.expect(t, isclose(powIntegerExponent(base, -2), type_of(base)(1. / quaternion(-9., 0., 0., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -3), type_of(base)(1. / quaternion(0., 0., 0., -27.))))
      tc.expect(t, isclose(powIntegerExponent(base, -4), type_of(base)(1. / quaternion(81., 0., 0., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -15), type_of(base)(1. / quaternion(0, 0., 0., -14348907.))))
    }
    {
      base := quaternion256(quaternion(0, 0., 3, 0.))
      tc.expect(t, isclose(base, quaternion(0, 0., 3, 0.)), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == quaternion(1., 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 1) == quaternion(0., 0., 3., 0.))
      tc.expect(t, powIntegerExponent(base, 2) == quaternion(-9, 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 3) == quaternion(0., 0., -27., 0.))
      tc.expect(t, powIntegerExponent(base, 4) == quaternion(81, 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 15) == quaternion(0, 0., -14348907., 0.))
      tc.expect(t, isclose(powIntegerExponent(base, -1), 1. / quaternion(0., 0., 3., 0.)))
      tc.expect(t, isclose(powIntegerExponent(base, -2), 1. / quaternion(-9., 0., 0., 0.)))
      tc.expect(t, isclose(powIntegerExponent(base, -3), 1. / quaternion(0., 0., -27., 0.)))
      tc.expect(t, isclose(powIntegerExponent(base, -4), 1. / quaternion(81., 0., 0., 0.)))
      tc.expect(t, isclose(powIntegerExponent(base, -15), 1. / quaternion(0, 0., -14348907., 0.)))
    }
  }
  {
    // base == 1+1i
    {
      base := quaternion128(quaternion(1, 1, 0., 0.))
      tc.expect(t, isclose(base, type_of(base)(quaternion(1, 1, 0., 0.))), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == quaternion(1., 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 1) == quaternion(1., 1., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 2) == quaternion(0, 2., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 3) == quaternion(-2., 2., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 4) == quaternion(-4, 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 15) == quaternion(128, -128., 0., 0.))
      tc.expect(t, isclose(powIntegerExponent(base, -1), type_of(base)(1. / quaternion(1., 1., 0., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -2), type_of(base)(1. / quaternion(0., 2., 0., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -3), type_of(base)(1. / quaternion(-2., 2., 0., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -4), type_of(base)(1. / quaternion(-4., 0., 0., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -15), type_of(base)(1. / quaternion(128, -128., 0., 0.))))
    }
    {
      base := quaternion256(quaternion(1, 1, 0., 0.))
      tc.expect(t, isclose(base, type_of(base)(quaternion(1, 1, 0., 0.))), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == quaternion(1., 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 1) == quaternion(1., 1., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 2) == quaternion(0, 2., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 3) == quaternion(-2., 2., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 4) == quaternion(-4, 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 15) == quaternion(128, -128., 0., 0.))
      tc.expect(t, isclose(powIntegerExponent(base, -1), type_of(base)(1. / quaternion(1., 1., 0., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -2), type_of(base)(1. / quaternion(0., 2., 0., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -3), type_of(base)(1. / quaternion(-2., 2., 0., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -4), type_of(base)(1. / quaternion(-4., 0., 0., 0.))))
      tc.expect(t, isclose(powIntegerExponent(base, -15), type_of(base)(1. / quaternion(128, -128., 0., 0.))))
    }
  }
  {
    // base == 1+1i+1j+1k
    {
      base := quaternion128(quaternion(1, 1, 1, 1))
      tc.expect(t, isclose(base, type_of(base)(quaternion(1, 1, 1, 1))), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == quaternion(1., 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 1) == quaternion(1., 1., 1., 1.))
      tc.expect(t, powIntegerExponent(base, 2) == quaternion(-2., 2, 2, 2))
      tc.expect(t, powIntegerExponent(base, 3) == quaternion(-8., 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 4) == quaternion(-8., -8., -8., -8.))
      tc.expect(t, powIntegerExponent(base, 15) == quaternion(-32768., 0., 0., 0.))
      tc.expect(t, isclose(powIntegerExponent(base, -1), type_of(base)(1. / quaternion(1., 1., 1., 1.))))
      tc.expect(t, isclose(powIntegerExponent(base, -2), type_of(base)(1. / quaternion(-2, 2, 2, 2))))
      tc.expect(t, isclose(powIntegerExponent(base, -3), type_of(base)(1. / quaternion(-8, 0, 0, 0))))
      tc.expect(t, isclose(powIntegerExponent(base, -4), type_of(base)(1. / quaternion(-8, -8, -8, -8))))
      tc.expect(t, isclose(powIntegerExponent(base, -15), type_of(base)(1. / quaternion(-32768, 0, 0, 0))))
    }
    {
      base := quaternion256(quaternion(1, 1, 1, 1))
      tc.expect(t, isclose(base, type_of(base)(quaternion(1, 1, 1, 1))), "assignment sanity check")
      tc.expect(t, powIntegerExponent(base, 0) == quaternion(1., 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 1) == quaternion(1., 1., 1., 1.))
      tc.expect(t, powIntegerExponent(base, 2) == quaternion(-2., 2, 2, 2))
      tc.expect(t, powIntegerExponent(base, 3) == quaternion(-8., 0., 0., 0.))
      tc.expect(t, powIntegerExponent(base, 4) == quaternion(-8., -8., -8., -8.))
      tc.expect(t, powIntegerExponent(base, 15) == quaternion(-32768., 0., 0., 0.))
      tc.expect(t, isclose(powIntegerExponent(base, -1), type_of(base)(1. / quaternion(1., 1., 1., 1.))))
      tc.expect(t, isclose(powIntegerExponent(base, -2), type_of(base)(1. / quaternion(-2, 2, 2, 2))))
      tc.expect(t, isclose(powIntegerExponent(base, -3), type_of(base)(1. / quaternion(-8, 0, 0, 0))))
      tc.expect(t, isclose(powIntegerExponent(base, -4), type_of(base)(1. / quaternion(-8, -8, -8, -8))))
      tc.expect(t, isclose(powIntegerExponent(base, -15), type_of(base)(1. / quaternion(-32768, 0, 0, 0))))
    }
  }
}


// Test edge cases for quaternion
@(test, private = "file")
test_zero_quat :: proc(t: ^testing.T) {
  using gm
  using util
  powers := [?]int{-1, -2, -200, 0, 1, 200}
  base := quaternion256(quaternion(0., 0., 0., 0.))
  for power in powers {
    if power >= 0 {
      expected := power == 0 ? quaternion(1., 0, 0., 0.) : quaternion(0., 0., 0., 0.)
      tc.expect(t, powIntegerExponent(quaternion128(quaternion(0., 0., 0., 0.)), power) == quaternion128(expected))
      tc.expect(t, powIntegerExponent(quaternion256(quaternion(0., 0., 0., 0.)), power) == quaternion256(expected))
    } else {
      tc.expect(t, isnan(powIntegerExponent(quaternion128(quaternion(0., 0., 0., 0.)), power)))
      tc.expect(t, isnan(powIntegerExponent(quaternion256(quaternion(0., 0., 0., 0.)), power)))
    }
  }
}

@(test, private = "file")
test_nan_quat :: proc(t: ^testing.T) {
  using gm
  using util
  powers := [?]int{-1, -2, -200, 0, 1, 200}
  nan := math.nan_f64()
  bases := [?]quaternion256{
    initQuaternion(nan, 0., 0., 0., quaternion256),
    initQuaternion(0., nan, 0., 0., quaternion256),
    initQuaternion(0., 0., nan, 0., quaternion256),
    initQuaternion(0., 0., 0., nan, quaternion256),
    initQuaternion(nan, nan, 0., 0., quaternion256),
    initQuaternion(nan, 0., nan, 0., quaternion256),
    initQuaternion(nan, 0., 0., nan, quaternion256),
    initQuaternion(0., nan, nan, 0., quaternion256),
    initQuaternion(0., nan, 0., nan, quaternion256),
    initQuaternion(0., 0., nan, nan, quaternion256),
    initQuaternion(nan, nan, nan, 0., quaternion256),
    initQuaternion(nan, nan, 0., nan, quaternion256),
    initQuaternion(nan, 0., nan, nan, quaternion256),
    initQuaternion(0., nan, nan, nan, quaternion256),
    initQuaternion(nan, nan, nan, nan, quaternion256),
  }
  for base in bases {
    tc.expect(t, isnan(base), "isnan sanity check")
    for power in powers {
      tc.expect(t, isnan(powIntegerExponent(quaternion128(base), power)))
      tc.expect(t, isnan(powIntegerExponent(quaternion256(base), power)))
    }
  }
}

@(test, private = "file")
test_inf_power_quat :: proc(t: ^testing.T) {
  using gm
  using util
  powers := [?]int{-1, -2, -200, 0, 1, 2, 200}
  inf := finfo(f64).inf
  simple_inf_bases := [?]quaternion256 {
    initQuaternion(inf, 0, 0, 0, quaternion256),
    initQuaternion(0, inf, 0, 0, quaternion256),
    initQuaternion(0, 0, inf, 0, quaternion256),
    initQuaternion(0, 0, 0, inf, quaternion256),
    initQuaternion(-inf, 0, 0, 0, quaternion256),
    initQuaternion(0, -inf, 0, 0, quaternion256),
    initQuaternion(0, 0, -inf, 0, quaternion256),
    initQuaternion(0, 0, 0, -inf, quaternion256),
    //////
    // ++
    initQuaternion(+inf, +inf, 0, 0, quaternion256),
    initQuaternion(+inf, 0, +inf, 0, quaternion256),
    initQuaternion(+inf, 0, 0, +inf, quaternion256),
    initQuaternion(0, +inf, +inf, 0, quaternion256),
    initQuaternion(0, +inf, 0, +inf, quaternion256),
    initQuaternion(0, 0, +inf, +inf, quaternion256),
    // +-
    initQuaternion(+inf, +inf, 0, 0, quaternion256),
    initQuaternion(+inf, -inf, 0, 0, quaternion256),
    initQuaternion(+inf, 0, -inf, 0, quaternion256),
    initQuaternion(+inf, 0, 0, -inf, quaternion256),
    initQuaternion(0, +inf, -inf, 0, quaternion256),
    initQuaternion(0, +inf, 0, -inf, quaternion256),
    initQuaternion(0, 0, +inf, -inf, quaternion256),
    // -+
    initQuaternion(-inf, +inf, 0, 0, quaternion256),
    initQuaternion(-inf, 0, +inf, 0, quaternion256),
    initQuaternion(-inf, 0, 0, +inf, quaternion256),
    initQuaternion(0, -inf, +inf, 0, quaternion256),
    initQuaternion(0, -inf, 0, +inf, quaternion256),
    initQuaternion(0, 0, -inf, +inf, quaternion256),
    // --
    initQuaternion(-inf, -inf, 0, 0, quaternion256),
    initQuaternion(-inf, 0, -inf, 0, quaternion256),
    initQuaternion(-inf, 0, 0, -inf, quaternion256),
    initQuaternion(0, -inf, -inf, 0, quaternion256),
    initQuaternion(0, -inf, 0, -inf, quaternion256),
    initQuaternion(0, 0, -inf, -inf, quaternion256),
    //////
    // +++
    initQuaternion(+inf, +inf, +inf, 0, quaternion256),
    initQuaternion(+inf, +inf, 0, +inf, quaternion256),
    initQuaternion(+inf, 0, +inf, +inf, quaternion256),
    initQuaternion(0, +inf, +inf, +inf, quaternion256),
    // ++-
    initQuaternion(+inf, +inf, -inf, 0, quaternion256),
    initQuaternion(+inf, +inf, 0, -inf, quaternion256),
    initQuaternion(+inf, 0, +inf, -inf, quaternion256),
    initQuaternion(0, +inf, +inf, -inf, quaternion256),
    // +-+
    initQuaternion(+inf, -inf, +inf, 0, quaternion256),
    initQuaternion(+inf, -inf, 0, +inf, quaternion256),
    initQuaternion(+inf, 0, -inf, +inf, quaternion256),
    initQuaternion(0, +inf, -inf, +inf, quaternion256),
    // +--
    initQuaternion(+inf, -inf, -inf, 0, quaternion256),
    initQuaternion(+inf, -inf, 0, -inf, quaternion256),
    initQuaternion(+inf, 0, -inf, -inf, quaternion256),
    initQuaternion(0, +inf, -inf, -inf, quaternion256),
    // -++
    initQuaternion(-inf, +inf, +inf, 0, quaternion256),
    initQuaternion(-inf, +inf, 0, +inf, quaternion256),
    initQuaternion(-inf, 0, +inf, +inf, quaternion256),
    initQuaternion(0, -inf, +inf, +inf, quaternion256),
    // -+-
    initQuaternion(-inf, +inf, -inf, 0, quaternion256),
    initQuaternion(-inf, +inf, 0, -inf, quaternion256),
    initQuaternion(-inf, 0, +inf, -inf, quaternion256),
    initQuaternion(0, -inf, +inf, -inf, quaternion256),
    // --+
    initQuaternion(-inf, -inf, +inf, 0, quaternion256),
    initQuaternion(-inf, -inf, 0, +inf, quaternion256),
    initQuaternion(-inf, 0, -inf, +inf, quaternion256),
    initQuaternion(0, -inf, -inf, +inf, quaternion256),
    // ---
    initQuaternion(-inf, -inf, -inf, 0, quaternion256),
    initQuaternion(-inf, -inf, 0, -inf, quaternion256),
    initQuaternion(-inf, 0, -inf, -inf, quaternion256),
    initQuaternion(0, -inf, -inf, -inf, quaternion256),
    ////////
    /// 4
    initQuaternion(+inf, +inf, +inf, +inf, quaternion256),
    initQuaternion(+inf, +inf, +inf, -inf, quaternion256),
    initQuaternion(+inf, +inf, -inf, +inf, quaternion256),
    initQuaternion(+inf, +inf, -inf, -inf, quaternion256),
    initQuaternion(+inf, -inf, +inf, +inf, quaternion256),
    initQuaternion(+inf, -inf, +inf, -inf, quaternion256),
    initQuaternion(+inf, -inf, -inf, +inf, quaternion256),
    initQuaternion(+inf, -inf, -inf, -inf, quaternion256),
    initQuaternion(-inf, +inf, +inf, +inf, quaternion256),
    initQuaternion(-inf, +inf, +inf, -inf, quaternion256),
    initQuaternion(-inf, +inf, -inf, +inf, quaternion256),
    initQuaternion(-inf, +inf, -inf, -inf, quaternion256),
    initQuaternion(-inf, -inf, +inf, +inf, quaternion256),
    initQuaternion(-inf, -inf, +inf, -inf, quaternion256),
    initQuaternion(-inf, -inf, -inf, +inf, quaternion256),
    initQuaternion(-inf, -inf, -inf, -inf, quaternion256),
  }
  for base in simple_inf_bases {
    tc.expect(t, isinf(base), "isnan sanity check")
    for power in powers {
      q128 := powIntegerExponent(quaternion128(base), power)
      q256 := powIntegerExponent(quaternion256(base), power)
      if power < 0 {
        tc.expect(t, powIntegerExponent(quaternion128(base), power) == 0)
        tc.expect(t, powIntegerExponent(quaternion256(base), power) == 0)
      } else if power == 0 {
        tc.expect(t, isnan(powIntegerExponent(quaternion128(base), power)))
        tc.expect(t, isnan(powIntegerExponent(quaternion256(base), power)))
      } else if power == 1 {
        // should be same
        tc.expect(t, quaternion128(base) == quaternion128(base))
        tc.expect(t, powIntegerExponent(quaternion128(base), power) == quaternion128(base))
        tc.expect(t, powIntegerExponent(quaternion256(base), power) == quaternion256(base))
      } else {
        // can be inf or nan
        tc.expect(t, isinf(q128) || isnan(q128))
        tc.expect(t, isinf(q256) || isnan(q256))
      }
    }
  }
}
///////////////////////////////////////////////////////
