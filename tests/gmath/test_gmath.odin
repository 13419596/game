// Must be run with `-collection:tests=` flag
package test_gmath

import "core:fmt"
import "core:testing"
import tc "tests:common"
import "core:intrinsics"
import "core:math"
import "core:c/libc"
import "game:gstrconv"
import "game:gmath"

main :: proc() {
  t := testing.T{}
  run_all(&t)
  tc.report(&t)
}

@(test)
run_all :: proc(t: ^testing.T) {
  runTests_isfinite(t)
  // runTests_isinf(t)
  // runTests_isnan(t)
  // runTests_isnormal(t)
  // runTests_finfo(t)
  // runTests_iinfo(t)
  // runTests_isclose(t)
  // runTests_pow_int(t)
  // runTests_linspace(t)
  // runTests_basic_real(t = t, test_nonnative_endian = false)
  // runTests_basic_complex(t)
  // runTests_basic_quaternion(t)
  runTests_roots(t)
  if false {
    test_tanh(t)
  }
}


@(test)
test_tanh :: proc(t: ^testing.T) {
  using math
  {
    inputs := [?]f16{-INF_F16, -1e4, -10., 5.451, 5.551, 1e4, INF_F16}
    for x in inputs {
      y := tanh(x)
      expected: type_of(x) = x >= 0 ? 1. : -1.
      tc.expect(
        t,
        abs(y - expected) < 1.e-3 && classify(y) != Float_Class.NaN,
        fmt.tprintf("Expected tanh(%T(%v)) to be close to %v. Got: %T(%v)", x, x, expected, y, y),
      )
    }
  }
  {
    inputs := [?]f32{-INF_F32, -1e38, -100., 44.344, 44.444, 1e38, INF_F32}
    for x in inputs {
      y := tanh(x)
      expected: type_of(x) = x >= 0 ? 1. : -1.
      tc.expect(
        t,
        abs(y - expected) < 1.e-5 && classify(y) != Float_Class.NaN,
        fmt.tprintf("Expected tanh(%T(%v)) to be close to %v. Got: %T(%v)", x, x, expected, y, y),
      )
    }
  }
  {
    inputs := [?]f64{-INF_F64, -1e308, -1000., 354.368, 355.368, 1e308, INF_F64}
    for x in inputs {
      y := tanh(x)
      expected := x >= 0 ? 1. : -1.
      tc.expect(
        t,
        abs(y - expected) < 1.e-8 && classify(y) != Float_Class.NaN,
        fmt.tprintf("Expected tanh(%T(%v)) to be close to %v. Got: %T(%v)", x, x, expected, y, y),
      )
    }
  }
}
