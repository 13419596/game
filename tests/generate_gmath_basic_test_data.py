# -*- coding: utf-8 -*-
import numpy as np
from numpy import (
    arccos, arcsin, arctan, cos, sin, tan, arccosh, arcsinh, arctanh, cosh, sinh, tanh, exp, sqrt, array, meshgrid, ndarray,
    log as ln, inf, nan, concatenate, tri, zeros, cbrt as np_cbrt, linspace, real, imag, sign, arctan2, zeros_like, conj, pi, )
from numpy.linalg import norm
import quaternion
from typing import Mapping, Union, Sequence, Dict, List, Callable
from logging import getLogger
import warnings
from pathlib import Path
import csv

############################
log = getLogger(__name__)


def cbrt(x: Union[float, complex, np.quaternion, ndarray]):
    try:
        return np_cbrt(x)
    except TypeError:
        return (x**(1. / 3.))
    ####
####


def arg(x: Union[complex, np.quaternion, ndarray]):
    if isinstance(x, complex):
        return arctan2(imag(x), real(x))
    elif isinstance(x, np.quaternion):
        return arccos(real(x) / abs(x))
    ####
    elif isinstance(x, ndarray):
        if x.dtype == float:
            out = zeros(x.shape)
            out[x < 0] = pi
            return out
        elif x.dtype == complex:
            return arctan2(imag(x), real(x))
        elif x.dtype == np.quaternion:
            xf = quaternion.as_float_array(x)
            norm_xf = norm(xf, axis=-1)
            # np.quaternion are scalar-first
            lgc = norm_xf != 0.
            out = zeros_like(norm_xf)
            out[lgc] = arccos(xf[lgc, 0]/norm_xf[lgc])
            return out
        ####
    ####
    raise TypeError(f'`arg` unsupported for type: {type(x).__name__}')
####


def normalizeData(data: Mapping[str, Sequence[Union[float, complex, ndarray]]]) -> Dict[str, List[float]]:
    out = {}
    for k, vv in data.items():
        if len(vv) == 0:
            out[k] = vv
            continue
        ####
        if isinstance(vv, ndarray):
            vv = list(vv.ravel())
        ####
        if not vv:
            out[k] = []
            continue
        ####
        v0 = vv[0]
        if isinstance(v0, complex):
            out[f'{k}_real'] = [v.real for v in vv]
            out[f'{k}_imag'] = [v.imag for v in vv]
        elif isinstance(v0, np.quaternion):
            out[f'{k}_real'] = [v.w for v in vv]
            out[f'{k}_imag'] = [v.x for v in vv]
            out[f'{k}_jmag'] = [v.y for v in vv]
            out[f'{k}_kmag'] = [v.z for v in vv]
        else:
            out[k] = vv
        ####
    ####
    return out
####


def writeSimpleCsv(filename: Union[str, Path], data: Mapping[str, List[float]]) -> None:
    num_items = 0
    for k, v in data.items():
        num_items = len(v)
    ####
    with open(filename, 'w') as fout:
        wr = csv.DictWriter(fout, data.keys())
        wr.writeheader()
        for i in range(num_items):
            wr.writerow({k: v[i] for k, v in data.items()})
        ####
    ####
####

###################################


def generateRealTestData(out_filepath: Union[str, Path], grid_points: ndarray, unary_funcs: Sequence[Callable]) -> None:
    zz = grid_points.copy()
    data = {'input': zz, }
    for func in unary_funcs:
        name = func.__name__
        if name.startswith('arc'):
            name = f'a{name[3:]}'
        elif name == 'log':
            name = 'ln'
        ####
        with warnings.catch_warnings():
            warnings.filterwarnings('ignore', category=RuntimeWarning)
            data[name] = func(zz)
        ####
    ####
    normed_data = normalizeData(data)
    writeSimpleCsv(out_filepath, normed_data)
####


def generateComplexTestData(out_filepath: Union[str, Path], grid_points: ndarray, unary_funcs: Sequence[Callable]) -> None:
    xx, yy = meshgrid(grid_points, grid_points)
    zz = (xx + 1j * yy).ravel()
    data = {'input': zz, }
    for func in unary_funcs:
        name = func.__name__
        if name.startswith('arc'):
            name = f'a{name[3:]}'
        elif name == 'log':
            name = 'ln'
        elif name == 'conjugate':
            name = 'conj'
        ####
        with warnings.catch_warnings():
            warnings.filterwarnings('ignore', category=RuntimeWarning)
            data[name] = func(zz)
        ####
    ####
    normed_data = normalizeData(data)
    writeSimpleCsv(out_filepath, normed_data)
####


def generateQuatTestData(out_filepath: Union[str, Path], grid_points: ndarray, unary_funcs: Sequence[Callable]) -> None:
    xx, yy, zz, ww = meshgrid(grid_points, grid_points,
                              grid_points, grid_points)
    inputs = array([np.quaternion(1, 0, 0, 0), ] * xx.size)
    for idx, (x, y, z, w) in enumerate(zip(xx.ravel(), yy.ravel(), zz.ravel(), ww.ravel())):
        q = np.quaternion()
        q.x = x
        q.y = y
        q.z = z
        q.w = w
        inputs[idx] = q
    ####
    data = {'input': inputs, }
    for func in unary_funcs:
        name = func.__name__
        if name.startswith('arc'):
            name = f'a{name[3:]}'
        elif name == 'log':
            name = 'ln'
        elif name == 'conjugate':
            name = 'conj'
        ####
        with warnings.catch_warnings():
            warnings.filterwarnings('ignore', category=RuntimeWarning)
            data[name] = func(inputs)
        ####
    ####
    normed_data = normalizeData(data)
    writeSimpleCsv(out_filepath, normed_data)
####

###############################################


def generatePowTestDataReal(out_filepath: Union[str, Path], grid_points: ndarray) -> None:
    base, exponent = meshgrid(grid_points, grid_points)
    base = base.ravel()
    exponent = exponent.ravel()
    data = {'base': base, 'exponent': exponent}
    with warnings.catch_warnings():
        warnings.filterwarnings('ignore', category=RuntimeWarning)
        data['pow'] = base**exponent
    ####
    normed_data = normalizeData(data)
    writeSimpleCsv(out_filepath, normed_data)
####


def generatePowTestDataComplex(out_filepath: Union[str, Path], grid_points: ndarray) -> None:
    base_real, base_imag, exponent_real, exponent_imag = meshgrid(
        *((grid_points,) * 4))
    base_real = base_real.ravel()
    base_imag = base_imag.ravel()
    exponent_real = exponent_real.ravel()
    exponent_imag = exponent_imag.ravel()
    base = zeros(base_real.shape, 'complex')
    exponent = zeros(base_real.shape, 'complex')
    for i in range(len(base_real)):
        # ensure no nan/inf-shenanigans
        base[i] = complex(base_real[i], base_imag[i])
        exponent[i] = complex(exponent_real[i], exponent_imag[i])
    ####
    data = {'base': base, 'exponent': exponent}
    with warnings.catch_warnings():
        warnings.filterwarnings('ignore', category=RuntimeWarning)
        data['pow'] = base**exponent
    ####
    normed_data = normalizeData(data)
    writeSimpleCsv(out_filepath, normed_data)
####


def generatePowTestDataQuaternion(out_filepath: Union[str, Path], grid_points: ndarray) -> None:
    base_r, base_i, base_j, base_k, exp_r, exp_i, exp_j, exp_k = meshgrid(
        *((grid_points,) * 8))
    base_r = base_r.ravel()
    base_i = base_i.ravel()
    base_j = base_j.ravel()
    base_k = base_k.ravel()
    exp_r = exp_r.ravel()
    exp_i = exp_i.ravel()
    exp_j = exp_j.ravel()
    exp_k = exp_k.ravel()
    base = zeros(base_r.shape) + np.quaternion()
    exponent = zeros(base_r.shape) + np.quaternion()
    for i in range(len(base_r)):
        base[i] = np.quaternion(base_r[i], base_i[i], base_j[i], base_k[i])
        exponent[i] = np.quaternion(exp_r[i], exp_i[i], exp_j[i], exp_k[i])
    ####
    data = {'base': base, 'exponent': exponent}
    with warnings.catch_warnings():
        warnings.filterwarnings('ignore', category=RuntimeWarning)
        data['pow'] = base**exponent
    ####
    normed_data = normalizeData(data)
    writeSimpleCsv(out_filepath, normed_data)
####
#

###############################################


def generateTestData(out_prefix: str) -> None:
    grid = array([-2., -1., -.25, 0., +.25, +1, +2, ])
    funcs = [abs, exp, ln, sqrt, cbrt, arg, conj, ]
    trig_funcs = [arccos, arcsin, arctan, cos, sin, tan, arccosh,
                  arcsinh, arctanh, cosh, sinh, tanh, ]

    generateRealTestData(
        out_filepath=str(out_prefix) + 'basic_real.csv',
        grid_points=grid,
        unary_funcs=funcs + trig_funcs,
    )

    generateComplexTestData(
        out_filepath=str(out_prefix) + 'basic_complex.csv',
        grid_points=grid,
        unary_funcs=funcs + trig_funcs,
    )

    generateQuatTestData(
        out_filepath=str(out_prefix) + 'basic_quaternion.csv',
        grid_points=grid,
        unary_funcs=funcs,
    )

    grid = array([-2., -1., 0., +1., +2.])
    pow_grid = concatenate([grid, [-inf, inf, nan]])
    generatePowTestDataReal(
        out_filepath=str(out_prefix) + 'pow_real.csv',
        grid_points=pow_grid,
    )

    generatePowTestDataComplex(
        out_filepath=str(out_prefix) + 'pow_complex.csv',
        grid_points=pow_grid,
    )

    grid = array([-1., 0., +2.])
    pow_grid = concatenate([grid, [inf, nan]])
    generatePowTestDataQuaternion(
        out_filepath=str(out_prefix) + 'pow_quaternion.csv',
        grid_points=pow_grid,
    )
####


if __name__ == "__main__":
    generateTestData('tests_')
####
