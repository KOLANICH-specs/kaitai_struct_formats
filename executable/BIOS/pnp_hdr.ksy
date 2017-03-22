meta:
  id: pnp_hdr
  title: Generic Option ROM Header
  application: x86 architecture
  endian: le
  license: Unlicense
  imports:
    - /firmware/device_class_code
    - /firmware/bios_header_generic

doc-ref:
  - Plug and Play BIOS Specification Version 1.0A May 5, 1994, 3.2 Expansion Header for Plug and Play
  - 'BIOS Boot Specification Version 1.01 January 11, 1996, Appendix A: Data Structures, A.3 PnP Expansion Header'
  - http://download.intel.com/support/motherboards/desktop/sb/pnpbiosspecificationv10a.pdf
  - http://www.scs.stanford.edu/05au-cs240c/lab/specsbbs101.pdf
seq:
  - id: structure_revision
    type: u1
  - id: length_16
    type: u1
  - id: next_header
    type: header_ptr
  - id: res1
    type: u1
  - id: checksum
    type: u1
  - id: dev_id
    type: u4
  - id: manuf_str_ptr
    type: c_str_ptr
  - id: prod_name_ptr
    type: c_str_ptr
  - id: dev_type
    type: device_class_code
  - id: dev_ind
    type: device_indicators
  - id: boot_conn_vec
    type: u2
  - id: disc_vec
    type: u2
  - id: bootstr_entr_point
    type: u2
  - id: reserved
    type: u2
  - id: static_res_inf_vec
    type: u2
instances:
  length:
    value: length_16 * 16
types:
  c_str_ptr:
    seq:
      - id: ptr
        type: u2
    instances:
      str:
        pos: ptr
        type: strz
        encoding: ASCII
        if: ptr != 0
  device_indicators:
    seq:
      - id: supports_ddi_model
        type: b1
      - id: may_be_shadowed_in_ram
        type: b1
      - id: read_cacheable
        type: b1
      - id: boot_device
        type: b1
      - id: reserved_0
        type: b1
      - id: ipl_device
        type: b1
      - id: input_device
        type: b1
      - id: display_device
        type: b1
