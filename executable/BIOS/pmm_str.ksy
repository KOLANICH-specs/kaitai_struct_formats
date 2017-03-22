meta:
  id: pmm_str
  title: POST Memory Manager Services structure
  application: x86 architecture
  endian: le
  license: Unlicense
doc-ref: ftp://ftp.software.ibm.com/eserver/pseries/chrptech/1394ohci/bios2.pdf
seq:
  - id: structure_revision
    type: u1
  - id: length_16
    type: u1

  - id: checksum
    type: u1

  - id: entry_point
    type: u4

  - id: reserved
    size: 5
instances:
  length:
    value: length_16 * 16
