meta:
  id: emu10k_instr
  title: An instruction for EMU10k{1,2} DSP (FX8010 ISA)
  license: GPL-3.0-or-later # Maybe Unlicense, if all the shit is stripped.
  endian: le
  encoding: ascii
  application:
    - as10k1
    - emufxtool
    - fxasm # Something related to Microsoft Developer Studion around year 1998
    - Dane # KX Project
    - E-mu Audio Production Studio
doc: |
  EMU10k1 and EMU10k2 are DSPs used in Creative Technology sound cards.
  ToDo: kx-audio-driver/kxapi/dane.cpp disassemble_microcode

  def saturate(n: float) -> float:
    return max(min(n, 1.), -1.)

  def wraparound(n: float) -> float:
    if n > 1.:
      return -1. + (n - 1.)
    elif n < -1.:
      return 1 + (n + 1.)
    else:
      return n

doc-ref:
  - https://github.com/alsa-project/alsa-tools/tree/master/as10k1
  - https://github.com/itadinanta/emufxtool
  - https://github.com/kxproject/kx-audio-driver
  - https://github.com/kxproject/kX-Audio-driver-Documentation

params:
  - id: bitness
    type: u1

seq:
  - id: wo
    -orig-id:
      - [w0, w1]
      - [d1, d2]
    type: subunit(bitness)
    repeat: expr
    repeat-expr: 2

instances:
  unkn:
    value: wo[0].a
  x:
    value: wo[0].b
  y:
    value: wo[0].c

  opcode:
    value: wo[1].a
    enum: opcode

  z:
    value: wo[1].b
  w:
    value: wo[1].c

  opcode_valid:
    value: opcode.to_i < 16

types:
  subunit:
    params:
      - id: bits
        type: u1
    seq:
      - id: w
        type: u4
    instances:
      mask:
        value: (1 << bits) - 1
      a:
        value: w >> (bits * 2)
      b:
        value: (w >> bits) & mask
      c:
        value: w & mask

enums:
  log_exp_sign_reg:
    # determines sign of the result
    0: normal
    1: abs
    2: neg_abs
    3: neg

  opcode:
    0x0:
      id: log_multiply_add_saturation
      -orig-id: MACS
      doc: "saturate(A + (X * Y >> 31))"
      -operand-type: log
    0x1:
      id: log_multiply_subtract_saturation
      -orig-id: MACS1
      doc: "saturate(A + (-X * Y >> 31))"
      -operand-type: log
    0x2:
      id: log_multiply_add_wraparound
      -orig-id: MACW
      doc: "wraparound(A + (X * Y >> 31))"
      -operand-type: log
    0x3:
      id: log_multiply_subtract_wraparound
      -orig-id: MACW1
      doc: "wraparound(A + (-X * Y >> 31))"
      -operand-type: log
    0x4:
      id: multiply_add_saturation
      -orig-id: MACINTS
      doc: "int_saturate(A + X * Y)"
      -operand-type: ["int | log", "int | log", "int | log", "int"]
    0x5:
      id: int_multiply_add_wraparound
      -orig-id: MACINTW
      doc: "int_wraparound(A + X * Y, 31 bit)"
      -operand-type: int
    0x6:
      id: acc3
      -orig-id: ACC3
      doc: "saturate(A + X + Y)"
      -operand-type: int | log
    0x7:
      id: multiply_accumulate_add_move
      -orig-id: MACMV
      doc: |
        R = A
        acc_{i} = acc_{i-1} + X * Y >> 31
        Useful for filters.
    0x8:
      id: and_xor
      -orig-id: ANDXOR
      doc: "(A & X) ^ Y"
    0x9:
      id: geq_neg
      -orig-id: TSTNEG
      doc: "(A >= Y) ? X : ~X"
    0xa:
      id: geq_select_y
      -orig-id: LIMIT
      doc: "(A >= Y) ? X : Y"
    0xb:
      id: lt_select_y
      -orig-id: LIMIT1
      doc: "(A < Y) ? X : Y"
    0xc:
      id: to_log
      -orig-id: LOG
      doc: Convert to logarithmic representation. See emu10k_log.ksy
      -operand-type: int
      -args: [result, convertee, resolution, sign_register]

    0xd:
      id: from_log
      -orig-id: EXP
      doc: Converts from logarithmic representation
      -operand-type: [log, int, int, int]

    0xe:
      id: interpolate
      -orig-id: INTERP
      doc: "saturate(A + (X * (Y - A) >> 31))"
      -operand-type: int

    0xf:
      id: skip
      -orig-id: SKIP
      -args: [ccr_backup, current_ccr_address, condition, count_of_instr]
      doc: Skips instructions based on condition
