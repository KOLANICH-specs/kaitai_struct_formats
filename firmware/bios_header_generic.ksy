meta:
  id: header_generic
  title: Expansion header
  application: x86 architecture
  endian: le
  license: Unlicense
  imports:
    - ./pirt
    - ./smbios32
    - /executable/BIOS/pnp_hdr
    - /executable/BIOS/pmm_str
    - /executable/BIOS/bios32
doc: Selects the right header body type based on signature
doc-ref: https://github.com/KevinOConnor/seabios/blob/master/docs/Developer_links.md
seq:
  - id: signature
    type: str
    encoding: ASCII
    size: 4
  - id: data
    type:
      switch-on: signature
      cases:
        '"$PnP"': pnp_hdr
        '"$PMM"': pmm_str
        '"_32_"': bios32
        '"$PIR"': pirt
        '"_SM_"': smbios32
types:
  header_ptr:
    seq:
      - id: next_header
        type: u2
    instances:
      next_hdr:
        pos: next_header
        type: header_generic
        if: next_header != 0
