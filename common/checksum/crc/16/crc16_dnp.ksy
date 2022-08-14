meta:
  id: crc16_dnp
  title: DNP variant of CRC-16
  license: Unlicense
  imports:
    - ../crc_generic
  -initial: 0x0
  -check: 0xea82
  -polynomial: 0x3d65
  -reflect_in: true
  -reflect_out: true
doc: Computes DNP variant of 16 of an array.

params:
  - id: array
    type: bytes

instances:
  value:
    value: generic.value

seq:
  - id: generic
    type: crc_generic(16, 0, 0xffff, true, true, 0x3d65, array)
