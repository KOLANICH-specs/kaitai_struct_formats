meta:
  id: bsdiff
  endian: le
  application:
    - bsdiff
    - bspatch
  license: BSD-2-Clause
seq:
  - id: signature
    contents: ["ENDSLEY/BSDIFF43"]
  - id: header
    type: u8
    repeat: expr
    repeat-expr: 8
    doc: |
      strangely encoded length:
      little endian, but instead of bytes are u8 numbers, only least byte of which is used
      see offtout function, there are lot of numbers this kind used in the format
  - id: data
    process: bzip2
    size-eos: true