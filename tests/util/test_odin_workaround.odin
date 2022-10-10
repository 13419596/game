// subpackage for running `gmath` tests
package test_util

import "core:fmt"
import "core:testing"
import tc "tests:common"
import util "game:util"
import gm "game:gmath"

@(test)
runTests_odin_workaround :: proc(t: ^testing.T) {
  runTests_odin_workaround_initFloat(t)
  runTests_odin_workaround_initQuat(t)
}

@(test)
runTests_odin_workaround_initFloat :: proc(t: ^testing.T) {
  // mainly sanity checks to see that yea verily a value assigned to a variable is actually assigned
  using util
  using gm
  values := [?]f64{0., -0., 1., 100., 1000., -1., -100., -1000., 0.25, -0.25}
  for value in values {
    {
      // native floats
      {
        x := initFloat(value, f16)
        tc.expect(t, f64(x) == value)
        tc.expect(t, value == f64(x))
        tc.expect(t, isclose(f64(x), value))
        tc.expect(t, isclose(x, type_of(x)(value)))
      }
      {
        x := initFloat(value, f32)
        tc.expect(t, f64(x) == value)
        tc.expect(t, value == f64(x))
        tc.expect(t, isclose(f64(x), value))
        tc.expect(t, isclose(x, type_of(x)(value)))
      }
      {
        x := initFloat(value, f64)
        tc.expect(t, f64(x) == value)
        tc.expect(t, value == f64(x))
        tc.expect(t, isclose(f64(x), value))
        tc.expect(t, isclose(x, type_of(x)(value)))
      }
      {
        x := initFloat(value, f16le)
        tc.expect(t, f64(x) == value)
        tc.expect(t, value == f64(x))
        tc.expect(t, isclose(f64(x), value))
        tc.expect(t, isclose(x, type_of(x)(value)))
      }
    }
    {
      // Little Endian floats
      {
        x := initFloat(value, f16le)
        tc.expect(t, f64(x) == value)
        tc.expect(t, value == f64(x))
        tc.expect(t, isclose(f64(x), value))
        tc.expect(t, isclose(x, type_of(x)(value)))
      }
      {
        x := initFloat(value, f32le)
        tc.expect(t, f64(x) == value)
        tc.expect(t, value == f64(x))
        tc.expect(t, isclose(f64(x), value))
        tc.expect(t, isclose(x, type_of(x)(value)))
      }
      {
        x := initFloat(value, f64le)
        tc.expect(t, f64(x) == value)
        tc.expect(t, value == f64(x))
        tc.expect(t, isclose(f64(x), value))
        tc.expect(t, isclose(x, type_of(x)(value)))
      }
      {
        x := initFloat(value, f16le)
        tc.expect(t, f64(x) == value)
        tc.expect(t, value == f64(x))
        tc.expect(t, isclose(f64(x), value))
        tc.expect(t, isclose(x, type_of(x)(value)))
      }
    }
    {
      // BIG Endian floats
      {
        x := initFloat(value, f16le)
        tc.expect(t, f64(x) == value)
        tc.expect(t, value == f64(x))
        tc.expect(t, isclose(f64(x), value))
        tc.expect(t, isclose(x, type_of(x)(value)))
      }
      {
        x := initFloat(value, f32le)
        tc.expect(t, f64(x) == value)
        tc.expect(t, value == f64(x))
        tc.expect(t, isclose(f64(x), value))
        tc.expect(t, isclose(x, type_of(x)(value)))
      }
      {
        x := initFloat(value, f64le)
        tc.expect(t, f64(x) == value)
        tc.expect(t, value == f64(x))
        tc.expect(t, isclose(f64(x), value))
        tc.expect(t, isclose(x, type_of(x)(value)))
      }
      {
        x := initFloat(value, f16le)
        tc.expect(t, f64(x) == value)
        tc.expect(t, value == f64(x))
        tc.expect(t, isclose(f64(x), value))
        tc.expect(t, isclose(x, type_of(x)(value)))
      }
    }
  }
}

@(test)
runTests_odin_workaround_initQuat :: proc(t: ^testing.T) {
  using util
  using gm
  {
    // zero specified
    tc.expect(t, quaternion(f32(1.), f32(2.), f32(3.), f32(4.)) == initQuaternion(f32(2.), f32(3.), f32(4.), f32(1.), quaternion128))
    tc.expect(t, quaternion(1., 2., 3., 4.) == initQuaternion(2., 3., 4., 1., quaternion256))
  }
  {
    // single specified
    a := f64(10.)
    tc.expect(t, quaternion(10., 2., 3., 4.) == initQuaternion(2., 3., 4., a, quaternion256))
    tc.expect(t, quaternion(1., 10., 3., 4.) == initQuaternion(a, 3., 4., 1., quaternion256))
    tc.expect(t, quaternion(1., 2., 10., 4.) == initQuaternion(2., a, 4., 1., quaternion256))
    tc.expect(t, quaternion(1., 2., 3., 10.) == initQuaternion(2., 3., a, 1., quaternion256))
  }
  {
    // two specified
    a := f64(10.)
    b := f64(20.)
    tc.expect(t, quaternion(10., 20., 3., 4.) == initQuaternion(b, 3., 4., a, quaternion256))
    tc.expect(t, quaternion(10., 2., 20., 4.) == initQuaternion(2., b, 4., a, quaternion256))
    tc.expect(t, quaternion(10., 2., 3., 20.) == initQuaternion(2., 3., b, a, quaternion256))
    tc.expect(t, quaternion(1., 10., 20., 4.) == initQuaternion(a, b, 4., 1., quaternion256))
    tc.expect(t, quaternion(1., 10., 3., 20.) == initQuaternion(a, 3., b, 1., quaternion256))
    tc.expect(t, quaternion(1., 2., 10., 20.) == initQuaternion(2., a, b, 1., quaternion256))
  }
  {
    // three specified
    a := f64(10.)
    b := f64(20.)
    c := f64(30.)
    tc.expect(t, quaternion(10., 20., 30., 4.) == initQuaternion(b, c, 4., a, quaternion256))
    tc.expect(t, quaternion(10., 20., 3., 30.) == initQuaternion(b, 3., c, a, quaternion256))
    tc.expect(t, quaternion(10., 2., 20., 30.) == initQuaternion(2., b, c, a, quaternion256))
    tc.expect(t, quaternion(1., 10., 20., 30.) == initQuaternion(a, b, c, 1., quaternion256))
  }
  {
    // four specified
    a := f64(10.)
    b := f64(20.)
    c := f64(30.)
    d := f64(40.)
    tc.expect(t, quaternion(10., 20., 30., 40.) == initQuaternion(b, c, d, a, quaternion256))
  }
}
