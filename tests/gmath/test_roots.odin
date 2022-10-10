// subpackage for running `gmath` tests
package test_gmath

import "core:fmt"
import "core:intrinsics"
import "core:math"
import "core:sort"
import "core:testing"
import gm "game:gmath"
import "game:util"
import tc "tests:common"

@(private = "file")
cnan := complex(math.nan_f64(), math.nan_f64())

@(private = "file")
inf := gm.finfo(f64).inf

@(private = "file")
compare_complex :: proc(lhs, rhs: complex128) -> int {
  using gm
  // nans > any
  lnan := isnan(lhs)
  rnan := isnan(rhs)
  if lnan || rnan {
    if lnan {
      return rnan ? 0 : +1
    }
    // rhs is nan & lhs is not, therefore right is greater
    return -1
  }
  lx := real(lhs)
  rx := real(rhs)
  if lx != rx {
    return lx < rx ? -1 : +1
  }
  ly := imag(lhs)
  ry := imag(rhs)
  if ly != ry {
    return ly < ry ? -1 : +1
  }
  return 0
}

@(test)
runTests_roots :: proc(t: ^testing.T) {
  test_quadratic(t)
  test_cubic(t)
}

/////////////////////////////
// Quadratic Roots 

@(test, private = "file")
test_quadratic :: proc(t: ^testing.T, test_nonnative_endian: bool = true) {
  inputs_f64 := [?][3]f64{{1., 0., 1.}, {1, -1, -1}, {0, 0, 0}, {0, 0, 100.}, {0, -100, 100.}, {1, 1, 1}, {inf, 0., 0.}}
  expecteds_f64 := [?][2]complex128{
    {complex(0, -1), complex(0, +1.)},
    {-0.61803399, 1.61803399},
    {cnan, cnan},
    {cnan, cnan},
    {+1, cnan},
    {complex(-.5, -.8660254), complex(-.5, .8660254)},
    {cnan, cnan},
  }

  {
    inputs := inputs_f64
    expecteds := expecteds_f64
    tc.expect(t, len(inputs) == len(expecteds), fmt.tprintf("Input length:%v and Expecteds length:%v should be the same", len(inputs_f64), len(expecteds)))
    test_quadratic_generic(t, inputs[:], expecteds[:], f16)
    test_quadratic_generic(t, inputs[:], expecteds[:], f32)
    test_quadratic_generic(t, inputs[:], expecteds[:], f64)
    if ODIN_ENDIAN == .Little {
      test_quadratic_generic(t, inputs[:], expecteds[:], f16le)
      test_quadratic_generic(t, inputs[:], expecteds[:], f32le)
      test_quadratic_generic(t, inputs[:], expecteds[:], f64le)
    } else {
      test_quadratic_generic(t, inputs[:], expecteds[:], f16be)
      test_quadratic_generic(t, inputs[:], expecteds[:], f32be)
      test_quadratic_generic(t, inputs[:], expecteds[:], f64be)
    }
    if test_nonnative_endian {
      if ODIN_ENDIAN == .Little {
        test_quadratic_generic(t, inputs[:], expecteds[:], f16be)
        test_quadratic_generic(t, inputs[:], expecteds[:], f32be)
        test_quadratic_generic(t, inputs[:], expecteds[:], f64be)
      } else {
        test_quadratic_generic(t, inputs[:], expecteds[:], f16le)
        test_quadratic_generic(t, inputs[:], expecteds[:], f32le)
        test_quadratic_generic(t, inputs[:], expecteds[:], f64le)
      }
    }
  }

  inputs_c128 := [?][3]complex128{{1., complex(1, 1), 1.}}
  expecteds_c128 := [?][2]complex128{{-0.74293414 - 1.52908551i, -0.25706586 + 0.52908551i}}
  {
    inputs := inputs_c128
    expecteds := expecteds_c128
    tc.expect(t, len(inputs) == len(expecteds), fmt.tprintf("Input length:%v and Expecteds length:%v should be the same", len(inputs_f64), len(expecteds)))
    test_quadratic_generic(t, inputs[:], expecteds[:], complex64)
    test_quadratic_generic(t, inputs[:], expecteds[:], complex128)
  }
}

test_quadratic_generic :: proc(t: ^testing.T, inputs: $A/[][3]$E, expecteds: [][2]complex128, $T: typeid) {
  using gm
  using util
  using sort
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    when intrinsics.type_is_float(T) {
      a := initFloat(input[0], T)
      b := initFloat(input[1], T)
      c := initFloat(input[2], T)
    } else {
      a := input[0]
      b := input[1]
      c := input[2]
    }
    roots := solveQuadratic(a, b, c)
    quick_sort_proc(roots[:], compare_complex)
    quick_sort_proc(expecteds[idx][:], compare_complex)
    for root, ri in roots {
      e := expecteds[idx][ri]
      tc.expect(t, isclose(root, e), fmt.tprintf("Test #%v: Expected quadratic root[%v]=%v to be close to %v.", idx, ri, root, e))
    }
  }
}

/////////////////////////////
// Cubic Roots 

@(test, private = "file")
test_cubic :: proc(t: ^testing.T, test_nonnative_endian: bool = true) {
  inputs_f64 := [?][4]f64{
    {0., 1., 0., 1.},
    {0., 1, -1, -1},
    {0., 0, 0, 0},
    {0., 0, 0, 100.},
    {0., 0, -100, 100.},
    {0., 1, 1, 1},
    {1, 1, 1, 1},
    {1, -1, 1, 1},
    {inf, 0., 0., 0.},
  }
  expecteds_f64 := [?][3]complex128{
    {complex(0, -1), complex(0, +1.), cnan},
    {-0.61803399, 1.61803399, cnan},
    {cnan, cnan, cnan},
    {cnan, cnan, cnan},
    {+1, cnan, cnan},
    {complex(-.5, -.8660254), complex(-.5, .8660254), cnan},
    {-1.00000000e+00, -1.i, +1.i},
    {-0.54368901, 0.77184451 - 1.11514251i, 0.77184451 + 1.11514251i},
    {cnan, cnan, cnan},
  }
  {
    inputs := inputs_f64
    expecteds := expecteds_f64
    tc.expect(t, len(inputs) == len(expecteds), fmt.tprintf("Input length:%v and Expecteds length:%v should be the same", len(inputs_f64), len(expecteds)))
    test_cubic_generic(t, inputs[:], expecteds[:], f16)
    test_cubic_generic(t, inputs[:], expecteds[:], f32)
    test_cubic_generic(t, inputs[:], expecteds[:], f64)
    if ODIN_ENDIAN == .Little {
      test_cubic_generic(t, inputs[:], expecteds[:], f16le)
      test_cubic_generic(t, inputs[:], expecteds[:], f32le)
      test_cubic_generic(t, inputs[:], expecteds[:], f64le)
    } else {
      test_cubic_generic(t, inputs[:], expecteds[:], f16be)
      test_cubic_generic(t, inputs[:], expecteds[:], f32be)
      test_cubic_generic(t, inputs[:], expecteds[:], f64be)
    }
    if test_nonnative_endian {
      if ODIN_ENDIAN == .Little {
        test_cubic_generic(t, inputs[:], expecteds[:], f16be)
        test_cubic_generic(t, inputs[:], expecteds[:], f32be)
        test_cubic_generic(t, inputs[:], expecteds[:], f64be)
      } else {
        test_cubic_generic(t, inputs[:], expecteds[:], f16le)
        test_cubic_generic(t, inputs[:], expecteds[:], f32le)
        test_cubic_generic(t, inputs[:], expecteds[:], f64le)
      }
    }
  }

  inputs_c128 := [?][4]complex128{{0., 1., complex(1, 1), 1.}, {1, 1, 1 + 1i, 1.}, {1, 1 + 1i, 0., 0.}}
  expecteds_c128 := [?][3]complex128{
    {-0.74293414 - 1.52908551i, -0.25706586 + 0.52908551i, cnan},
    {-1.04913645 + 0.55265307i, -0.19347236 + 0.65610035i, 0.24260882 - 1.20875341i},
    {-1 - 1i, 0., 0.},
  }
  {
    inputs := inputs_c128
    expecteds := expecteds_c128
    tc.expect(t, len(inputs) == len(expecteds), fmt.tprintf("Input length:%v and Expecteds length:%v should be the same", len(inputs_f64), len(expecteds)))
    test_cubic_generic(t, inputs[:], expecteds[:], complex64)
    test_cubic_generic(t, inputs[:], expecteds[:], complex128)
  }
}

test_cubic_generic :: proc(t: ^testing.T, inputs: $A/[][4]$E, expecteds: [][3]complex128, $T: typeid) {
  using gm
  using util
  using sort
  info := finfo(intrinsics.type_elem_type(T))
  rtol := f64(max(info.resolution, DEFAULT_RTOL))
  for input, idx in inputs {
    when intrinsics.type_is_float(T) {
      a := initFloat(input[0], T)
      b := initFloat(input[1], T)
      c := initFloat(input[2], T)
      d := initFloat(input[3], T)
    } else {
      a := input[0]
      b := input[1]
      c := input[2]
      d := input[3]
    }
    roots := solveCubic(a, b, c, d)
    quick_sort_proc(expecteds[idx][:], compare_complex)
    quick_sort_proc(roots[:], compare_complex)
    for root, ri in roots {
      e := expecteds[idx][ri]
      tc.expect(t, isclose(root, e), fmt.tprintf("Test #%v: Expected cubic root[%v]=%v to be close to %v.", idx, ri, root, e))
    }
  }
}
