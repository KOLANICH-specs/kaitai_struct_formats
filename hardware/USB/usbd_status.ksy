meta:
  id: usbd_status
  license: Unlicense
  endian: le
doc: |
  Little endian is assumed
doc-ref:
  - https://raw.githubusercontent.com/reactos/reactos/master/sdk/include/psdk/usb.h
  - https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/content/usb/ns-usb-_urb_header
seq:
  - id: code0
    type: b8
    doc: switch a enum depending on c21
  - id: code11
    type: b4
    enum: c11
  - id: code10
    type: b4
    enum: c10

  - id: code21
    type: b4
    enum: c21
  - id: code20
    type: b4
    enum: c20

  - id: error
    type: b1
  - id: pending
    type: b1
  - id: reserved31
    type: b2
  - id: reserved30
    type: b4
instances:
  bad:
    value: code0
    enum: c0_bad
    if: code21==c21::bad
  some_error:
    value: code0
    enum: c0
    if: code21==c21::none
enums:
  c0:
    0x00: none
    0x01: crc
    0x02: btstuff
    0x03: data_toggle_mismatch
    0x04: stall_pid
    0x05: dev_not_responding
    0x06: pid_check_failure
    0x07: unexpected_pid
    0x08: data_overrun
    0x09: data_underrun
    0x0a: reserved1
    0x0b: reserved2
    0x0c: buffer_overrun
    0x0d: buffer_underrun
    0x0f: not_accessed
    0x10: fifo
    0x11: xact_error
    0x12: babble_detected
    0x13: data_buffer_error
    0x30: endpoint_halted
  c0_bad:
    0x00: none
    0x01: bad_descriptor_blen
    0x02: bad_descriptor_type
    0x03: bad_interface_descriptor
    0x04: bad_endpoint_descriptor
    0x05: bad_interface_assoc_descriptor
    0x06: bad_config_desc_length
    0x07: bad_number_of_interfaces
    0x08: bad_number_of_endpoints
    0x09: bad_endpoint_address
  c10:
    0x0: none
    0x2: invalid_urb_function
    0x3: invalid_parameter
    0x4: error_busy
    0x6: invalid_pipe_handle
    0x7: no_bandwidth
    0x8: internal_hc_error
    0x9: error_short_transfer

    0xa: bad_start_frame
    0xb: isoch_request_failed
    0xc: frame_control_owned
    0xd: frame_control_not_owned
    0xe: not_supported
    0xf: invalid_configuration_descriptor
  c11:
    0x0: none
    0x1: insufficient_resources
    0x2: set_config_failed
    0x3: buffer_too_small
    0x4: interface_not_found
    0x5: invalid_pipe_flags
    0x6: timeout
    0x7: device_gone
    0x8: status_not_mapped
    0x9: hub_internal_error
  c20:
    0x00: none
    0x01: canceled
    0x02: iso_not_accessed_by_hw
    0x03: iso_td_error
    0x04: iso_na_late_usbport
    0x05: iso_not_accessed_late
  c21:
    0x00: none
    0x10: bad
