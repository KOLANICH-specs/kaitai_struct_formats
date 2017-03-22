meta:
  id: pci_data_structure
  title: PCIR data structure
  application: x86 architecture
  endian: le
  license: Unlicense
  imports:
    - ./device_class_code
doc-ref:
  - BIOS Boot Specification Version 1.01 January 11, 1996, Appendix A: Data Structures, A.4 PCI Data Structure
  - http://www.scs.stanford.edu/05au-cs240c/lab/specsbbs101.pdf
seq:
  - id: signature
    contents: "PCIR"
  - id: vid
    type: u2
  - id: pid
    type: u2
  - id: vital_product_data_ptr
    type: u2
  - id: len
    type: u2
  - id: rev
    type: u1
  - id: class_code
    type: device_class_code
  - id: image_len
    type: u2
  - id: rev_level
    type: u2
  - id: code_type
    type: u1
    enum: code_type
  - id: indicator
    type: u1
  - id: maximum_runtime_image_length
    type: u2
    if: rev > 30
  - id: configuration_utility_code_header_ptr
    type: u2
    if: rev > 30
  - id: dmtf_clp_entry_point_ptr
    type: u2
    if: rev > 30
types:
  pci_data_struct_ptr:
    seq:
      - id: ptr
        type: u2
    instances:
      pci_data_struct:
        pos: ptr
        type: pci_data_structure
        if: ptr != 0
enums:
  code_type:
    0: x86
    1: open_firmware
    2: hewlett_packard
    3: efi
