meta:
  id: smbios32
  title: SMBIOS32
  application: x86 architecture
  endian: le
  license: Unlicense
doc-ref: https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.1.1.pdf
seq:
  - id: checksum
    type: u1
  - id: length
    type: u1
  - id: major_version
    type: u1
  - id: minor_version
    type: u1
  - id: max_structure_size
    type: u2
  - id: entry_point_revision
    type: u1
    enum: eps_revision
  - id: formatted_area
    size: 5
  - id: ieps
    type: ieps
types:
  smbios_table:
    seq:
      - id: entries
        type: smbios_structure
        repeat: expr
        repeat-expr: ieps.number_of_structures
    types:
      smbios_structure:
        seq:
          - id: type
            type: u1
          - id: len
            type: u1
          - id: handle
            type: u2
          - id: data
            size: len - 4
          - id: strings
            type: strz
            encoding: ASCII
            repeat: until
            repeat-until: _ == ""
  ieps:
    seq:
      - id: signature
        type: str
        size: 5
        encoding: ASCII
        contents: _DMI_
      - id: checksum
        type: u1
      - id: structure_table_length
        type: u2
      - id: structure_table_address
        type: u4
      - id: number_of_structures
        type: u2
      - id: bcd_revision
        type: u1
instances:
  table:
    type: smbios_table
    size: ieps.structure_table_length
enums:
  eps_revision:
    0x00: SMBIOS_21 #Entry Point is based on SMBIOS 2.1 definition; formatted area is reserved and set to all 00h.

