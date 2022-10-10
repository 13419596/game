// subpackage for running `gmath` tests
package test_gmath

import "core:encoding/csv"
import "core:fmt"
import "core:intrinsics"
import "core:io"
import "core:math"
import "core:path/filepath"
import "core:os"
import "core:strconv"
import "core:testing"
import gm "game:gmath"
import "game:gcsv"
import "game:util"
import tc "tests:common"

@(private = "file")
basic_data_filename :: "tests_basic_quaternion.csv"

@(private = "file")
pow_data_filename :: "tests_pow_quaternion.csv"

@(private = "file")
loadTestDataComplex :: proc(filepath: string) -> (gcsv.CsvTableData(f64), gcsv.CsvTableData(quaternion256)) {
  using gcsv
  rtable := gcsv.readDictOfFloatsFromCsv(filepath)
  qtable := getQuaternionTableFromFloatTable(&rtable)
  return rtable, qtable
}

@(test)
runTests_basic_quaternion :: proc(t: ^testing.T) {
  {
    rtable, qtable := loadTestDataComplex(basic_data_filename)
    defer gcsv.deleteCsvTableData(&rtable)
    defer gcsv.deleteCsvTableData(&qtable)
    inputs, ok := &qtable.data["input"]
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

    if expecteds, ok := qtable.data["conj"]; ok {
      test_basic_conj(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `conj`")
    }
    if expecteds, ok := qtable.data["exp"]; ok {
      test_basic_exp(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `exp`")
    }
    if expecteds, ok := qtable.data["ln"]; ok {
      test_basic_ln(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `ln`")
    }
    if expecteds, ok := qtable.data["sqrt"]; ok {
      test_basic_sqrt(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `sqrt`")
    }
    if expecteds, ok := qtable.data["cbrt"]; ok {
      test_basic_cbrt(t, inputs[:], expecteds[:])
    } else {
      tc.expect(t, ok, "input data file should have `cbrt`")
    }
  }
  {
    rtable, qtable := loadTestDataComplex(pow_data_filename)
    defer gcsv.deleteCsvTableData(&rtable)
    defer gcsv.deleteCsvTableData(&qtable)
    base, base_ok := &qtable.data["base"]
    tc.expect(t, base_ok, "input data file should have `base`")
    if !base_ok {
      return
    }
    exponent, exponent_ok := &qtable.data["exponent"]
    tc.expect(t, exponent_ok, "input data file should have `exponent`")
    if !exponent_ok {
      return
    }
    expecteds, expecteds_ok := &qtable.data["pow"]
    tc.expect(t, expecteds_ok, "input data file should have `pow`")
    if !expecteds_ok {
      return
    }
  }
}

///////////////////////////////////////
// abs

@(private = "file")
test_basic_abs :: proc(t: ^testing.T, inputs: []quaternion256, expecteds: []f64) {
  test_basic_abs_generic(t, quaternion128, inputs, expecteds)
  test_basic_abs_generic(t, quaternion256, inputs, expecteds)
}

@(private = "file")
test_basic_abs_generic :: proc(t: ^testing.T, $T: typeid, inputs: []quaternion256, expecteds: []f64) {
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
test_basic_arg :: proc(t: ^testing.T, inputs: []quaternion256, expecteds: []f64) {
  test_basic_arg_generic(t, quaternion128, inputs, expecteds)
  test_basic_arg_generic(t, quaternion256, inputs, expecteds)
}

@(private = "file")
test_basic_arg_generic :: proc(t: ^testing.T, $T: typeid, inputs: []quaternion256, expecteds: []f64) {
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
test_basic_conj :: proc(t: ^testing.T, inputs: []quaternion256, expecteds: []quaternion256) {
  test_basic_conj_generic(t, quaternion128, inputs, expecteds)
  test_basic_conj_generic(t, quaternion256, inputs, expecteds)
}

@(private = "file")
test_basic_conj_generic :: proc(t: ^testing.T, $T: typeid, inputs: []quaternion256, expecteds: []quaternion256) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := conj(x)
    tc.expect(t, isclose(quaternion256(y), expecteds[idx], rtol), fmt.tprintf("conj(%T(%v)): expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// exp

@(private = "file")
test_basic_exp :: proc(t: ^testing.T, inputs: []quaternion256, expecteds: []quaternion256) {
  test_basic_exp_generic(t, quaternion128, inputs, expecteds)
  test_basic_exp_generic(t, quaternion256, inputs, expecteds)
}

@(private = "file")
test_basic_exp_generic :: proc(t: ^testing.T, $T: typeid, inputs: []quaternion256, expecteds: []quaternion256) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := exp(x)
    tc.expect(t, isclose(quaternion256(y), expecteds[idx], rtol), fmt.tprintf("exp(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// ln

@(private = "file")
test_basic_ln :: proc(t: ^testing.T, inputs: []quaternion256, expecteds: []quaternion256) {
  test_basic_ln_generic(t, quaternion128, inputs, expecteds)
  test_basic_ln_generic(t, quaternion256, inputs, expecteds)
}

@(private = "file")
test_basic_ln_generic :: proc(t: ^testing.T, $T: typeid, inputs: []quaternion256, expecteds: []quaternion256) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := ln(x)
    tc.expect(t, isclose(quaternion256(y), expecteds[idx], rtol), fmt.tprintf("ln(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// sqrt

@(private = "file")
test_basic_sqrt :: proc(t: ^testing.T, inputs: []quaternion256, expecteds: []quaternion256) {
  test_basic_sqrt_generic(t, quaternion128, inputs, expecteds)
  test_basic_sqrt_generic(t, quaternion256, inputs, expecteds)
}

@(private = "file")
test_basic_sqrt_generic :: proc(t: ^testing.T, $T: typeid, inputs: []quaternion256, expecteds: []quaternion256) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := sqrt(x)
    close := isclose(quaternion256(y), expecteds[idx], rtol)
    tc.expect(t, close, fmt.tprintf("sqrt(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// cbrt

@(private = "file")
test_basic_cbrt :: proc(t: ^testing.T, inputs: []quaternion256, expecteds: []quaternion256) {
  test_basic_cbrt_generic(t, quaternion128, inputs, expecteds)
  test_basic_cbrt_generic(t, quaternion256, inputs, expecteds)
}

@(private = "file")
test_basic_cbrt_generic :: proc(t: ^testing.T, $T: typeid, inputs: []quaternion256, expecteds: []quaternion256) {
  // ensure values are close to expected
  using gm
  using util
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    x := T(input)
    y := cbrt(x)
    tc.expect(t, isclose(quaternion256(y), expecteds[idx], rtol), fmt.tprintf("cbrt(%T(%v)): Expected %v ; Got %v", x, x, expecteds[idx], y))
  }
}

///////////////////////////////////////
// pow

@(private = "file")
test_basic_pow :: proc(t: ^testing.T, inputs_base: []quaternion256, inputs_exponent: []quaternion256, expecteds: []quaternion256) {
  tc.expect(t, len(inputs_base) > 0 && len(inputs_exponent) > 0 && len(expecteds) > 0, "Expected all test inputs to be length > 0")
  test_basic_pow_generic(t, inputs_base, inputs_exponent, expecteds, quaternion128)
  test_basic_pow_generic(t, inputs_base, inputs_exponent, expecteds, quaternion256)
}

@(private = "file")
test_basic_pow_generic :: proc(t: ^testing.T, inputs_base: []quaternion256, inputs_exponent: []quaternion256, expecteds: []quaternion256, $T: typeid) {
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
      isclose(quaternion256(y), expecteds[idx], rtol),
      fmt.tprintf("pow(%T(%v), %T(%v)): Expected %v ; Got %v", base, base, exponent, exponent, expecteds[idx], y),
    )
  }
}
