meta:
  id: emu10k_log
  title: Floating point repr for EMU10k{1,2} DSP (FX8010 ISA)
  license: GPL-3.0-or-later
  endian: le
  encoding: ascii
  application:
    - as10k1
    - emufxtool

doc: |
  The way it works [?]:
  1. The sign bit is stored
  2. The absolute value is taken of the data
  3. The data is shifted left ( << ) towards the binary point (the MSB).
  4. Exp = Max_Exp_Size - Num_Of_Shifts
  5. If MSB=1 and Exp <= Max_Exp_Size then: the implicit MSB is remove by shifting << one more bit and Exp is incremented.
  6. The Resulting mantissa is Right Shifted by sizeof(Max_Exp_Size)+1
  7. The sign bit and sign operand are compared and proper action is taken according to the table shown above.

  convertee: Data to be converted. It would be interpreted as fractional format.
  resolution: Must be between 1 (0x1) and 31 (0x1F). This parameter controls, in simple words, the
  quantity of scale conversion made by the instruction. A value of 1 means no scale conversion. A value of 31
  means maximum scale conversion (see gaphs 3, 4, 5, 6).

params:
  - id: convertee
    type: u1
  - id: resolution
    type: u1
  - id: sign_register
    type: u1
