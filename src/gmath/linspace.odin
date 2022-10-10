package gmath

import "core:intrinsics"
import "core:fmt"
import "game:util"


linspace_static :: proc(start, stop: $T, $N: uint) -> [N]T {
  // Returns statically allocated array
  out := [N]T{}
  if N == 0 {
    return out
  }
  _assignLinspaceSlice(start, stop, out[:])
  return out
}

@(require_results)
linspace :: proc(start, stop: $T, $N: uint) -> [dynamic]T {
  // Returns dynamically allocated array
  out := make([dynamic]T, N)
  if N == 0 {
    return out
  }
  _assignLinspaceSlice(start, stop, out[:])
  return out
}

@(private = "file")
_assignLinspaceSlice :: proc(start, stop: $T, arr: []T) {
  N := len(arr)
  when intrinsics.type_is_integer(T) {
    when intrinsics.type_is_unsigned(T) {
      is_ascending := start <= stop
      lower_bound := min(start, stop)
      dxN := f64(max(start, stop) - lower_bound) / f64(N - 1)
      if is_ascending {
        // do like normal
        for n in 0 ..< N {
          arr[n] = T(dxN * f64(n)) + start
        }
      } else {
        // assign in reverse
        for n in 0 ..< N {
          idx := N - n - 1
          arr[idx] = T(dxN * f64(n)) + lower_bound
        }
      }
    } else {
      dxN := f64(stop - start) / f64(N - 1)
      for n in 0 ..< N {
        arr[n] = T(dxN * f64(n)) + start
      }
    }
  } else {
    when intrinsics.type_is_float(T) {
      dx := (stop - start) / util.initFloat(f64(N - 1), T) // odin work around
      for n in 0 ..< N {
        arr[n] = dx * util.initFloat(f64(n), T) + start
      }
    } else {
      dx := (stop - start) / T(f64(N - 1))
      for n in 0 ..< N {
        arr[n] = dx * T(f64(n)) + start
      }
    }
    // Ensure exactness at endpoints
    arr[0] = start
    arr[len(arr) - 1] = stop
  }
}
