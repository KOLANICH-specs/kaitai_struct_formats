meta:
  id: ndarray
  title: An abstraction for multidimensional arrays.
  application:
    - numpy
    - safetensors
  license: Unlicense
  endian: le
  encoding: utf-8
  imports:
    - /common/ieee754_float/f1
    - /common/ieee754_float/f2be
    - /common/ieee754_float/f2le
    - /common/ieee754_float/f10be
    - /common/ieee754_float/f10le
    - /common/ieee754_float/f12le
    - /common/ieee754_float/f12be
    - /common/ieee754_float/f16be
    - /common/ieee754_float/f16le
    - /common/ieee754_float/f32be
    - /common/ieee754_float/f32le
    - /common/ndarray_descriptor
  -affected-by: 703
  ks-opaque-types: true

doc: |
  This is a part of an abstraction layer for multidimensional arrays and tensors, as used in, for example, `numpy`.
  Configure it with an `ndarray_descriptor`, and parse with it a buffer.

params:
  - id: descriptor
    type: ndarray_descriptor
seq:
  - id: data_initial
    type: ndarray_internal(-1)

instances:
  dims_m_2:
    value: _root.descriptor.shape.size.as<u8> - 2

  data:
    value: data_initial.data[0].as<ndarray_internal>.data

types:
  array:
    params:
      - id: idx
        type: u8
    seq:
      - id: data
        -affected-by: 703
        type:
          switch-on: _root.descriptor.item_type
          cases:
            ndarray_descriptor::item_type::u1: u1
            ndarray_descriptor::item_type::s1: s1
            ndarray_descriptor::item_type::f1: f1
            ndarray_descriptor::item_type::sc1: s1 # char

            ndarray_descriptor::item_type::u2le: u2le
            ndarray_descriptor::item_type::u4le: u4le
            ndarray_descriptor::item_type::u8le: u8le
            ndarray_descriptor::item_type::s2le: s2le
            ndarray_descriptor::item_type::s4le: s4le
            ndarray_descriptor::item_type::s8le: s8le
            ndarray_descriptor::item_type::f2le: f2le
            ndarray_descriptor::item_type::f4le: f4le
            ndarray_descriptor::item_type::f8le: f8le
            ndarray_descriptor::item_type::f10le: f10le
            ndarray_descriptor::item_type::f12le: f12le
            ndarray_descriptor::item_type::f16le: f16le
            ndarray_descriptor::item_type::f32le: f32le

            ndarray_descriptor::item_type::u2be: u2be
            ndarray_descriptor::item_type::u4be: u4be
            ndarray_descriptor::item_type::u8be: u8be
            ndarray_descriptor::item_type::s2be: s2be
            ndarray_descriptor::item_type::s4be: s4be
            ndarray_descriptor::item_type::s8be: s8be
            ndarray_descriptor::item_type::f2be: f2be
            ndarray_descriptor::item_type::f4be: f4be
            ndarray_descriptor::item_type::f8be: f8be
            ndarray_descriptor::item_type::f10be: f10be
            ndarray_descriptor::item_type::f12be: f12be
            ndarray_descriptor::item_type::f16be: f16be
            ndarray_descriptor::item_type::f32be: f32be

            # Machine endianness, assumming le, since it is the most sensible endiannes and the most common today
            # Is not generated by numpy, but is parsed well from tampered numpy files.
            ndarray_descriptor::item_type::u2me: u2le
            ndarray_descriptor::item_type::u4me: u4le
            ndarray_descriptor::item_type::u8me: u8le
            ndarray_descriptor::item_type::s2me: s2le
            ndarray_descriptor::item_type::s4me: s4le
            ndarray_descriptor::item_type::s8me: s8le
            ndarray_descriptor::item_type::f2me: f2le
            ndarray_descriptor::item_type::f4me: f4le
            ndarray_descriptor::item_type::f8me: f8le
            ndarray_descriptor::item_type::f10me: f10le
            ndarray_descriptor::item_type::f12me: f12le
            ndarray_descriptor::item_type::f16me: f16le
            ndarray_descriptor::item_type::f32me: f32le

        repeat: expr
        repeat-expr: _root.descriptor.shape[idx].as<u8>
  ndarray_internal:
    params:
      - id: idx
        type: u8
    seq:
      - id: data
        type:
          switch-on: idx == _root.dims_m_2
          cases:
            false: ndarray_internal(idx+1)
            true: array(idx)
        repeat: expr
        repeat-expr: 'idx >= 0 ? _root.descriptor.shape[idx].as<u8> : 1'
