meta:
  id: bios32
  title: legacy BIOS
  application: x86 architecture
  endian: le
  license: Unlicense
doc-ref: https://bos.asmhackers.net/docs/pci/docs/bios32.pdf
seq:
  - id: entry_point
    type: u4
  - id: rev
    type: u1
  - id: len
    type: u1
  - id: checksum
    type: u1
  - id: reserved
    size: 5
