// subpackage for running `gmath` tests
package test_gmath

import "core:fmt"
import "core:testing"
import tc "tests:common"
import gm "game:gmath"
import "game:util"

@(test)
runTests_isnormal :: proc(t: ^testing.T) {
  test_isnormal_all_bools(t)
  test_isnormal_all_ints(t)
  test_isnormal_all_floats(t)
}

@(test)
test_isnormal_all_bools :: proc(t: ^testing.T) {
  using gm
  tc.expect(t, isnormal(false))
  tc.expect(t, isnormal(true))
  tc.expect(t, isnormal(b8(false)))
  tc.expect(t, isnormal(b8(true)))
  tc.expect(t, isnormal(b16(false)))
  tc.expect(t, isnormal(b16(true)))
  tc.expect(t, isnormal(b32(false)))
  tc.expect(t, isnormal(b32(true)))
  tc.expect(t, isnormal(b64(false)))
  tc.expect(t, isnormal(b64(true)))
}


///////////////////////////////////////////////////////////////

@(test)
test_isnormal_all_ints :: proc(t: ^testing.T) {
  test_isnormal_generic_int(t, i8)
  test_isnormal_generic_int(t, u8)
  test_isnormal_generic_int(t, i16)
  test_isnormal_generic_int(t, i16le)
  test_isnormal_generic_int(t, i16be)
  test_isnormal_generic_int(t, u16)
  test_isnormal_generic_int(t, u16le)
  test_isnormal_generic_int(t, u16be)
  test_isnormal_generic_int(t, i32le)
  test_isnormal_generic_int(t, i32be)
  test_isnormal_generic_int(t, u32)
  test_isnormal_generic_int(t, u32le)
  test_isnormal_generic_int(t, u32be)
  test_isnormal_generic_int(t, i64le)
  test_isnormal_generic_int(t, i64be)
  test_isnormal_generic_int(t, u64)
  test_isnormal_generic_int(t, u64le)
  test_isnormal_generic_int(t, u64be)
}

@(private = "file")
test_isnormal_generic_int :: proc(t: ^testing.T, $T: typeid, loc := #caller_location) {
  using gm
  info := iinfo(T)
  tc.expect(t, isnormal(info.min), fmt.tprintf("Expected type:%T to be all normal", T{}))
  tc.expect(t, isnormal(info.max), fmt.tprintf("Expected type:%T to be all normal", T{}))
  tc.expect(t, isnormal(T(0)), fmt.tprintf("Expected type:%T to be all normal", T{}))
}

///////////////////////////////////////////////////////////////

@(test)
test_isnormal_all_floats :: proc(t: ^testing.T) {
  test_isnormal_generic_float(t, f16)
  test_isnormal_generic_float(t, f16le)
  test_isnormal_generic_float(t, f16be)
  test_isnormal_generic_float(t, f32)
  test_isnormal_generic_float(t, f32le)
  test_isnormal_generic_float(t, f32be)
  test_isnormal_generic_float(t, f64)
  test_isnormal_generic_float(t, f64le)
  test_isnormal_generic_float(t, f64be)
}

@(private = "file")
test_isnormal_generic_float :: proc(t: ^testing.T, $T: typeid) {
  using gm
  using util
  info := finfo(T)
  inf := initFloat(2., T) * info.max
  nan := inf - inf
  sn := info.smallest_normal
  sn_div_2 := sn / initFloat(2., T)
  tc.expect(t, !isnormal(inf), "+inf is not normal")
  tc.expect(t, !isnormal(-inf), "-inf is not normal")
  tc.expect(t, !isnormal(nan), "nan is not normal")
  tc.expect(t, isnormal(initFloat(+0, T)), "+zero is normal")
  tc.expect(t, isnormal(initFloat(-0, T)), "-zero is normal")
  tc.expect(t, isnormal(initFloat(+1., T)), "+1 is normal")
  tc.expect(t, isnormal(initFloat(-1., T)), "-1 is normal")
  tc.expect(t, isnormal(initFloat(+10., T)), "+10 is normal")
  tc.expect(t, isnormal(initFloat(-10., T)), "-10 is normal")
  tc.expect(t, isnormal(initFloat(+.1, T)), "+.1 is normal")
  tc.expect(t, isnormal(initFloat(-.1, T)), "-.1 is normal")
  tc.expect(t, isnormal(sn), "normal is normal")
  tc.expect(t, isnormal(-sn), "-normal is normal")
  tc.expect(t, !isnormal(sn_div_2), "normal/2 is normal")
  tc.expect(t, !isnormal(-sn_div_2), "-normal/2 is normal")
  tc.expect(t, !isnormal(info.smallest_subnormal), "subnormal is normal")
  tc.expect(t, !isnormal(-info.smallest_subnormal), "-subnormal is normal")
}
