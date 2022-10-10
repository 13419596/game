// subpackage for running `gmath` tests
package test_gmath

import "core:fmt"
import "core:path/filepath"
import "core:testing"
import "core:math"
import "core:os"
import tc "tests:common"
import "game:gcsv"
import gm "game:gmath"
import "game:util"

@(private = "file")
basic_data_filename :: "tests_basic_real.csv"

@(private = "file")
pow_data_filename :: "tests_pow_real.csv"

@(private = "file")
loadTestData :: proc(filepath: string) -> gcsv.CsvTableData(f64) {
  using gcsv
  real_table := gcsv.readDictOfFloatsFromCsv(filepath)
  return real_table
}

@(test)
runTests_basic_real :: proc(t: ^testing.T, test_nonnative_endian: bool) {
  {
    test_table := loadTestData(basic_data_filename)
    defer gcsv.deleteCsvTableData(&test_table)
    inputs, ok := &test_table.data["input"]
    tc.expect(t, ok, "input data file should have `input`")

    if expecteds, ok := test_table.data["abs"]; ok {
      test_basic_abs(t, inputs[:], expecteds[:], test_nonnative_endian)
    } else {
      tc.expect(t, ok, "input data file should have `abs`")
    }
    if expecteds, ok := test_table.data["arg"]; ok {
      test_basic_arg(t, inputs[:], expecteds[:], test_nonnative_endian)
    } else {
      tc.expect(t, ok, "input data file should have `arg`")
    }

    if expecteds, ok := test_table.data["acos"]; ok {
      test_basic_acos(t, inputs[:], expecteds[:], test_nonnative_endian)
    } else {
      tc.expect(t, ok, "input data file should have `acos`")
    }
    if expecteds, ok := test_table.data["asin"]; ok {
      test_basic_asin(t, inputs[:], expecteds[:], test_nonnative_endian)
    } else {
      tc.expect(t, ok, "input data file should have `asin`")
    }
    if expecteds, ok := test_table.data["atan"]; ok {
      test_basic_atan(t, inputs[:], expecteds[:], test_nonnative_endian)
    } else {
      tc.expect(t, ok, "input data file should have `atan`")
    }

    if expecteds, ok := test_table.data["cos"]; ok {
      test_basic_cos(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `cos`")
    }
    if expecteds, ok := test_table.data["sin"]; ok {
      test_basic_sin(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `sin`")
    }
    if expecteds, ok := test_table.data["tan"]; ok {
      test_basic_tan(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `tan`")
    }

    if expecteds, ok := test_table.data["acosh"]; ok {
      test_basic_acosh(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `acosh`")
    }
    if expecteds, ok := test_table.data["asinh"]; ok {
      test_basic_asinh(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `asinh`")
    }
    if expecteds, ok := test_table.data["atanh"]; ok {
      test_basic_atanh(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `atanh`")
    }

    if expecteds, ok := test_table.data["cosh"]; ok {
      test_basic_cosh(t, inputs[:], expecteds[:], test_nonnative_endian)
    } else {
      tc.expect(t, ok, "input data file should have `cosh`")
    }
    if expecteds, ok := test_table.data["sinh"]; ok {
      test_basic_sinh(t, inputs[:], expecteds[:], test_nonnative_endian)
    } else {
      tc.expect(t, ok, "input data file should have `sinh`")
    }
    if expecteds, ok := test_table.data["tanh"]; ok {
      test_basic_tanh(t, inputs[:], expecteds[:], test_nonnative_endian)
    } else {
      tc.expect(t, ok, "input data file should have `tanh`")
    }

    if expecteds, ok := test_table.data["exp"]; ok {
      test_basic_exp(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `exp`")
    }
    if expecteds, ok := test_table.data["ln"]; ok {
      test_basic_ln(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `ln`")
    }
    if expecteds, ok := test_table.data["sqrt"]; ok {
      test_basic_sqrt(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `sqrt`")
    }

    if expecteds, ok := test_table.data["cbrt"]; ok {
      test_basic_cbrt(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `cbrt`")
    }
  }
  {
    test_table := loadTestData(pow_data_filename)
    defer gcsv.deleteCsvTableData(&test_table)
    bases, bases_ok := test_table.data["base"]
    tc.expect(t, bases_ok, "input data file should have `base`")
    if !bases_ok {
      return
    }
    exponents, exponents_ok := test_table.data["exponent"]
    tc.expect(t, exponents_ok, "input data file should have `exponents`")
    if !exponents_ok {
      return
    }
    expecteds, expecteds_ok := test_table.data["pow"]
    tc.expect(t, expecteds_ok, "input data file should have `pow`")
    if !expecteds_ok {
      return
    }
    test_basic_pow(t, bases[:], exponents[:], expecteds[:])
  }
}

///////////////////////////////////////
// abs

@(private = "file")
test_basic_abs :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, test_nonnative_endian: bool) {
  test_basic_abs_generic(t, inputs, expecteds, f16)
  test_basic_abs_generic(t, inputs, expecteds, f32)
  test_basic_abs_generic(t, inputs, expecteds, f64)
  if ODIN_ENDIAN == .Little {
    test_basic_abs_generic(t, inputs, expecteds, f16le)
    test_basic_abs_generic(t, inputs, expecteds, f32le)
    test_basic_abs_generic(t, inputs, expecteds, f64le)
  } else {
    test_basic_abs_generic(t, inputs, expecteds, f16be)
    test_basic_abs_generic(t, inputs, expecteds, f32be)
    test_basic_abs_generic(t, inputs, expecteds, f64be)
  }
  if test_nonnative_endian {
    if ODIN_ENDIAN == .Little {
      test_basic_abs_generic(t, inputs, expecteds, f16be)
      test_basic_abs_generic(t, inputs, expecteds, f32be)
      test_basic_abs_generic(t, inputs, expecteds, f64be)
    } else {
      test_basic_abs_generic(t, inputs, expecteds, f16le)
      test_basic_abs_generic(t, inputs, expecteds, f32le)
      test_basic_abs_generic(t, inputs, expecteds, f64le)
    }
  }
}

@(private = "file")
test_basic_abs_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := abs(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("abs(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// arg

@(private = "file")
test_basic_arg :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, test_nonnative_endian: bool) {
  test_basic_arg_generic(t, inputs, expecteds, f16)
  test_basic_arg_generic(t, inputs, expecteds, f32)
  test_basic_arg_generic(t, inputs, expecteds, f64)
  if ODIN_ENDIAN == .Little {
    test_basic_arg_generic(t, inputs, expecteds, f16le)
    test_basic_arg_generic(t, inputs, expecteds, f32le)
    test_basic_arg_generic(t, inputs, expecteds, f64le)
  } else {
    test_basic_arg_generic(t, inputs, expecteds, f16be)
    test_basic_arg_generic(t, inputs, expecteds, f32be)
    test_basic_arg_generic(t, inputs, expecteds, f64be)
  }
  if test_nonnative_endian {
    if ODIN_ENDIAN == .Little {
      test_basic_arg_generic(t, inputs, expecteds, f16be)
      test_basic_arg_generic(t, inputs, expecteds, f32be)
      test_basic_arg_generic(t, inputs, expecteds, f64be)
    } else {
      test_basic_arg_generic(t, inputs, expecteds, f16le)
      test_basic_arg_generic(t, inputs, expecteds, f32le)
      test_basic_arg_generic(t, inputs, expecteds, f64le)
    }
  }
}

@(private = "file")
test_basic_arg_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := arg(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("arg(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// acos

@(private = "file")
test_basic_acos :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, test_nonnative_endian: bool) {
  test_basic_acos_generic(t, inputs, expecteds, f16)
  test_basic_acos_generic(t, inputs, expecteds, f32)
  test_basic_acos_generic(t, inputs, expecteds, f64)
  if ODIN_ENDIAN == .Little {
    test_basic_acos_generic(t, inputs, expecteds, f16le)
    test_basic_acos_generic(t, inputs, expecteds, f32le)
    test_basic_acos_generic(t, inputs, expecteds, f64le)
  } else {
    test_basic_acos_generic(t, inputs, expecteds, f16be)
    test_basic_acos_generic(t, inputs, expecteds, f32be)
    test_basic_acos_generic(t, inputs, expecteds, f64be)
  }
  if test_nonnative_endian {
    if ODIN_ENDIAN == .Little {
      test_basic_acos_generic(t, inputs, expecteds, f16be)
      test_basic_acos_generic(t, inputs, expecteds, f32be)
      test_basic_acos_generic(t, inputs, expecteds, f64be)
    } else {
      test_basic_acos_generic(t, inputs, expecteds, f16le)
      test_basic_acos_generic(t, inputs, expecteds, f32le)
      test_basic_acos_generic(t, inputs, expecteds, f64le)
    }
  }
}

@(private = "file")
test_basic_acos_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := acos(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("acos(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// asin

@(private = "file")
test_basic_asin :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, test_nonnative_endian: bool) {
  test_basic_asin_generic(t, inputs, expecteds, f16)
  test_basic_asin_generic(t, inputs, expecteds, f32)
  test_basic_asin_generic(t, inputs, expecteds, f64)
  if ODIN_ENDIAN == .Little {
    test_basic_asin_generic(t, inputs, expecteds, f16le)
    test_basic_asin_generic(t, inputs, expecteds, f32le)
    test_basic_asin_generic(t, inputs, expecteds, f64le)
  } else {
    test_basic_asin_generic(t, inputs, expecteds, f16be)
    test_basic_asin_generic(t, inputs, expecteds, f32be)
    test_basic_asin_generic(t, inputs, expecteds, f64be)
  }
  if test_nonnative_endian {
    if ODIN_ENDIAN == .Little {
      test_basic_asin_generic(t, inputs, expecteds, f16be)
      test_basic_asin_generic(t, inputs, expecteds, f32be)
      test_basic_asin_generic(t, inputs, expecteds, f64be)
    } else {
      test_basic_asin_generic(t, inputs, expecteds, f16le)
      test_basic_asin_generic(t, inputs, expecteds, f32le)
      test_basic_asin_generic(t, inputs, expecteds, f64le)
    }
  }
}

@(private = "file")
test_basic_asin_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := asin(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("asin(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// atan

@(private = "file")
test_basic_atan :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, test_nonnative_endian: bool) {
  test_basic_atan_generic(t, inputs, expecteds, f16)
  test_basic_atan_generic(t, inputs, expecteds, f32)
  test_basic_atan_generic(t, inputs, expecteds, f64)
  if ODIN_ENDIAN == .Little {
    test_basic_atan_generic(t, inputs, expecteds, f16le)
    test_basic_atan_generic(t, inputs, expecteds, f32le)
    test_basic_atan_generic(t, inputs, expecteds, f64le)
  } else {
    test_basic_atan_generic(t, inputs, expecteds, f16be)
    test_basic_atan_generic(t, inputs, expecteds, f32be)
    test_basic_atan_generic(t, inputs, expecteds, f64be)
  }
  if test_nonnative_endian {
    if ODIN_ENDIAN == .Little {
      test_basic_atan_generic(t, inputs, expecteds, f16be)
      test_basic_atan_generic(t, inputs, expecteds, f32be)
      test_basic_atan_generic(t, inputs, expecteds, f64be)
    } else {
      test_basic_atan_generic(t, inputs, expecteds, f16le)
      test_basic_atan_generic(t, inputs, expecteds, f32le)
      test_basic_atan_generic(t, inputs, expecteds, f64le)
    }
  }
}

@(private = "file")
test_basic_atan_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := atan(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("atan(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// cos

@(private = "file")
test_basic_cos :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64) {
  test_basic_cos_generic(t, inputs, expecteds, f16)
  test_basic_cos_generic(t, inputs, expecteds, f16le)
  test_basic_cos_generic(t, inputs, expecteds, f16be)
  test_basic_cos_generic(t, inputs, expecteds, f32)
  test_basic_cos_generic(t, inputs, expecteds, f32le)
  test_basic_cos_generic(t, inputs, expecteds, f32be)
  test_basic_cos_generic(t, inputs, expecteds, f64)
  test_basic_cos_generic(t, inputs, expecteds, f64le)
  test_basic_cos_generic(t, inputs, expecteds, f64be)
}

@(private = "file")
test_basic_cos_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := cos(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("cos(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}


///////////////////////////////////////
// sin

@(private = "file")
test_basic_sin :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64) {
  test_basic_sin_generic(t, inputs, expecteds, f16)
  test_basic_sin_generic(t, inputs, expecteds, f16le)
  test_basic_sin_generic(t, inputs, expecteds, f16be)
  test_basic_sin_generic(t, inputs, expecteds, f32)
  test_basic_sin_generic(t, inputs, expecteds, f32le)
  test_basic_sin_generic(t, inputs, expecteds, f32be)
  test_basic_sin_generic(t, inputs, expecteds, f64)
  test_basic_sin_generic(t, inputs, expecteds, f64le)
  test_basic_sin_generic(t, inputs, expecteds, f64be)
}

@(private = "file")
test_basic_sin_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := sin(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("sin(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// tan

@(private = "file")
test_basic_tan :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64) {
  test_basic_tan_generic(t, inputs, expecteds, f16)
  test_basic_tan_generic(t, inputs, expecteds, f16le)
  test_basic_tan_generic(t, inputs, expecteds, f16be)
  test_basic_tan_generic(t, inputs, expecteds, f32)
  test_basic_tan_generic(t, inputs, expecteds, f32le)
  test_basic_tan_generic(t, inputs, expecteds, f32be)
  test_basic_tan_generic(t, inputs, expecteds, f64)
  test_basic_tan_generic(t, inputs, expecteds, f64le)
  test_basic_tan_generic(t, inputs, expecteds, f64be)
}

@(private = "file")
test_basic_tan_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := tan(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("tan(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// acosh

@(private = "file")
test_basic_acosh :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64) {
  test_basic_acosh_generic(t, inputs, expecteds, f16)
  test_basic_acosh_generic(t, inputs, expecteds, f16le)
  test_basic_acosh_generic(t, inputs, expecteds, f16be)
  test_basic_acosh_generic(t, inputs, expecteds, f32)
  test_basic_acosh_generic(t, inputs, expecteds, f32le)
  test_basic_acosh_generic(t, inputs, expecteds, f32be)
  test_basic_acosh_generic(t, inputs, expecteds, f64)
  test_basic_acosh_generic(t, inputs, expecteds, f64le)
  test_basic_acosh_generic(t, inputs, expecteds, f64be)
}

@(private = "file")
test_basic_acosh_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := acosh(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("acosh(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// asinh

@(private = "file")
test_basic_asinh :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64) {
  test_basic_asinh_generic(t, inputs, expecteds, f16)
  test_basic_asinh_generic(t, inputs, expecteds, f16le)
  test_basic_asinh_generic(t, inputs, expecteds, f16be)
  test_basic_asinh_generic(t, inputs, expecteds, f32)
  test_basic_asinh_generic(t, inputs, expecteds, f32le)
  test_basic_asinh_generic(t, inputs, expecteds, f32be)
  test_basic_asinh_generic(t, inputs, expecteds, f64)
  test_basic_asinh_generic(t, inputs, expecteds, f64le)
  test_basic_asinh_generic(t, inputs, expecteds, f64be)
}

@(private = "file")
test_basic_asinh_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := asinh(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("asinh(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// atanh

@(private = "file")
test_basic_atanh :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64) {
  test_basic_atanh_generic(t, inputs, expecteds, f16)
  test_basic_atanh_generic(t, inputs, expecteds, f16le)
  test_basic_atanh_generic(t, inputs, expecteds, f16be)
  test_basic_atanh_generic(t, inputs, expecteds, f32)
  test_basic_atanh_generic(t, inputs, expecteds, f32le)
  test_basic_atanh_generic(t, inputs, expecteds, f32be)
  test_basic_atanh_generic(t, inputs, expecteds, f64)
  test_basic_atanh_generic(t, inputs, expecteds, f64le)
  test_basic_atanh_generic(t, inputs, expecteds, f64be)
}

@(private = "file")
test_basic_atanh_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(f64)
  rtol := f64(max(info.resolution, DEFAULT_RTOL * 50.))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := atanh(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("%v: atanh(%T(%v)): Expected % .18e ; Got %v", idx, x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// cosh

@(private = "file")
test_basic_cosh :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, test_nonnative_endian: bool) {
  test_basic_cosh_generic(t, inputs, expecteds, f16)
  test_basic_cosh_generic(t, inputs, expecteds, f32)
  test_basic_cosh_generic(t, inputs, expecteds, f64)
  if ODIN_ENDIAN == .Little {
    test_basic_cosh_generic(t, inputs, expecteds, f16le)
    test_basic_cosh_generic(t, inputs, expecteds, f32le)
    test_basic_cosh_generic(t, inputs, expecteds, f64le)
  } else {
    test_basic_cosh_generic(t, inputs, expecteds, f16be)
    test_basic_cosh_generic(t, inputs, expecteds, f32be)
    test_basic_cosh_generic(t, inputs, expecteds, f64be)
  }
  if test_nonnative_endian {
    if ODIN_ENDIAN == .Little {
      test_basic_cosh_generic(t, inputs, expecteds, f16be)
      test_basic_cosh_generic(t, inputs, expecteds, f32be)
      test_basic_cosh_generic(t, inputs, expecteds, f64be)
    } else {
      test_basic_cosh_generic(t, inputs, expecteds, f16le)
      test_basic_cosh_generic(t, inputs, expecteds, f32le)
      test_basic_cosh_generic(t, inputs, expecteds, f64le)
    }
  }
}

@(private = "file")
test_basic_cosh_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := cosh(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("cosh(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}


///////////////////////////////////////
// sinh

@(private = "file")
test_basic_sinh :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, test_nonnative_endian: bool) {
  test_basic_sinh_generic(t, inputs, expecteds, f16)
  test_basic_sinh_generic(t, inputs, expecteds, f32)
  test_basic_sinh_generic(t, inputs, expecteds, f64)
  if ODIN_ENDIAN == .Little {
    test_basic_sinh_generic(t, inputs, expecteds, f16le)
    test_basic_sinh_generic(t, inputs, expecteds, f32le)
    test_basic_sinh_generic(t, inputs, expecteds, f64le)
  } else {
    test_basic_sinh_generic(t, inputs, expecteds, f16be)
    test_basic_sinh_generic(t, inputs, expecteds, f32be)
    test_basic_sinh_generic(t, inputs, expecteds, f64be)
  }
  if test_nonnative_endian {
    if ODIN_ENDIAN == .Little {
      test_basic_sinh_generic(t, inputs, expecteds, f16be)
      test_basic_sinh_generic(t, inputs, expecteds, f32be)
      test_basic_sinh_generic(t, inputs, expecteds, f64be)
    } else {
      test_basic_sinh_generic(t, inputs, expecteds, f16le)
      test_basic_sinh_generic(t, inputs, expecteds, f32le)
      test_basic_sinh_generic(t, inputs, expecteds, f64le)
    }
  }
}

@(private = "file")
test_basic_sinh_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := sinh(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("sinh(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// tanh

@(private = "file")
test_basic_tanh :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, test_nonnative_endian: bool) {
  test_basic_tanh_generic(t, inputs, expecteds, f16)
  test_basic_tanh_generic(t, inputs, expecteds, f32)
  test_basic_tanh_generic(t, inputs, expecteds, f64)
  if ODIN_ENDIAN == .Little {
    test_basic_tanh_generic(t, inputs, expecteds, f16le)
    test_basic_tanh_generic(t, inputs, expecteds, f32le)
    test_basic_tanh_generic(t, inputs, expecteds, f64le)
  } else {
    test_basic_tanh_generic(t, inputs, expecteds, f16be)
    test_basic_tanh_generic(t, inputs, expecteds, f32be)
    test_basic_tanh_generic(t, inputs, expecteds, f64be)
  }
  if test_nonnative_endian {
    if ODIN_ENDIAN == .Little {
      test_basic_tanh_generic(t, inputs, expecteds, f16be)
      test_basic_tanh_generic(t, inputs, expecteds, f32be)
      test_basic_tanh_generic(t, inputs, expecteds, f64be)
    } else {
      test_basic_tanh_generic(t, inputs, expecteds, f16le)
      test_basic_tanh_generic(t, inputs, expecteds, f32le)
      test_basic_tanh_generic(t, inputs, expecteds, f64le)
    }
  }
}

@(private = "file")
test_basic_tanh_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := tanh(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("tanh(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// exp

@(private = "file")
test_basic_exp :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64) {
  test_basic_exp_generic(t, inputs, expecteds, f16)
  test_basic_exp_generic(t, inputs, expecteds, f16le)
  test_basic_exp_generic(t, inputs, expecteds, f16be)
  test_basic_exp_generic(t, inputs, expecteds, f32)
  test_basic_exp_generic(t, inputs, expecteds, f32le)
  test_basic_exp_generic(t, inputs, expecteds, f32be)
  test_basic_exp_generic(t, inputs, expecteds, f64)
  test_basic_exp_generic(t, inputs, expecteds, f64le)
  test_basic_exp_generic(t, inputs, expecteds, f64be)
}

@(private = "file")
test_basic_exp_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := exp(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("exp(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// ln

@(private = "file")
test_basic_ln :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64) {
  test_basic_ln_generic(t, inputs, expecteds, f16)
  test_basic_ln_generic(t, inputs, expecteds, f16le)
  test_basic_ln_generic(t, inputs, expecteds, f16be)
  test_basic_ln_generic(t, inputs, expecteds, f32)
  test_basic_ln_generic(t, inputs, expecteds, f32le)
  test_basic_ln_generic(t, inputs, expecteds, f32be)
  test_basic_ln_generic(t, inputs, expecteds, f64)
  test_basic_ln_generic(t, inputs, expecteds, f64le)
  test_basic_ln_generic(t, inputs, expecteds, f64be)
}

@(private = "file")
test_basic_ln_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := ln(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("ln(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// sqrt

@(private = "file")
test_basic_sqrt :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64) {
  test_basic_sqrt_generic(t, inputs, expecteds, f16)
  test_basic_sqrt_generic(t, inputs, expecteds, f16le)
  test_basic_sqrt_generic(t, inputs, expecteds, f16be)
  test_basic_sqrt_generic(t, inputs, expecteds, f32)
  test_basic_sqrt_generic(t, inputs, expecteds, f32le)
  test_basic_sqrt_generic(t, inputs, expecteds, f32be)
  test_basic_sqrt_generic(t, inputs, expecteds, f64)
  test_basic_sqrt_generic(t, inputs, expecteds, f64le)
  test_basic_sqrt_generic(t, inputs, expecteds, f64be)
}

@(private = "file")
test_basic_sqrt_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := sqrt(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("sqrt(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// cbrt

@(private = "file")
test_basic_cbrt :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64) {
  test_basic_cbrt_generic(t, inputs, expecteds, f16)
  test_basic_cbrt_generic(t, inputs, expecteds, f16le)
  test_basic_cbrt_generic(t, inputs, expecteds, f16be)
  test_basic_cbrt_generic(t, inputs, expecteds, f32)
  test_basic_cbrt_generic(t, inputs, expecteds, f32le)
  test_basic_cbrt_generic(t, inputs, expecteds, f32be)
  test_basic_cbrt_generic(t, inputs, expecteds, f64)
  test_basic_cbrt_generic(t, inputs, expecteds, f64le)
  test_basic_cbrt_generic(t, inputs, expecteds, f64be)
}

@(private = "file")
test_basic_cbrt_generic :: proc(t: ^testing.T, inputs: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := initFloat(input, T)
    y := cbrt(x)
    tc.expect(t, isclose(f64(y), expecteds[idx], rtol), fmt.tprintf("cbrt(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// pow

@(private = "file")
test_basic_pow :: proc(t: ^testing.T, inputs_base: []f64, inputs_exponent: []f64, expecteds: []f64) {
  tc.expect(t, len(inputs_base) > 0 && len(inputs_exponent) > 0 && len(expecteds) > 0, "Expected all test inputs to be length > 0")
  test_basic_pow_generic(t, inputs_base, inputs_exponent, expecteds, f16)
  test_basic_pow_generic(t, inputs_base, inputs_exponent, expecteds, f16le)
  test_basic_pow_generic(t, inputs_base, inputs_exponent, expecteds, f16be)
  test_basic_pow_generic(t, inputs_base, inputs_exponent, expecteds, f32)
  test_basic_pow_generic(t, inputs_base, inputs_exponent, expecteds, f32le)
  test_basic_pow_generic(t, inputs_base, inputs_exponent, expecteds, f32be)
  test_basic_pow_generic(t, inputs_base, inputs_exponent, expecteds, f64)
  test_basic_pow_generic(t, inputs_base, inputs_exponent, expecteds, f64le)
  test_basic_pow_generic(t, inputs_base, inputs_exponent, expecteds, f64be)
}

@(private = "file")
test_basic_pow_generic :: proc(t: ^testing.T, inputs_base: []f64, inputs_exponent: []f64, expecteds: []f64, $T: typeid) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(T)
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  tc.expect(t, len(inputs_base) > 0 && len(inputs_exponent) > 0 && len(expecteds) > 0, "Expected all test inputs to be length > 0")
  for _, idx in inputs_base {
    base := initFloat(inputs_base[idx], T)
    exponent := initFloat(inputs_exponent[idx], T)
    y := pow(base, exponent)
    tc.expect(
      t,
      isclose(f64(y), expecteds[idx], rtol),
      fmt.tprintf("pow(%T(%v), %T(%v)): Expected %v ; Got %v", base, base, exponent, exponent, expecteds[idx], y),
    )
  }
}
