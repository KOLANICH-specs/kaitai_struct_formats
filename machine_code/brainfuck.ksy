meta:
  id: brainfuck
  endian: le
  license: Unlicense
  encoding: ascii
doc: |
  This is a try to create a brainfuck interpreter as a ksy.
seq:
  - id: data
    type: u1
    size: 10
  - id: code
    type: op
    repeat: eos
types:
  op:
    seq:
      - id: op
        type: str
        size: 1
