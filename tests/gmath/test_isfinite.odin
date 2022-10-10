// subpackage for running `gmath` tests
package test_gmath

import "core:fmt"
import "core:testing"
import tc "tests:common"
import gm "game:gmath"
import "game:util"

@(test)
runTests_isfinite :: proc(t: ^testing.T) {
  test_isfinite_all_bools(t)
  test_isfinite_all_ints(t)
  test_isfinite_all_floats(t)
}

@(test)
test_isfinite_all_bools :: proc(t: ^testing.T) {
  using gm
  tc.expect(t, isfinite(false))
  tc.expect(t, isfinite(true))
  tc.expect(t, isfinite(b8(false)))
  tc.expect(t, isfinite(b8(true)))
  tc.expect(t, isfinite(b16(false)))
  tc.expect(t, isfinite(b16(true)))
  tc.expect(t, isfinite(b32(false)))
  tc.expect(t, isfinite(b32(true)))
  tc.expect(t, isfinite(b64(false)))
  tc.expect(t, isfinite(b64(true)))
}


///////////////////////////////////////////////////////////////

@(test)
test_isfinite_all_ints :: proc(t: ^testing.T) {
  test_isfinite_generic_int(t, i8)
  test_isfinite_generic_int(t, u8)
  test_isfinite_generic_int(t, i16)
  test_isfinite_generic_int(t, i16le)
  test_isfinite_generic_int(t, i16be)
  test_isfinite_generic_int(t, u16)
  test_isfinite_generic_int(t, u16le)
  test_isfinite_generic_int(t, u16be)
  test_isfinite_generic_int(t, i32le)
  test_isfinite_generic_int(t, i32be)
  test_isfinite_generic_int(t, u32)
  test_isfinite_generic_int(t, u32le)
  test_isfinite_generic_int(t, u32be)
  test_isfinite_generic_int(t, i64le)
  test_isfinite_generic_int(t, i64be)
  test_isfinite_generic_int(t, u64)
  test_isfinite_generic_int(t, u64le)
  test_isfinite_generic_int(t, u64be)
}

@(private = "file")
test_isfinite_generic_int :: proc(t: ^testing.T, $T: typeid, loc := #caller_location) {
  using gm
  info := iinfo(T)
  tc.expect(t, isfinite(info.min), fmt.tprintf("Expected type:%T to be all finite", T{}))
  tc.expect(t, isfinite(info.max), fmt.tprintf("Expected type:%T to be all finite", T{}))
  tc.expect(t, isfinite(T(0)), fmt.tprintf("Expected type:%T to be all finite", T{}))
}

///////////////////////////////////////////////////////////////

@(test)
test_isfinite_all_floats :: proc(t: ^testing.T) {
  test_isfinite_generic_float(t, f16)
  test_isfinite_generic_float(t, f16le)
  test_isfinite_generic_float(t, f16be)
  test_isfinite_generic_float(t, f32)
  test_isfinite_generic_float(t, f32le)
  test_isfinite_generic_float(t, f32be)
  test_isfinite_generic_float(t, f64)
  test_isfinite_generic_float(t, f64le)
  test_isfinite_generic_float(t, f64be)
}

@(private = "file")
test_isfinite_generic_float :: proc(t: ^testing.T, $T: typeid) {
  using gm
  using util
  info := finfo(T)
  inf := initFloat(2., T) * info.max
  nan := inf - inf
  sn := info.smallest_normal
  sn_div_2 := sn / initFloat(2., T)
  tc.expect(t, !isfinite(inf), "+inf is not finite")
  tc.expect(t, !isfinite(-inf), "-inf is not finite")
  tc.expect(t, !isfinite(nan), "nan is not finite")
  tc.expect(t, isfinite(T(+0)), "+zero is finite")
  tc.expect(t, isfinite(T(-0)), "-zero is finite")
  tc.expect(t, isfinite(T(+1.)), "+1 is finite")
  tc.expect(t, isfinite(T(-1.)), "-1 is finite")
  tc.expect(t, isfinite(T(+10.)), "+10 is finite")
  tc.expect(t, isfinite(T(-10.)), "-10 is finite")
  tc.expect(t, isfinite(T(+.1)), "+.1 is finite")
  tc.expect(t, isfinite(T(-.1)), "-.1 is finite")
  tc.expect(t, isfinite(sn), "normal is finite")
  tc.expect(t, isfinite(-sn), "-normal is finite")
  tc.expect(t, isfinite(sn_div_2), "normal/2 is finite")
  tc.expect(t, isfinite(-sn_div_2), "-normal/2 is finite")
  tc.expect(t, isfinite(info.smallest_subnormal), "subnormal is finite")
  tc.expect(t, isfinite(-info.smallest_subnormal), "-subnormal is finite")
}
