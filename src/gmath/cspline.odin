package gmath

import "core:math"
import "game:util"

calculateCubicSplineIntermediatePoint :: proc(t0, t1, x0, x1, v0, v1, xi: $T, imag_atol: f64 = 1e-14) -> (T, bool) {
  // https://en.wikipedia.org/wiki/Cubic_Hermite_spline
  // p(u) = (2*u^3 - 3t^2 + 1)*p0 + (u^3 - 2*u^2+u)*m0 + (-2*u^3 + 3t^2)*p1 + (u^3 - u^2)*m1
  // where:
  // u=[0,1]
  // endpoints p0,p1
  // derivatives at endpoints m0,m1 (wrt u)
  //
  // However we are given x(t)
  // x(t=t0) = x0
  // x(t=t1) = x1
  // x'(t=t0) = v0
  // x'(t=t1) = v1
  // 
  // Since we want to find intersection time with x(ti)=xi
  // The endpoints will be offset by xi
  // p0 = (x0 - xi)
  // p1 = (x1 - xi)
  //
  // To compute x(t)'s cubic spline coefficents, and change of variables also needs to be done
  // t = u*(t1-t0) + t0
  // dt/du = (t1-t0)
  // 
  // d/du(p(u)) = d/du(x(t=u(t))) = d/dt(x(t))*dt/du(u(t))
  // m0 = v0 * dt/du = v0 * (t1-t0)
  // m1 = v1 * dt/du = v1 * (t1-t0)
  /*
  ```python
  from sympy import symbols
  from sympy.polys.polytools import poly_from_expr
  p0, p1, m0, m1, u = symbols('p0,p1,m0,m1,u')
  pt = (2*u**3 - 3*u**2 + 1)*p0 + (u**3 - 2*u**2+u)*m0 + (-2*u**3 + 3*u**2)*p1 + (u**3 - u**2)*m1
  poly_from_expr(pt, u)[0].coeffs()
  # [
  #   m0 + m1 + 2*p0 - 2*p1,
  #   -2*m0 - m1 - 3*p0 + 3*p1,
  #   m0,
  #   p0,
  # ]
  ```
  */
  // TODO update constants for non-endian floats
  if t0 == t1 {
    return util.initFloat(math.nan_f64(), T), false
  }
  dt := (t1 - t0)
  dtdu := dt
  /////
  // Cubic spline term coefficients
  p0 := (x0 - xi)
  p1 := (x1 - xi)
  m0 := v0 * dtdu
  m1 := v1 * dtdu
  /////
  // Cubic spline polynomial coefficents
  a := m0 + m1 + 2 * p0 - 2 * p1
  b := -2 * m0 - m1 - 3 * p0 + 3 * p1
  c := m0
  d := p0
  /////
  u_roots := solveCubic(a = a, b = b, c = c, d = d)
  /////
  ui := util.initFloat(math.nan_f64(), T)
  ok := false
  for u_root in u_roots {
    ur := real(u_root)
    aui := abs(imag(u_root))
    if 0. <= ur && ur <= 1. && aui <= imag_atol {
      ok = true
      ui = ur
    }
  }
  out := ui * dt + t0
  return out, ok
}
