// subpackage for running `gmath` tests
package test_gmath

import "core:fmt"
import "core:testing"
import "core:math"
import "core:os"
import tc "tests:common"
import gm "game:gmath"
import "game:util"

@(test)
runTests_finfo :: proc(t: ^testing.T) {
  test_native_finfo(t)
  test_nonnative_finfo(t)
  test_finfo_endianness_flags(t)
}

/////////////////////////////////////////////////////

@(test)
test_native_finfo :: proc(t: ^testing.T) {
  test_finfo(t, f16)
  test_finfo(t, f32)
  test_finfo(t, f64)

  // check native endian specified floats 
  if ODIN_ENDIAN == .Little {
    test_finfo(t, f16le)
    test_finfo(t, f32le)
    test_finfo(t, f64le)
  } else {
    test_finfo(t, f16be)
    test_finfo(t, f32be)
    test_finfo(t, f64be)
  }

  // compare native floats to native endian specified floats
  if ODIN_ENDIAN == .Little {
    test_compare_finfos(t, f16, f16le)
    test_compare_finfos(t, f32, f32le)
    test_compare_finfos(t, f64, f64le)
  } else {
    test_compare_finfos(t, f16, f16be)
    test_compare_finfos(t, f32, f32be)
    test_compare_finfos(t, f64, f64be)
  }
}

@(test)
test_nonnative_finfo :: proc(t: ^testing.T) {
  // swap from native
  if ODIN_ENDIAN == .Little {
    test_finfo(t, f16be)
    test_finfo(t, f32be)
    test_finfo(t, f64be)
    test_compare_finfos(t, f16, f16be)
    test_compare_finfos(t, f32, f32be)
    test_compare_finfos(t, f64, f64be)
  } else {
    test_finfo(t, f16le)
    test_finfo(t, f32le)
    test_finfo(t, f64le)
    test_compare_finfos(t, f16, f16le)
    test_compare_finfos(t, f32, f32le)
    test_compare_finfos(t, f64, f64le)
  }
  test_compare_finfos(t, f16le, f16be)
  test_compare_finfos(t, f32le, f32be)
  test_compare_finfos(t, f64le, f64be)
}

@(test)
test_finfo_endianness_flags :: proc(t: ^testing.T) {
  using gm
  float_props := [?]FloatCommonProperties{
    finfo(f16),
    finfo(f32),
    finfo(f64),
    finfo(f16be),
    finfo(f32be),
    finfo(f64be),
    finfo(f16le),
    finfo(f32le),
    finfo(f64le),
  }
  expected_big_endian_flags := [?]bool{(ODIN_ENDIAN == .Big), (ODIN_ENDIAN == .Big), (ODIN_ENDIAN == .Big), true, true, true, false, false, false}
  for prop, idx in float_props {
    expected_flag := expected_big_endian_flags[idx]
    tc.expect(
      t,
      prop.is_big_endian == expected_flag,
      fmt.tprintf("Expected type:%v big endian flag to be %v but got %v.", prop.type, expected_flag, prop.is_big_endian),
    )
  }
}

///////////////////////////////////////////////////////////////////////

@(private = "file")
test_FloatCommonProperties :: proc(t: ^testing.T, props: ^gm.FloatCommonProperties) {
  using gm
  f0 := props.type
  max_exponent_value: int = int(1 << props.num_exponent_bits)

  // bit count tests
  tc.expect(t, 1 < props.num_bits, fmt.tprintf("%T: num bits should be greater than 0", f0))
  tc.expect(t, 1 < props.num_mantissa_bits && props.num_mantissa_bits < (props.num_bits - 1), fmt.tprintf("%T: num mantissa bits should be within bounds", f0))
  tc.expect(
    t,
    0 < props.num_exponent_bits && props.num_exponent_bits < (props.num_bits - 1),
    fmt.tprintf("%T: num exponents bits should be within bounds", f0),
  )
  tc.expect(t, (1 + props.num_mantissa_bits + props.num_exponent_bits) == props.num_bits, fmt.tprintf("%T: bit components should add up to total.", f0))

  tc.expect(t, 1 < props.decimal_digit_precision)

  // exponent bounds
  tc.expect(t, 0 < props.max_exp && props.max_exp <= max_exponent_value)
  tc.expect(t, -max_exponent_value <= props.min_exp && props.min_exp < 0)
  tc.expect(t, -max_exponent_value <= props.exponent_bias && props.exponent_bias < 0)
  tc.expect(t, -props.min_exp < props.max_exp)
  tc.expect(t, -props.exponent_bias < props.max_exp)

  // epsilons' exponents
  tc.expect(t, -max_exponent_value <= props.eps_exponent && props.eps_exponent < 0)
  tc.expect(t, -max_exponent_value <= props.epsneg_exponent && props.epsneg_exponent < 0)
  tc.expect(t, props.epsneg_exponent < props.eps_exponent)
}

@(private = "file")
test_finfo :: proc(t: ^testing.T, $F: typeid) {
  using gm
  using util
  fi :: util.initFloat
  info := finfo(F)
  f0 := F{}
  max_exponent_value: int = int(1 << info.num_exponent_bits)

  // TODO print to buffer instead of stdout somehow
  // printFloatInfo(&info)

  test_FloatCommonProperties(t, &info.properties)

  // check type
  tc.expect(t, type_of(info.eps) == info.type)

  // resolution tests
  resolution_within_bounds := fi(0, F) < info.resolution && info.resolution < fi(1, F)
  tc.expect(
    t,
    resolution_within_bounds,
    fmt.tprintf(
      "%T: resolution:% .18e should be within bounds (0,1). 0<r:%v  r<1:%v",
      f0,
      info.resolution,
      fi(0, F) < info.resolution,
      info.resolution < fi(1, F),
    ),
  )

  // eps tests
  tc.expect(
    t,
    fi(0., F) < info.eps && info.eps < fi(1., F),
    fmt.tprintf("%T: eps:% .18e should be within bounds (0,1). 0<eps:%v  eps<1:%v", f0, info.eps, fi(0., F) < info.eps, info.eps < fi(1., F)),
  )
  tc.expect(
    t,
    fi(-1., F) < info.epsneg && info.epsneg < fi(0., F),
    fmt.tprintf(
      "%T: epsneg:%.18e should be within bounds (-1,0). -1<epsneg:%v  epsneg<0:%v",
      f0,
      info.epsneg,
      fi(-1., F) < info.epsneg,
      info.epsneg < fi(0., F),
    ),
  )

  // min/max tests
  tc.expect(t, fi(0., F) < info.max)
  tc.expect(t, info.min < fi(0., F))
  {
    max_m, max_e, max_ok := getFloatParts(f64(info.max))
    tc.expect(t, max_ok, fmt.tprintf("Unable to get float for info.max:%T(%v). value over/underflowed during normal operations", info.max, info.max))

    min_m, min_e, min_ok := getFloatParts(f64(info.min))
    tc.expect(t, min_ok, fmt.tprintf("Unable to get float for info.min:%T(%v). value over/underflowed during normal operations", info.min, info.min))

    nmin := fi(-1. * f64(info.min), F)
    nmin_m, nmin_e, nmin_ok := getFloatParts(f64(nmin))
    tc.expect(t, nmin_ok, fmt.tprintf("Unable to get float for -info.min:%T(%v). value over/underflowed during normal operations", nmin, nmin))

    tc.expect(
      t,
      robustFloatComparison(info.max, -info.min),
      fmt.tprintf("%T maximum:%v.e%d should be equal to negated minimum:%v.e%d (minimum:%v.e%d)", f0, max_m, max_e, nmin_m, nmin_e, min_m, min_e),
    )
  }

  // smallest values tests
  tc.expect(
    t,
    fi(0, F) < info.smallest_normal && info.smallest_normal < fi(1, F),
    fmt.tprintf(
      "%T: smallest_normal:% .18e should be within bounds (0,1). 0<sn:%v  sn<1:%v",
      f0,
      info.smallest_normal,
      fi(0, F) < info.smallest_normal,
      info.smallest_normal < fi(1, F),
    ),
  )
  tc.expect(
    t,
    fi(0., F) < info.smallest_subnormal && info.smallest_subnormal < fi(1, F),
    fmt.tprintf(
      "%T: smallest_subnormal:% .18e should be within bounds (0,1). 0<ssn:%v  ssn<1:%v",
      f0,
      info.smallest_subnormal,
      0 < info.smallest_subnormal,
      info.smallest_subnormal < 1,
    ),
  )
  tc.expect(t, info.smallest_subnormal < info.smallest_normal)

  // check sign on inf
  tc.expect(t, fi(0., F) < info.inf)

  // check that float values are finite(normal)
  field_names := [?]string{"resolution", "eps", "epsneg", "max", "min", "smallest_normal"}
  normal_values := [?]F{info.resolution, info.eps, info.epsneg, info.max, info.min, info.smallest_normal}
  for value, idx in normal_values {
    value_m, value_e, ok := getFloatParts(f64(value))
    tc.expect(
      t,
      ok,
      fmt.tprintf("Unable to get float parts for values[%d]:%T(%v). Encountered strange float behavior. Result: %v %v", idx, value, value, value_m, value_e),
    )
    if ok {
      name := field_names[idx]
      tc.expect(t, isfinite(value), fmt.tprintf("Expected values[%d]:%T(%v.%d) to be finite. (field='%s')", idx, value, value_m, value_e, name))
      tc.expect(t, isnormal(value), fmt.tprintf("Expected values[%d]:%T(%v.%d) to be normal. (field='%s')", idx, value, value_m, value_e, name))
    }
  }

  // check subnormal values
  subnormal_values := [?]F{info.smallest_subnormal}
  for value, idx in subnormal_values {
    tc.expect(t, isfinite(value))
    tc.expect(t, !isnormal(value))
  }

  inf_values := [?]F{info.inf}
  for value in inf_values {
    tc.expect(t, isinf(value))
  }

  // check nan values
  nan_values := [?]F{info.nan}
  for value in nan_values {
    tc.expect(t, isnan(value))
  }

  // Check that values are right on edges
  max_ulp := F(pow2int(info.max_exp - int(info.num_mantissa_bits)))
  tc.expect(t, isposinf(info.max + max_ulp))
  tc.expect(t, !isposinf(info.max + max_ulp / fi(2., F)))

  sn_div_2 := info.smallest_normal / fi(2., F)
  tc.expect(t, info.smallest_subnormal < sn_div_2)
  tc.expect(t, !isnormal(sn_div_2))
}

@(private = "file")
test_compare_finfos :: proc(t: ^testing.T, $F1: typeid, $F2: typeid) {
  using gm
  fi :: util.initFloat
  lhs := finfo(F1)
  rhs := finfo(F2)
  // Int fields should be exact
  tc.expect(t, lhs.num_bits == rhs.num_bits, "field num_bits should be the same")
  tc.expect(t, lhs.num_mantissa_bits == rhs.num_mantissa_bits, "field num_mantissa_bits should be the same")
  tc.expect(t, lhs.num_exponent_bits == rhs.num_exponent_bits, "field num_exponent_bits should be the same")
  tc.expect(t, lhs.decimal_digit_precision == rhs.decimal_digit_precision, "field decimal_digit_precision should be the same")
  tc.expect(t, lhs.max_exp == rhs.max_exp, "field max_exp should be the same")
  tc.expect(t, lhs.min_exp == rhs.min_exp, "field min_exp should be the same")
  tc.expect(t, lhs.exponent_bias == rhs.exponent_bias, "field exponent_bias should be the same")
  tc.expect(t, lhs.eps_exponent == rhs.eps_exponent, "field eps_exponent should be the same")
  tc.expect(t, lhs.epsneg_exponent == rhs.epsneg_exponent, "field epsneg_exponent should be the same")
  //////////
  // Float fields should compare after cast - both ways
  // F1 cast
  tc.expect(t, robustFloatComparison(F1(lhs.resolution), F1(rhs.resolution)), "field resolution should be the same")
  tc.expect(t, robustFloatComparison(F1(lhs.eps), F1(rhs.eps)), "field eps should be the same")
  tc.expect(t, robustFloatComparison(F1(lhs.epsneg), F1(rhs.epsneg)), "field epsneg should be the same")
  tc.expect(t, robustFloatComparison(F1(lhs.max), F1(rhs.max)), "field max should be the same")
  tc.expect(t, robustFloatComparison(F1(lhs.min), F1(rhs.min)), "field min should be the same")
  tc.expect(t, robustFloatComparison(F1(lhs.smallest_normal), F1(rhs.smallest_normal)), "field smallest_normal should be the same")
  tc.expect(t, robustFloatComparison(F1(lhs.smallest_subnormal), F1(rhs.smallest_subnormal)), "field smallest_subnormal should be the same")
  tc.expect(t, robustFloatComparison(F1(lhs.inf), F1(rhs.inf)), "field inf should be the same")
  // F2 cast
  tc.expect(t, robustFloatComparison(F2(lhs.resolution), F2(rhs.resolution)), "field resolution should be the same")
  tc.expect(t, robustFloatComparison(F2(lhs.eps), F2(rhs.eps)), "field eps should be the same")
  tc.expect(t, robustFloatComparison(F2(lhs.epsneg), F2(rhs.epsneg)), "field epsneg should be the same")
  tc.expect(t, robustFloatComparison(F2(lhs.max), F2(rhs.max)), "field max should be the same")
  tc.expect(t, robustFloatComparison(F2(lhs.min), F2(rhs.min)), "field min should be the same")
  tc.expect(t, robustFloatComparison(F2(lhs.smallest_normal), F2(rhs.smallest_normal)), "field smallest_normal should be the same")
  tc.expect(t, robustFloatComparison(F2(lhs.smallest_subnormal), F2(rhs.smallest_subnormal)), "field smallest_subnormal should be the same")
  tc.expect(t, robustFloatComparison(F2(lhs.inf), F2(rhs.inf)), "field inf should be the same")
  tc.expect(t, robustFloatComparison(F2(lhs.nan), F2(rhs.nan)), "field nan should be the same")
}

@(private = "file")
robustFloatComparison :: proc(lhs, rhs: $T) -> bool {
  using gm
  isnan_lhs := isnan(lhs)
  isnan_rhs := isnan(rhs)
  if isnan_lhs && isnan_rhs {
    return true
  } else if isnan_lhs != isnan_rhs {
    return false
  }
  if lhs == rhs {
    return true
  }
  isinf_lhs := isinf(lhs)
  isinf_rhs := isinf(rhs)
  if (isinf_lhs != isinf_rhs) || isinf_lhs || isinf_rhs {
    // if not same, or either is inf, then not equal (because equality has already been checked)
    return false
  }
  // both numbers are not nan or inf's
  // and do not compare equal, but should

  lhs_m, lhs_e, lhs_ok := getFloatParts(f64(lhs))
  if !lhs_ok {
    // some error occured
    return false
  }
  rhs_m, rhs_e, rhs_ok := getFloatParts(f64(rhs))
  if !rhs_ok {
    // some error occured
    return false
  }
  out := (lhs_m == rhs_m) && (lhs_e == rhs_e)
  return out
}
