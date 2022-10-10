// Must be run with `-collection:tests=` flag
package test_printf_float

import "core:fmt"
import "core:math"
import "core:testing"
import tc "tests:common"

log10_2 :: math.LN2 / math.LN10

get_float_parts :: proc(x: $T) -> (T, int) {
  // This will get you a close result, but may be off a bit because of rounding
  num_digits := int(math.log10(abs(x)) + 1)
  tens_power := num_digits - 1 + (0 if num_digits >= 0 else -1)
  tens_mantissa := x / math.pow(10., T(tens_power))
  return tens_mantissa, tens_power
}


get_leading_digits_powers_of_two :: proc(power: int, num_digits: int = 1, $F: typeid) -> int {
  //  https://math.stackexchange.com/q/2006181
  x := F(power) * log10_2
  d := int(1. + x)
  exponent := x - F(d) + F(num_digits)
  out := math.pow(10., exponent)
  return int(out)
}

main :: proc() {
  t := testing.T{}
  test_printf_float(&t, 5, f16)
  test_printf_float(&t, 5, f16be)
  test_printf_float(&t, 5, f16le)
  test_printf_float(&t, 7, f32)
  test_printf_float(&t, 7, f32be)
  test_printf_float(&t, 7, f32le)
  test_printf_float(&t, 11, f64)
  test_printf_float(&t, 11, f64be)
  test_printf_float(&t, 11, f64le)

  fmt.printf("\n\nFloat printing workaround:\n")
  {
    f := f16(2344)
    m, e := get_float_parts(f)
    fmt.printf("expected           : 2.344e3\n")
    fmt.printf("odin printf        : %e\n", f)
    fmt.printf("work around result : %ve%d\n", m, e)
  }
  {
    f := f64(1 << 1019)
    m, e := get_float_parts(f)
    fmt.printf("expected          : 5.618e306\n")
    fmt.printf("odin printf        : %e\n", f)
    fmt.printf("work around result : %ve%d\n", m, e)
  }
  {
    f := -f64(1 << 1019)
    m, e := get_float_parts(f)
    fmt.printf("expected           : -5.618e306\n")
    fmt.printf("odin printf        : %e\n", f)
    fmt.printf("work around result : %ve%d\n", m, e)
  }
  {
    f := 1.234e-300
    m, e := get_float_parts(f)
    fmt.printf("expected           : 1.234e-300\n")
    fmt.printf("odin printf        : %e\n", f)
    fmt.printf("work around result : %ve%d\n", m, e)
  }
  {
    f := -1.234e-300
    m, e := get_float_parts(f)
    fmt.printf("expected           : -1.234e-300\n")
    fmt.printf("odin printf        : %e\n", f)
    fmt.printf("work around result : %ve%d\n", m, e)
  }
  fmt.printf("\n\n")
  tc.report(&t)
}

@(test)
test_printf_float :: proc(t: ^testing.T, num_exponent_bits: uint, $F: typeid) {
  // Tests positive powers of 2, when formatting floats. 
  // The leading digit can be determined analytically and thus compared to the printf'd result
  buf: [400]byte = {}
  buf2: [400]byte = {}
  int2rune := [?]rune{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}
  start_value := 8.
  max_exponent := (1 << (num_exponent_bits - 1)) - 1
  for n in 4 ..= max_exponent {
    expected_first_digit: int = get_leading_digits_powers_of_two(power = n, num_digits = 1, F = F)
    result_string := fmt.bprintf(buf[:], "%v", math.pow(2., F(n)))
    result_first_digit := (int(result_string[0]) - 48)
    comparison := expected_first_digit == result_first_digit
    tc.expect(
      t,
      comparison,
      fmt.bprintf(buf2[:], "%T 2^(% 4d) expected:%v got:%v - string:\"%v\"", F{}, n, expected_first_digit, result_first_digit, result_string),
    )
  }
}
