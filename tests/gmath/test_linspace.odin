// subpackage for running `gmath` tests
package test_gmath

import "core:fmt"
import "core:intrinsics"
import "core:math"
import "core:os"
import "core:testing"
import tc "tests:common"
import gm "game:gmath"
import "game:util"

@(private = "file")
_le :: proc(lhs, rhs: $T) -> bool {
  when intrinsics.type_is_quaternion(T) {
    if real(lhs) > real(rhs) {
      return false
    } else if imag(lhs) > imag(rhs) {
      return false
    } else if jmag(lhs) > jmag(rhs) {
      return false
    } else if kmag(lhs) > kmag(rhs) {
      return false
    }
    return true
  } else when intrinsics.type_is_complex(T) {
    if real(lhs) > real(rhs) {
      return false
    } else if imag(lhs) > imag(rhs) {
      return false
    }
    return true
  } else {
    return lhs <= rhs
  }
}

@(test)
runTests_linspace :: proc(t: ^testing.T) {
  {
    test_linspace_generic(t, f16)
    test_linspace_generic(t, f16le)
    test_linspace_generic(t, f16be)
    test_linspace_generic(t, f32)
    test_linspace_generic(t, f32le)
    test_linspace_generic(t, f32be)
    test_linspace_generic(t, f64)
    test_linspace_generic(t, f64le)
    test_linspace_generic(t, f64be)
  }
  {
    test_linspace_generic(t, i8)
    test_linspace_generic(t, u8)
    test_linspace_generic(t, i16)
    test_linspace_generic(t, i16be)
    test_linspace_generic(t, i16le)
    test_linspace_generic(t, u16)
    test_linspace_generic(t, u16be)
    test_linspace_generic(t, u16le)
    test_linspace_generic(t, i32)
    test_linspace_generic(t, i32be)
    test_linspace_generic(t, i32le)
    test_linspace_generic(t, u32)
    test_linspace_generic(t, u32be)
    test_linspace_generic(t, u32le)
    test_linspace_generic(t, i64)
    test_linspace_generic(t, i64be)
    test_linspace_generic(t, i64le)
    test_linspace_generic(t, u64)
    test_linspace_generic(t, u64be)
    test_linspace_generic(t, u64le)
  }
  {
    test_linspace_generic(t, complex64)
    test_linspace_generic(t, complex128)
  }
  {
    test_linspace_generic(t, quaternion128)
    test_linspace_generic(t, quaternion256)
  }
}


@(private = "file")
test_linspace_generic :: proc(t: ^testing.T, $T: typeid) {
  using gm
  using util
  N :: 10
  when intrinsics.type_is_float(T) {
    mins := [?]T{initFloat(0., T), initFloat(100., T)}
    maxs := [?]T{initFloat(1., T), initFloat(200., T)}
  } else {
    mins := [?]T{T(0.), T(50.)}
    maxs := [?]T{T(1.), T(100.)}
  }
  for _, min_idx in mins {
    min := mins[min_idx]
    max := maxs[min_idx]
    {
      // ascending test
      arr_static := linspace_static(min, max, N)
      arr_dyn := linspace(min, max, N)
      defer delete(arr_dyn)
      arrs := [?][]T{arr_static[:], arr_dyn[:]}
      for arr in arrs {
        tc.expect(t, len(arr) == N)
        tc.expect(t, arr[0] == min, fmt.tprintf("%T: Expected arr[0]:%v to be equal to min:%v.", T{}, arr[0], min))
        tc.expect(t, arr[len(arr) - 1] == max)
        value := arr[0]
        for n in 0 ..< len(arr) {
          tc.expect(t, _le(value, arr[n]), fmt.tprintf("Expected %v to be <= %v.", value, arr[n]))
          value = arr[n]
        }
      }
    }
    {
      // descending test
      arr_static := linspace_static(max, min, N)
      arr_dyn := linspace(max, min, N)
      defer delete(arr_dyn)
      arrs := [?][]T{arr_static[:], arr_dyn[:]}
      for arr in arrs {
        tc.expect(t, len(arr) == N)
        tc.expect(t, arr[0] == max, fmt.tprintf("%T: Expected arr[0]:%v to be equal to max:%v.", T{}, arr[0], max))
        tc.expect(t, arr[len(arr) - 1] == min, fmt.tprintf("%T: Expected arr[-1]:%v to be equal to min:%v.", T{}, arr[len(arr) - 1], min))
        value := arr[0]
        for n in 1 ..< len(arr) {
          tc.expect(t, _le(arr[n], value), fmt.tprintf("Expected %v to be >= %v.", value, arr[n]))
          value = arr[n]
        }
      }
    }
  }
}
