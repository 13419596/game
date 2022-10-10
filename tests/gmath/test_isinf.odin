// subpackage for running `gmath` tests
package test_gmath

import "core:fmt"
import "core:testing"
import tc "tests:common"
import gm "game:gmath"
import "game:util"

@(test)
runTests_isinf :: proc(t: ^testing.T) {
  test_isinf_all_bools(t)
  test_isinf_all_ints(t)
  test_isinf_all_floats(t)
}

@(test)
test_isinf_all_bools :: proc(t: ^testing.T) {
  using gm
  tc.expect(t, !isinf(false))
  tc.expect(t, !isinf(true))
  tc.expect(t, !isinf(b8(false)))
  tc.expect(t, !isinf(b8(true)))
  tc.expect(t, !isinf(b16(false)))
  tc.expect(t, !isinf(b16(true)))
  tc.expect(t, !isinf(b32(false)))
  tc.expect(t, !isinf(b32(true)))
  tc.expect(t, !isinf(b64(false)))
  tc.expect(t, !isinf(b64(true)))
}


///////////////////////////////////////////////////////////////

@(test)
test_isinf_all_ints :: proc(t: ^testing.T) {
  test_isinf_generic_int(t, i8)
  test_isinf_generic_int(t, u8)
  test_isinf_generic_int(t, i16)
  test_isinf_generic_int(t, i16le)
  test_isinf_generic_int(t, i16be)
  test_isinf_generic_int(t, u16)
  test_isinf_generic_int(t, u16le)
  test_isinf_generic_int(t, u16be)
  test_isinf_generic_int(t, i32le)
  test_isinf_generic_int(t, i32be)
  test_isinf_generic_int(t, u32)
  test_isinf_generic_int(t, u32le)
  test_isinf_generic_int(t, u32be)
  test_isinf_generic_int(t, i64le)
  test_isinf_generic_int(t, i64be)
  test_isinf_generic_int(t, u64)
  test_isinf_generic_int(t, u64le)
  test_isinf_generic_int(t, u64be)
}

@(private = "file")
test_isinf_generic_int :: proc(t: ^testing.T, $T: typeid, loc := #caller_location) {
  using gm
  info := iinfo(T)
  tc.expect(t, !isinf(info.min), fmt.tprintf("Expected type:%T to be all finite", T{}))
  tc.expect(t, !isinf(info.max), fmt.tprintf("Expected type:%T to be all finite", T{}))
  tc.expect(t, !isinf(T(0)), fmt.tprintf("Expected type:%T to be all finite", T{}))
}

///////////////////////////////////////////////////////////////

@(test)
test_isinf_all_floats :: proc(t: ^testing.T) {
  test_isinf_generic_float(t, f16)
  test_isinf_generic_float(t, f16le)
  test_isinf_generic_float(t, f16be)
  test_isinf_generic_float(t, f32)
  test_isinf_generic_float(t, f32le)
  test_isinf_generic_float(t, f32be)
  test_isinf_generic_float(t, f64)
  test_isinf_generic_float(t, f64le)
  test_isinf_generic_float(t, f64be)
}

@(private = "file")
test_isinf_generic_float :: proc(t: ^testing.T, $T: typeid) {
  using gm
  using util
  info := finfo(T)
  inf := initFloat(2., T) * info.max
  nan := inf - inf
  sn := info.smallest_normal
  sn_div_2 := sn / initFloat(2., T)
  tc.expect(t, isinf(inf), "+inf is not finite")
  tc.expect(t, isinf(-inf), "-inf is not finite")
  tc.expect(t, !isinf(nan), "nna is not finite")
  tc.expect(t, !isinf(T(+0)), "+zero is finite")
  tc.expect(t, !isinf(T(-0)), "-zero is finite")
  tc.expect(t, !isinf(T(+1.)), "+1 is finite")
  tc.expect(t, !isinf(T(-1.)), "-1 is finite")
  tc.expect(t, !isinf(T(+10.)), "+10 is finite")
  tc.expect(t, !isinf(T(-10.)), "-10 is finite")
  tc.expect(t, !isinf(T(+.1)), "+.1 is finite")
  tc.expect(t, !isinf(T(-.1)), "-.1 is finite")
  tc.expect(t, !isinf(sn), "normal is finite")
  tc.expect(t, !isinf(-sn), "-normal is finite")
  tc.expect(t, !isinf(sn_div_2), "normal/2 is finite")
  tc.expect(t, !isinf(-sn_div_2), "-normal/2 is finite")
  tc.expect(t, !isinf(info.smallest_subnormal), "subnormal is finite")
  tc.expect(t, !isinf(-info.smallest_subnormal), "-subnormal is finite")
}
