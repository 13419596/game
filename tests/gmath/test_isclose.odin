// subpackage for running `gmath` tests
package test_gmath

import "core:fmt"
import "core:testing"
import "core:math"
import rand "core:math/rand"
import tc "tests:common"
import gm "game:gmath"

@(private = "file")
num_monte :: 30

@(test)
runTests_isclose :: proc(t: ^testing.T) {
  test_isclose(t)
  test_isclose_complex(t)
  test_isclose_quaternion(t)
  test_allclose_scalar(t)
  test_allclose_array(t)
}

@(test)
test_isclose :: proc(t: ^testing.T) {
  using gm
  {
    for n in -1000 ..= 1000 {
      tc.expect(t, isclose(f16(n), f16(n)))
      tc.expect(t, isclose(f16le(n), f16le(n)))
      tc.expect(t, isclose(f16be(n), f16be(n)))
      tc.expect(t, isclose(f32(n), f32(n)))
      tc.expect(t, isclose(f32le(n), f32le(n)))
      tc.expect(t, isclose(f32be(n), f32be(n)))
      tc.expect(t, isclose(f64(n), f64(n)))
      tc.expect(t, isclose(f64le(n), f64le(n)))
      tc.expect(t, isclose(f64be(n), f64be(n)))
    }
  }
  {
    for monte in 0 ..< num_monte {
      value := rand.float64() * 100 + 10.
      if rand.float32() < .5 {
        value *= -1
      }
      noise := rand.float64_normal(mean = 0, stddev = 1e-15)
      value2 := value + noise
      tc.expect(t, isclose(value, value))
    }
  }
  {
    // atol tests
    tc.expect(t, isclose(lhs = 1., rhs = 2., rtol = 0, atol = 1))
    tc.expect(t, !isclose(lhs = 1., rhs = 2., rtol = 0, atol = .999))
    tc.expect(t, isclose(lhs = 1., rhs = 2., rtol = 0, atol = 2))
    // swap order
    tc.expect(t, isclose(lhs = 2., rhs = 1., rtol = 0, atol = 1))
    tc.expect(t, !isclose(lhs = 2., rhs = 1., rtol = 0, atol = .999))
    tc.expect(t, isclose(lhs = 1., rhs = 1., rtol = 0, atol = 2))
  }
  {
    // rtol tests
    tc.expect(t, isclose(lhs = 1., rhs = 2., rtol = 1., atol = 0.))
    tc.expect(t, isclose(lhs = 1., rhs = 2., rtol = .99, atol = 0.))
    tc.expect(t, isclose(lhs = 1., rhs = 2., rtol = 1., atol = 0.))
    // swap order
    tc.expect(t, isclose(lhs = 2., rhs = 1., rtol = 1., atol = 0.))
    tc.expect(t, !isclose(lhs = 2., rhs = 1., rtol = .99, atol = 0.))
    tc.expect(t, isclose(lhs = 1., rhs = 1., rtol = 1., atol = 0.))
  }
  {
    // equal nan tests
    nan := math.nan_f64()
    tc.expect(t, isclose(lhs = nan, rhs = nan, equal_nan = true))
    tc.expect(t, !isclose(lhs = 0., rhs = nan, equal_nan = true))
    tc.expect(t, !isclose(lhs = nan, rhs = 0., equal_nan = true))
    tc.expect(t, !isclose(lhs = nan, rhs = nan, equal_nan = false))
    tc.expect(t, !isclose(lhs = 0., rhs = nan, equal_nan = false))
    tc.expect(t, !isclose(lhs = nan, rhs = 0., equal_nan = false))
  }
}

@(test)
test_allclose_scalar :: proc(t: ^testing.T) {
  using gm
  {
    for n in -1000 ..= 1000 {
      tc.expect(t, allclose(f16(n), f16(n)))
      tc.expect(t, allclose(f16le(n), f16le(n)))
      tc.expect(t, allclose(f16be(n), f16be(n)))
      tc.expect(t, allclose(f32(n), f32(n)))
      tc.expect(t, allclose(f32le(n), f32le(n)))
      tc.expect(t, allclose(f32be(n), f32be(n)))
      tc.expect(t, allclose(f64(n), f64(n)))
      tc.expect(t, allclose(f64le(n), f64le(n)))
      tc.expect(t, allclose(f64be(n), f64be(n)))
    }
  }
  {
    for monte in 0 ..< num_monte {
      value := rand.float64() * 100 + 10.
      if rand.float32() < .5 {
        value *= -1
      }
      noise := rand.float64_normal(mean = 0, stddev = 1e-15)
      value2 := value + noise
      tc.expect(t, allclose(value, value))
    }
  }
  {
    // atol tests
    tc.expect(t, allclose(lhs = 1., rhs = 2., rtol = 0, atol = 1))
    tc.expect(t, !allclose(lhs = 1., rhs = 2., rtol = 0, atol = .999))
    tc.expect(t, allclose(lhs = 1., rhs = 2., rtol = 0, atol = 2))
    // swap order
    tc.expect(t, allclose(lhs = 2., rhs = 1., rtol = 0, atol = 1))
    tc.expect(t, !allclose(lhs = 2., rhs = 1., rtol = 0, atol = .999))
    tc.expect(t, allclose(lhs = 1., rhs = 1., rtol = 0, atol = 2))
  }
  {
    // rtol tests
    tc.expect(t, allclose(lhs = 1., rhs = 2., rtol = 1., atol = 0.))
    tc.expect(t, allclose(lhs = 1., rhs = 2., rtol = .99, atol = 0.))
    tc.expect(t, allclose(lhs = 1., rhs = 2., rtol = 1., atol = 0.))
    // swap order
    tc.expect(t, allclose(lhs = 2., rhs = 1., rtol = 1., atol = 0.))
    tc.expect(t, !allclose(lhs = 2., rhs = 1., rtol = .99, atol = 0.)) // ! on purpose because rtol is scaled by rhs only
    tc.expect(t, allclose(lhs = 1., rhs = 1., rtol = 1., atol = 0.))
  }
  {
    // equal nan tests
    nan := math.nan_f64()
    tc.expect(t, allclose(lhs = nan, rhs = nan, equal_nan = true))
    tc.expect(t, !allclose(lhs = 0., rhs = nan, equal_nan = true))
    tc.expect(t, !allclose(lhs = nan, rhs = 0., equal_nan = true))
    tc.expect(t, !allclose(lhs = nan, rhs = nan, equal_nan = false))
    tc.expect(t, !allclose(lhs = 0., rhs = nan, equal_nan = false))
    tc.expect(t, !allclose(lhs = nan, rhs = 0., equal_nan = false))
  }
}

@(test)
test_allclose_array :: proc(t: ^testing.T) {
  using gm
  {
    for n in -1000 ..= 1000 {
      {
        N :: 1
        {
          values := [N]f16{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
        {
          values := [N]f16le{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
        {
          values := [N]f16be{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
        {
          values := [N]f32{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
        {
          values := [N]f32le{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
        {
          values := [N]f32be{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
        {
          values := [N]f64{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
        {
          values := [N]f64le{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
        {
          values := [N]f64be{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
      }
      {
        N :: 2
        {
          values := [N]f16{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
        {
          values := [N]f16le{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
        {
          values := [N]f16be{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
        {
          values := [N]f32{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
        {
          values := [N]f32le{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
        {
          values := [N]f32be{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
        {
          values := [N]f64{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
        {
          values := [N]f64le{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
        {
          values := [N]f64be{}
          for _, i in values {
            values[i] = type_of(values[i])(n)
          }
          tc.expect(t, allclose(values[:], values[:]))
        }
      }
    }
  }
  {
    for monte in 0 ..< num_monte {
      {
        N :: 1
        values1 := [N]f64{}
        values2 := [N]f64{}
        for _, i in values1 {
          value := rand.float64() * 100 + 1000.
          if rand.float32() < .5 {
            value *= -1
          }
          values1[i] = value
          noise := clamp(rand.float64_normal(mean = 0, stddev = 1e-18), -1e-12, 1e-12)
          values2[i] = value + noise
        }
        tc.expect(t, allclose(values1[:], values1[:]))
        tc.expect(t, allclose(values2[:], values2[:]))
        tc.expect(t, allclose(values1[:], values2[:]))
        tc.expect(t, allclose(values2[:], values2[:]))
      }
    }
  }
  {
    // atol tests
    {
      lhs := [?]f64{1., 1.}
      rhs := [?]f64{2., 2.}
      tc.expect(t, allclose(lhs[:], rhs[:], 0., 1.))
      tc.expect(t, allclose(rhs[:], lhs[:], 0., 1.))
    }
    {
      lhs := [?]f64{1., 1.}
      rhs := [?]f64{2., 2.}
      tc.expect(t, !allclose(lhs[:], rhs[:], 0., .999))
      tc.expect(t, !allclose(rhs[:], lhs[:], 0., .999))
    }
    {
      lhs := [?]f64{1., 1.}
      rhs := [?]f64{2., 2.}
      tc.expect(t, allclose(lhs[:], rhs[:], 0., 2.))
      tc.expect(t, allclose(rhs[:], lhs[:], 0., 2.))
    }
  }
  {
    // rtol tests
    {
      lhs := [?]f64{1., 1.}
      rhs := [?]f64{2., 2.}
      tc.expect(t, allclose(lhs[:], rhs[:], 1., 0.))
      tc.expect(t, allclose(rhs[:], lhs[:], 1., 0.))
    }
    {
      lhs := [?]f64{1., 1.}
      rhs := [?]f64{2., 2.}
      tc.expect(t, allclose(lhs[:], rhs[:], .99, 0.), "larger rhs makes rtol larger")
      tc.expect(t, !allclose(rhs[:], lhs[:], .99, 0.), "rtol is big, but scaled by rhs, so should not be close") // ! on purpose because rtol is scaled by rhs only
    }
    {
      lhs := [?]f64{1., 1.}
      rhs := [?]f64{1.01, 1.01}
      tc.expect(t, allclose(lhs[:], rhs[:], .1, 0.), "rtol should be big enough that values are close")
      tc.expect(t, allclose(rhs[:], lhs[:], .1, 0.), "rtol should be big enough that values are close")
    }
  }
  {
    // equal nan tests
    {
      nan := math.nan_f64()
      lhs := [?]f64{100., nan}
      rhs := [?]f64{100., nan}
      tc.expect(t, allclose(lhs = lhs[:], rhs = rhs[:], equal_nan = true))
      tc.expect(t, allclose(lhs = rhs[:], rhs = lhs[:], equal_nan = true))
      tc.expect(t, !allclose(lhs = lhs[:], rhs = rhs[:], equal_nan = false))
      tc.expect(t, !allclose(lhs = rhs[:], rhs = lhs[:], equal_nan = false))
    }
    {
      nan := math.nan_f64()
      lhs := [?]f64{100., 100.}
      rhs := [?]f64{100., nan}
      tc.expect(t, !allclose(lhs = lhs[:], rhs = rhs[:], equal_nan = true))
      tc.expect(t, !allclose(lhs = rhs[:], rhs = lhs[:], equal_nan = true))
      tc.expect(t, !allclose(lhs = lhs[:], rhs = rhs[:], equal_nan = false))
      tc.expect(t, !allclose(lhs = rhs[:], rhs = lhs[:], equal_nan = false))
    }
  }
}


@(test)
test_isclose_complex :: proc(t: ^testing.T) {
  using gm
  {
    // regular test
    tc.expect(t, isclose(1 + 1i, 1 + 1.00001i))
    tc.expect(t, !isclose(1 + 100.i, 1 + 1.00001i))
    tc.expect(t, !isclose(1 + 0.i, 1i))
    tc.expect(t, !isclose(1i, 1. + 0i))
  }
  {
    // equal nan test
    nan := math.nan_f64()
    tc.expect(t, isclose(lhs = complex(nan, nan), rhs = complex(nan, nan), equal_nan = true))
    tc.expect(t, isclose(lhs = complex(nan, 0), rhs = complex(0, nan), equal_nan = true))
    tc.expect(t, !isclose(lhs = complex(1, 1), rhs = complex(1, nan), equal_nan = true))
    tc.expect(t, !isclose(lhs = complex(1, 1), rhs = complex(nan, 1), equal_nan = true))
    tc.expect(t, !isclose(lhs = complex(1, 1), rhs = complex(nan, nan), equal_nan = true))
  }
}

@(test)
test_isclose_quaternion :: proc(t: ^testing.T) {
  using gm
  {
    tc.expect(t, isclose(1 + 1i + 0j, 1 + 1.00001i + 0j))
    tc.expect(t, isclose(1 + 1j + 0j, 1 + 1.00001j + 0j))
    tc.expect(t, isclose(1 + 1k + 0j, 1 + 1.00001k + 0j))
    tc.expect(t, !isclose(1 + 100.i + 0j, 1 + 1.00001i + 0j))
    tc.expect(t, !isclose(1 + 100.j + 0j, 1 + 1.00001j + 0j))
    tc.expect(t, !isclose(1 + 100.k + 0j, 1 + 1.00001k + 0j))
    tc.expect(t, !isclose(1 + 1i + 0j, 1 + 1j + 0j))
    tc.expect(t, !isclose(1 + 1i + 0j, 1 + 1k + 0j))
    tc.expect(t, !isclose(1 + 1j + 0j, 1 + 1k + 0j))
  }
  {
    // equal nan test
    nan := math.nan_f64()
    tc.expect(t, isclose(lhs = quaternion(nan, nan, nan, nan), rhs = quaternion(nan, nan, nan, nan), equal_nan = true))
    tc.expect(t, isclose(lhs = quaternion(nan, 0, 0, 0), rhs = quaternion(0, nan, 0, 0), equal_nan = true))
    tc.expect(t, !isclose(lhs = quaternion(1, 1, 1, 1), rhs = quaternion(nan, 1., 1., 1.), equal_nan = true))
    tc.expect(t, !isclose(lhs = quaternion(1, 1, 1, 1), rhs = quaternion(1., nan, 1., 1.), equal_nan = true))
    q1111 := quaternion(1., 1., 1., 1.)
    q3 := quaternion(1., 1., 1., 1.) + 1j * quaternion(nan, 0., 0., 0.)
    q4 := quaternion(1., 1., 1., 1.) + 1k * quaternion(nan, 0., 0., 0.)
    tc.expect(t, !isclose(lhs = q1111, rhs = q3, equal_nan = true))
    tc.expect(t, !isclose(lhs = q1111, rhs = q4, equal_nan = true))
  }
}

///////////////////////////////////////////////////
//
initializeMatrixSequential :: proc(mat: ^matrix[$M, $N]$T) {
  index := T(0)
  for m in 0 ..< M {
    for n in 0 ..< N {
      mat[m, n] = index
      index += 1
    }
  }
}

@(test)
test_allclose_matrix :: proc(t: ^testing.T) {
  using gm
  {
    {
      M :: 1
      N :: 1
      {
        values := matrix[M, N]f16{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
      {
        values := matrix[M, N]f16le{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
      {
        values := matrix[M, N]f16be{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
      {
        values := matrix[M, N]f32{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
      {
        values := matrix[M, N]f32le{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
      {
        values := matrix[M, N]f32be{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
      {
        values := matrix[M, N]f64{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
      {
        values := matrix[M, N]f64le{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
      {
        values := matrix[M, N]f64be{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
    }
    {
      M :: 2
      N :: 2
      {
        values := matrix[M, N]f16{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
      {
        values := matrix[M, N]f16le{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
      {
        values := matrix[M, N]f16be{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
      {
        values := matrix[M, N]f32{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
      {
        values := matrix[M, N]f32le{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
      {
        values := matrix[M, N]f32be{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
      {
        values := matrix[M, N]f64{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
      {
        values := matrix[M, N]f64le{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
      {
        values := matrix[M, N]f64be{}
        initializeMatrixSequential(&values)
        tc.expect(t, allclose(&values, &values))
      }
    }
  }
  {
    for monte in 0 ..< num_monte {
      {
        M :: 2
        N :: 2
        values1 := matrix[M, N]f64{}
        values2 := matrix[M, N]f64{}
        for m in 0 ..< M {
          for n in 0 ..< N {
            value := rand.float64() * 100 + 1000.
            if rand.float32() < .5 {
              value *= -1
            }
            values1[m, n] = value
            noise := clamp(rand.float64_normal(mean = 0, stddev = 1e-18), -1e-12, 1e-12)
            values2[m, n] = value + noise
          }
        }
        tc.expect(t, allclose(&values1, &values1))
        tc.expect(t, allclose(&values2, &values2))
        tc.expect(t, allclose(&values1, &values2))
        tc.expect(t, allclose(&values2, &values2))
      }
    }
  }
  {
    // atol tests
    {
      lhs := matrix[2, 1]f64 {
        1., 
        1., 
      }
      rhs := matrix[2, 1]f64 {
        2., 
        2., 
      }
      tc.expect(t, allclose(&lhs, &rhs, 0., 1.))
      tc.expect(t, allclose(&rhs, &lhs, 0., 1.))
    }
    {
      lhs := matrix[2, 1]f64 {
        1., 
        1., 
      }
      rhs := matrix[2, 1]f64 {
        2., 
        2., 
      }
      tc.expect(t, !allclose(&lhs, &rhs, 0., .999))
      tc.expect(t, !allclose(&rhs, &lhs, 0., .999))
    }
    {
      lhs := matrix[2, 1]f64 {
        1., 
        1., 
      }
      rhs := matrix[2, 1]f64 {
        2., 
        2., 
      }
      tc.expect(t, allclose(&lhs, &rhs, 0., 2.))
      tc.expect(t, allclose(&rhs, &lhs, 0., 2.))
    }
  }
  {
    // rtol tests
    {
      lhs := matrix[2, 1]f64 {
        1., 
        1., 
      }
      rhs := matrix[2, 1]f64 {
        2., 
        2., 
      }
      tc.expect(t, allclose(&lhs, &rhs, 1., 0.))
      tc.expect(t, allclose(&rhs, &lhs, 1., 0.))
    }
    {
      lhs := matrix[2, 1]f64 {
        1., 
        1., 
      }
      rhs := matrix[2, 1]f64 {
        2., 
        2., 
      }
      tc.expect(t, allclose(&lhs, &rhs, .99, 0.), "larger rhs makes rtol larger")
      tc.expect(t, !allclose(&rhs, &lhs, .99, 0.), "rtol is big, but scaled by rhs, so should not be close") // ! on purpose because rtol is scaled by rhs only
    }
    {
      lhs := matrix[2, 1]f64 {
        1., 
        1., 
      }
      rhs := matrix[2, 1]f64 {
        1.01, 
        1.01, 
      }
      tc.expect(t, allclose(&lhs, &rhs, .1, 0.), "rtol should be big enough that values are close")
      tc.expect(t, allclose(&rhs, &lhs, .1, 0.), "rtol should be big enough that values are close")
    }
  }
  {
    // equal nan tests
    nan := math.nan_f64()
    {
      lhs := matrix[2, 1]f64 {
        100., 
        nan, 
      }
      rhs := matrix[2, 1]f64 {
        100., 
        nan, 
      }
      tc.expect(t, allclose(lhs = &lhs, rhs = &rhs, equal_nan = true))
      tc.expect(t, allclose(lhs = &rhs, rhs = &lhs, equal_nan = true))
      tc.expect(t, !allclose(lhs = &lhs, rhs = &rhs, equal_nan = false))
      tc.expect(t, !allclose(lhs = &rhs, rhs = &lhs, equal_nan = false))
    }
    {
      lhs := matrix[2, 1]f64 {
        100., 
        100., 
      }
      rhs := matrix[2, 1]f64 {
        100., 
        nan, 
      }
      tc.expect(t, !allclose(lhs = &lhs, rhs = &rhs, equal_nan = true))
      tc.expect(t, !allclose(lhs = &rhs, rhs = &lhs, equal_nan = true))
      tc.expect(t, !allclose(lhs = &lhs, rhs = &rhs, equal_nan = false))
      tc.expect(t, !allclose(lhs = &rhs, rhs = &lhs, equal_nan = false))
    }
  }
}
