meta:
  id: pci_expansion_rom_header
  application: x86 architecture
  endian: le
  license: Unlicense
  imports:
    - ./bios_header_generic
    - /executable/BIOS/pci_data_struct
    - /executable/BIOS/legacy_option_rom_header
doc-ref:
  - Plug and Play BIOS Specification Version 1.0A May 5, 1994, 3.1 Option ROM Header
  - 'BIOS Boot Specification Version 1.01 January 11, 1996, Appendix A: Data Structures, A.2 PnP Option ROM Header'
  - https://github.com/KevinOConnor/seabios/blob/master/docs/Developer_links.md
  - http://download.intel.com/support/motherboards/desktop/sb/pnpbiosspecificationv10a.pdf
  - http://www.osdever.net/documents/PNPBIOSSpecification-v1.0a.pdf
  - https://web.archive.org/web/20160424101328if_/http://mirrors.josefsipek.net/www.nondot.org/sabre/os/files/PlugNPlay/PNPBIOSSpecification-v1.0a.pdf
  # MD5: e393bdce982b4ec62ab3acbc3617a6a4
  # SHA1: eebc2dab26e1939900fcfc28da9c60e9176a11a8
  # SHA256: 95a99a7c9d82a7df2595f9181720e798db5dc6ec85ee232ba8370f30bfda8643
  # SHA512: a1583c52e926974874d601c7a717c986ad81c351b86e1047be8b82529f107aed42458b7249d957effa752f14ffae9088136b05fde5855caa6995b52707137a16
  - http://www.scs.stanford.edu/05au-cs240c/lab/specsbbs101.pdf
seq:
  - id: signature
    contents: [0x55, 0xAA]
  - id: impl_defined
    type: legacy_option_rom_header
  - id: data_struct_ptr
    type: pci_data_struct_ptr
  - id: exp_hdr_ptr
    type: header_ptr
