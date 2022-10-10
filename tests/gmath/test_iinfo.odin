// subpackage for running `gmath` tests
package test_gmath

import "core:fmt"
import "core:testing"
import "core:math"
import "core:os"
import tc "tests:common"
import gm "game:gmath"

@(test)
runTests_iinfo :: proc(t: ^testing.T) {
  test_iinfo_endianness_flags(t)
  test_iinfo_signed_flags(t)
  test_iinfos(t)
}

////////////////////////////////////////////////////////

@(test)
test_iinfo_endianness_flags :: proc(t: ^testing.T) {
  using gm
  props := [?]IntCommonProperties{
    iinfo(i16),
    iinfo(i32),
    iinfo(i64),
    iinfo(u16),
    iinfo(u32),
    iinfo(u64),
    iinfo(i16be),
    iinfo(i32be),
    iinfo(i64be),
    iinfo(u16be),
    iinfo(u32be),
    iinfo(u64be),
    iinfo(i16le),
    iinfo(i32le),
    iinfo(i64le),
    iinfo(u16le),
    iinfo(u32le),
    iinfo(u64le),
  }
  expected_big_endian_flags := [?]bool {
    // byte types are  don't care 
    (ODIN_ENDIAN == .Big),
    (ODIN_ENDIAN == .Big),
    (ODIN_ENDIAN == .Big),
    (ODIN_ENDIAN == .Big),
    (ODIN_ENDIAN == .Big),
    (ODIN_ENDIAN == .Big), // 6 native types
    true,
    true,
    true,
    true,
    true,
    true, // 6 explicit BE
    false,
    false,
    false,
    false,
    false,
    false, // 6 explicit le
  }
  for prop, idx in props {
    expected_flag := expected_big_endian_flags[idx]
    tc.expect(
      t,
      prop.is_big_endian == expected_flag,
      fmt.tprintf("Expected type:%v big endian flag to be %v but got %v.", prop.type, expected_flag, prop.is_big_endian),
    )
  }
}

@(test)
test_iinfo_signed_flags :: proc(t: ^testing.T) {
  using gm
  props := [?]IntCommonProperties{
    iinfo(i8),
    iinfo(i16),
    iinfo(i32),
    iinfo(i64),
    iinfo(i16be),
    iinfo(i32be),
    iinfo(i64be),
    iinfo(i16le),
    iinfo(i32le),
    iinfo(i64le),
    iinfo(u8),
    iinfo(u16),
    iinfo(u32),
    iinfo(u64),
    iinfo(u16be),
    iinfo(u32be),
    iinfo(u64be),
    iinfo(u16le),
    iinfo(u32le),
    iinfo(u64le),
  }
  expected_signed_flags := [?]bool {
    // 10 signed types
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    // 10 unsigned
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  }
  for prop, idx in props {
    expected_flag := expected_signed_flags[idx]
    tc.expect(
      t,
      prop.is_signed == expected_flag,
      fmt.tprintf("Expected type:%v signed flag to be %v but got %v.", prop.type, expected_flag, prop.is_big_endian),
    )
  }
}

/////////////////////////////////////////////////////////////////

@(test)
test_iinfos :: proc(t: ^testing.T) {
  test_iinfo(t, i8)
  test_iinfo(t, i16)
  test_iinfo(t, i32)
  test_iinfo(t, i64)
  test_iinfo(t, i16be)
  test_iinfo(t, i32be)
  test_iinfo(t, i64be)
  test_iinfo(t, i16le)
  test_iinfo(t, i32le)
  test_iinfo(t, i64le)
  test_iinfo(t, u8)
  test_iinfo(t, u16)
  test_iinfo(t, u32)
  test_iinfo(t, u64)
  test_iinfo(t, u16be)
  test_iinfo(t, u32be)
  test_iinfo(t, u64be)
  test_iinfo(t, u16le)
  test_iinfo(t, u32le)
  test_iinfo(t, u64le)
}

/////////////////////////////////////////////////////////////////

@(private = "file")
test_IntCommonProperties :: proc(t: ^testing.T, props: ^gm.IntCommonProperties) {
  using gm
  i0 := props.type

  // bit count tests
  tc.expect(t, 1 < props.num_bits, fmt.tprintf("%T: num bits should be greater than 0", i0))
  tc.expect(t, 1 < props.num_decimal_digits)
  tc.expect(t, props.num_decimal_digits <= props.num_bits)
}

@(private = "file")
test_iinfo :: proc(t: ^testing.T, $T: typeid) {
  using gm
  i0 := T{}
  info := iinfo(T)

  // TODO print to buffer instead of stdout somehow
  // printIntInfo(&info)

  test_IntCommonProperties(t, &info.properties)

  tc.expect(t, type_of(info.max) == info.type, fmt.tprintf("expected max %T(%v) to be of type %T", info.max, info.max, info.type))
  tc.expect(t, type_of(info.min) == info.type, fmt.tprintf("expected min %T(%v) to be of type %T", info.min, info.min, info.type))

  tc.expect(t, 0 < info.max, fmt.tprintf("Expected max:%T(%v) to be greater than zero.", info.max, info.max))
  tc.expect(t, info.min < info.max, fmt.tprintf("Expected min:%T(%v) to be less than max:%T(%v)", info.min, info.min, info.max, info.max))

  if info.is_signed {
    tc.expect(t, info.min < 0, fmt.tprintf("Expected min:%T(%v) to be less than zero.", info.min, info.min))
  } else {
    tc.expect(t, info.min == 0, fmt.tprintf("Expected min:%T(%v) to be equal to zero.", info.min, info.min))
  }

  mean_value := (info.min / 2) + (info.max / 2)
  if info.is_signed {
    tc.expect(t, mean_value < 0, fmt.tprintf("Expected mean:%T(%v) to be negative for signed type", mean_value, mean_value))
  } else {
    tc.expect(t, mean_value >= 0, fmt.tprintf("Expected mean:%T(%v) to be equal to zero for unsigned type.", mean_value, mean_value))
  }
}
