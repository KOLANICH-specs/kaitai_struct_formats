meta:
  id: usb_urb_transfer_flags_free_bsd
  license: BSD-2-Clause
  endian: le
  bit-endian: le

doc-ref:
  - https://github.com/freebsd/freebsd/blob/1d6e4247415d264485ee94b59fdbc12e0c566fd0/sys/compat/linuxkpi/common/include/linux/usb.h#L255

seq:
  - id: not_ok
    -orig-id: URB_SHORT_NOT_OK
    type: b1
    doc: report short transfers like errors
  - id: iso_asap
    -orig-id: URB_ISO_ASAP
    type: b1
    doc: ignore "start_frame" field
  - id: zero_packet
    -orig-id: URB_ZERO_PACKET
    type: b1
    doc: the USB transfer ends with a short packet
  - id: no_transfer_dma_map
    -orig-id: URB_NO_TRANSFER_DMA_MAP
    type: b1
    doc: "transfer_dma" is valid on submit
  - id: wait_wakeup
    -orig-id: URB_WAIT_WAKEUP
    type: b1
    doc: 0x0010 custom flags
  - id: is_sleeping
    -orig-id: URB_IS_SLEEPING
    type: b1
    doc: 0x0020 custom flags
  - id: unkn
    type: b10
