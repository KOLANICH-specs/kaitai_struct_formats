meta:
  id: legacy_option_rom_header
  title: Legacy Option ROM header
  application: x86 architecture
  endian: le
  license: Unlicense
doc-ref:
  - Plug and Play BIOS Specification Version 1.0A May 5, 1994, 3.1 Option ROM Header
  - 'BIOS Boot Specification Version 1.01 January 11, 1996, Appendix A: Data Structures, A.2 PnP Option ROM Header'
  - http://download.intel.com/support/motherboards/desktop/sb/pnpbiosspecificationv10a.pdf
  - http://www.scs.stanford.edu/05au-cs240c/lab/specsbbs101.pdf
seq:
  - id: optrom_len
    type: u1
  - id: init_vec
    type: u4
  - id: reserved
    size: 17
