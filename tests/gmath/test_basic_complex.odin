// subpackage for running `gmath` tests
package test_gmath

import "core:fmt"
import "core:intrinsics"
import "core:math"
import "core:os"
import "core:testing"
import tc "tests:common"
import gm "game:gmath"
import "game:gcsv"
import "game:util"
import "core:encoding/csv"
import "core:io"
import "core:path/filepath"
import "core:strconv"

@(private = "file")
basic_data_filename :: "tests_basic_complex.csv"

@(private = "file")
pow_data_filename :: "tests_pow_complex.csv"

@(private = "file")
loadTestDataComplex :: proc(filepath: string) -> (gcsv.CsvTableData(f64), gcsv.CsvTableData(complex128)) {
  using gcsv
  rtable := gcsv.readDictOfFloatsFromCsv(filepath)
  ctable := getComplexTableFromFloatTable(&rtable)
  return rtable, ctable
}

@(test)
runTests_basic_complex :: proc(t: ^testing.T) {
  {
    rtable, ctable := loadTestDataComplex(basic_data_filename)
    defer gcsv.deleteCsvTableData(&rtable)
    defer gcsv.deleteCsvTableData(&ctable)
    inputs, ok := &ctable.data["input"]
    tc.expect(t, ok, "input data file should have `input`")

    if expecteds, ok := rtable.data["abs"]; ok {
      test_basic_abs(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `abs`")
    }
    if expecteds, ok := rtable.data["arg"]; ok {
      test_basic_arg(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `arg`")
    }

    if expecteds, ok := ctable.data["conj"]; ok {
      test_basic_conj(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `conj`")
    }
    if expecteds, ok := ctable.data["acos"]; ok {
      test_basic_acos(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `acos`")
    }
    if expecteds, ok := ctable.data["asin"]; ok {
      test_basic_asin(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `asin`")
    }
    if expecteds, ok := ctable.data["atan"]; ok {
      test_basic_atan(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `atan`")
    }

    if expecteds, ok := ctable.data["cos"]; ok {
      test_basic_cos(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `cos`")
    }
    if expecteds, ok := ctable.data["sin"]; ok {
      test_basic_sin(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `sin`")
    }
    if expecteds, ok := ctable.data["tan"]; ok {
      test_basic_tan(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `tan`")
    }

    if expecteds, ok := ctable.data["acosh"]; ok {
      test_basic_acosh(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `acosh`")
    }
    if expecteds, ok := ctable.data["asinh"]; ok {
      test_basic_asinh(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `asinh`")
    }
    if expecteds, ok := ctable.data["atanh"]; ok {
      test_basic_atanh(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `atanh`")
    }

    if expecteds, ok := ctable.data["cosh"]; ok {
      test_basic_cosh(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `cosh`")
    }
    if expecteds, ok := ctable.data["sinh"]; ok {
      test_basic_sinh(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `sinh`")
    }
    if expecteds, ok := ctable.data["tanh"]; ok {
      test_basic_tanh(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `tanh`")
    }

    if expecteds, ok := ctable.data["exp"]; ok {
      test_basic_exp(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `exp`")
    }
    if expecteds, ok := ctable.data["ln"]; ok {
      test_basic_ln(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `ln`")
    }
    if expecteds, ok := ctable.data["sqrt"]; ok {
      test_basic_sqrt(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `sqrt`")
    }
    if expecteds, ok := ctable.data["cbrt"]; ok {
      test_basic_cbrt(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `cbrt`")
    }
  }
  {
    rtable, ctable := loadTestDataComplex(pow_data_filename)
    defer gcsv.deleteCsvTableData(&rtable)
    defer gcsv.deleteCsvTableData(&ctable)
    base, base_ok := &ctable.data["base"]
    tc.expect(t, base_ok, "input data file should have `base`")
    if !base_ok {
      return
    }
    exponent, exponent_ok := &ctable.data["exponent"]
    tc.expect(t, exponent_ok, "input data file should have `exponent`")
    if !exponent_ok {
      return
    }
    expecteds, expecteds_ok := &ctable.data["pow"]
    tc.expect(t, expecteds_ok, "input data file should have `pow`")
    if !expecteds_ok {
      return
    }
  }
}

///////////////////////////////////////
// abs

@(private = "file")
test_basic_abs :: proc(t: ^testing.T, inputs: []complex128, expecteds: []f64) {
  test_basic_abs_generic(t, complex64, inputs, expecteds)
  test_basic_abs_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_abs_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []f64) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := abs(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("abs(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// arg

@(private = "file")
test_basic_arg :: proc(t: ^testing.T, inputs: []complex128, expecteds: []f64) {
  test_basic_arg_generic(t, complex64, inputs, expecteds)
  test_basic_arg_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_arg_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []f64) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := arg(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("arg(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// conj

@(private = "file")
test_basic_conj :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_conj_generic(t, complex64, inputs, expecteds)
  test_basic_conj_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_conj_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := conj(x)
    tc.expect(t, isclose(complex128(y), expecteds[idx], rtol), fmt.tprintf("conj(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// acos

@(private = "file")
test_basic_acos :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_acos_generic(t, complex64, inputs, expecteds)
  test_basic_acos_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_acos_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := acos(x)
    tc.expect(t, isclose(complex128(y), expecteds[idx], rtol), fmt.tprintf("acos(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// asin

@(test)
test_basic_asin :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_asin_generic(t, complex64, inputs, expecteds)
  test_basic_asin_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_asin_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := asin(x)
    tc.expect(t, isclose(type_of(expecteds[idx])(y), expecteds[idx], rtol), fmt.tprintf("asin(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// atan

@(test)
test_basic_atan :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_atan_generic(t, complex64, inputs, expecteds)
  test_basic_atan_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_atan_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := atan(x)
    tc.expect(t, isclose(type_of(expecteds[idx])(y), expecteds[idx], rtol), fmt.tprintf("atan(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// cos

@(private = "file")
test_basic_cos :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_cos_generic(t, complex64, inputs, expecteds)
  test_basic_cos_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_cos_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := cos(x)
    tc.expect(t, isclose(complex128(y), expecteds[idx], rtol), fmt.tprintf("cos(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// sin

@(test)
test_basic_sin :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_sin_generic(t, complex64, inputs, expecteds)
  test_basic_sin_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_sin_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := sin(x)
    tc.expect(t, isclose(type_of(expecteds[idx])(y), expecteds[idx], rtol), fmt.tprintf("sin(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// tan

@(test)
test_basic_tan :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_tan_generic(t, complex64, inputs, expecteds)
  test_basic_tan_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_tan_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL * 10))
  for input, idx in inputs {
    x := T(input)
    y := tan(x)
    tc.expect(t, isclose(type_of(expecteds[idx])(y), expecteds[idx], rtol), fmt.tprintf("tan(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// acosh

@(private = "file")
test_basic_acosh :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_acosh_generic(t, complex64, inputs, expecteds)
  test_basic_acosh_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_acosh_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := acosh(x)
    tc.expect(t, isclose(complex128(y), expecteds[idx], rtol), fmt.tprintf("acosh(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// asinh

@(test)
test_basic_asinh :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_asinh_generic(t, complex64, inputs, expecteds)
  test_basic_asinh_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_asinh_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := asinh(x)
    tc.expect(t, isclose(type_of(expecteds[idx])(y), expecteds[idx], rtol), fmt.tprintf("asinh(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// atanh

@(test)
test_basic_atanh :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_atanh_generic(t, complex64, inputs, expecteds)
  test_basic_atanh_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_atanh_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := atanh(x)
    tc.expect(t, isclose(type_of(expecteds[idx])(y), expecteds[idx], rtol), fmt.tprintf("atanh(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// cosh

@(private = "file")
test_basic_cosh :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_cosh_generic(t, complex64, inputs, expecteds)
  test_basic_cosh_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_cosh_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := cosh(x)
    tc.expect(t, isclose(complex128(y), expecteds[idx], rtol), fmt.tprintf("cosh(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// sinh

@(test)
test_basic_sinh :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_sinh_generic(t, complex64, inputs, expecteds)
  test_basic_sinh_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_sinh_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := sinh(x)
    tc.expect(t, isclose(type_of(expecteds[idx])(y), expecteds[idx], rtol), fmt.tprintf("sinh(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// tanh

@(test)
test_basic_tanh :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_tanh_generic(t, complex64, inputs, expecteds)
  test_basic_tanh_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_tanh_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL * 10))
  for input, idx in inputs {
    x := T(input)
    y := tanh(x)
    tc.expect(t, isclose(type_of(expecteds[idx])(y), expecteds[idx], rtol), fmt.tprintf("tanh(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// exp

@(private = "file")
test_basic_exp :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_exp_generic(t, complex64, inputs, expecteds)
  test_basic_exp_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_exp_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := exp(x)
    tc.expect(t, isclose(complex128(y), expecteds[idx], rtol), fmt.tprintf("exp(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// ln

@(private = "file")
test_basic_ln :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_ln_generic(t, complex64, inputs, expecteds)
  test_basic_ln_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_ln_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := ln(x)
    tc.expect(t, isclose(complex128(y), expecteds[idx], rtol), fmt.tprintf("ln(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// sqrt

@(private = "file")
test_basic_sqrt :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_sqrt_generic(t, complex64, inputs, expecteds)
  test_basic_sqrt_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_sqrt_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := sqrt(x)
    tc.expect(t, isclose(complex128(y), expecteds[idx], rtol), fmt.tprintf("sqrt(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// cbrt

@(private = "file")
test_basic_cbrt :: proc(t: ^testing.T, inputs: []complex128, expecteds: []complex128) {
  test_basic_cbrt_generic(t, complex64, inputs, expecteds)
  test_basic_cbrt_generic(t, complex128, inputs, expecteds)
}

@(private = "file")
test_basic_cbrt_generic :: proc(t: ^testing.T, $T: typeid, inputs: []complex128, expecteds: []complex128) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := cbrt(x)
    tc.expect(t, isclose(complex128(y), expecteds[idx], rtol), fmt.tprintf("cbrt(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// pow

@(private = "file")
test_basic_pow :: proc(t: ^testing.T, inputs_base: []complex128, inputs_exponent: []complex128, expecteds: []complex128) {
  tc.expect(t, len(inputs_base) > 0 && len(inputs_exponent) > 0 && len(expecteds) > 0, "Expected all test inputs to be length > 0")
  test_basic_pow_generic(t, inputs_base, inputs_exponent, expecteds, complex64)
  test_basic_pow_generic(t, inputs_base, inputs_exponent, expecteds, complex128)
}

@(private = "file")
test_basic_pow_generic :: proc(t: ^testing.T, inputs_base: []complex128, inputs_exponent: []complex128, expecteds: []complex128, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for _, idx in inputs_base {
    base := inputs_base[idx]
    exponent := inputs_exponent[idx]
    y := pow(base, exponent)
    tc.expect(
      t,
      isclose(complex128(y), expecteds[idx], rtol),
      fmt.tprintf("pow(%T(%v), %T(%v)): Expected %v ; Got %v", base, base, exponent, exponent, expecteds[idx], y),
    )
  }
}
