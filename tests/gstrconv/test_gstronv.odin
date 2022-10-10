// Must be run with `-collection:tests=` flag
package test_gmath

import "core:intrinsics"
import "core:math"
import "core:testing"
import "game:gstrconv"
import tc "tests:common"


main :: proc() {
  t := testing.T{}
  run_all(&t)
  tc.report(&t)
}

@(test)
run_all :: proc(t: ^testing.T) {
  test_parse_float(t)
}

test_parse_float :: proc(t: ^testing.T) {
  using gstrconv
  {
    f: f64
    ok: bool
    f, ok = parse_f64("inf")
    tc.expect(t, math.classify(f) == math.Float_Class.Inf, "expected f64(+inf)")
    f, ok = parse_f64("+inf")
    tc.expect(t, math.classify(f) == math.Float_Class.Inf, "expected f64(+inf)")
    f, ok = parse_f64("-inf")
    tc.expect(t, math.classify(f) == math.Float_Class.Neg_Inf, "expected f64(-inf)")
    f, ok = parse_f64("inFinity")
    tc.expect(t, math.classify(f) == math.Float_Class.Inf, "expected f64(+inf)")
    f, ok = parse_f64("+InFinity")
    tc.expect(t, math.classify(f) == math.Float_Class.Inf, "expected f64(+inf)")
    f, ok = parse_f64("-InfiniTy")
    tc.expect(t, math.classify(f) == math.Float_Class.Neg_Inf, "expected f64(-inf)")
    f, ok = parse_f64("nan")
    tc.expect(t, math.classify(f) == math.Float_Class.NaN, "expected f64(nan)")
    f, ok = parse_f64("nAN")
    tc.expect(t, math.classify(f) == math.Float_Class.NaN, "expected f64(nan)")
  }
  {
    f: f32
    ok: bool
    f, ok = parse_f32("inf")
    tc.expect(t, math.classify(f) == math.Float_Class.Inf, "expected f32(+inf)")
    f, ok = parse_f32("+inf")
    tc.expect(t, math.classify(f) == math.Float_Class.Inf, "expected f32(+inf)")
    f, ok = parse_f32("-inf")
    tc.expect(t, math.classify(f) == math.Float_Class.Neg_Inf, "expected f32(-inf)")
    f, ok = parse_f32("inFinity")
    tc.expect(t, math.classify(f) == math.Float_Class.Inf, "expected f32(+inf)")
    f, ok = parse_f32("+InFinity")
    tc.expect(t, math.classify(f) == math.Float_Class.Inf, "expected f32(+inf)")
    f, ok = parse_f32("-InfiniTy")
    tc.expect(t, math.classify(f) == math.Float_Class.Neg_Inf, "expected f32(-inf)")
    f, ok = parse_f32("nan")
    tc.expect(t, math.classify(f) == math.Float_Class.NaN, "expected f32(nan)")
    f, ok = parse_f32("nAN")
    tc.expect(t, math.classify(f) == math.Float_Class.NaN, "expected f32(nan)")
  }
}
