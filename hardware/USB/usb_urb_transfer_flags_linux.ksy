meta:
  id: usb_urb_transfer_flags_linux
  license: GPL-2.0
  endian: le
  bit-endian: le

doc-ref:
  - https://github.com/torvalds/linux/blob/ecfd7940b8641da6e41ca94eba36876dc2ba827b/include/linux/usb.h#L1328

seq:
  - id: not_ok
    -orig-id: URB_SHORT_NOT_OK
    type: b1
    doc: report short reads as errors
  - id: iso_asap
    -orig-id: URB_ISO_ASAP
    type: b1
    doc: iso-only; use the first unexpired slot in the schedule
  - id: no_transfer_dma_map
    -orig-id: URB_NO_TRANSFER_DMA_MAP
    type: b1
    doc: urb->transfer_dma valid on submit
  - id: unkn0
    type: b3
  - id: zero_packet
    -orig-id: URB_ZERO_PACKET
    type: b1
    doc: Finish bulk OUT with short packet
  - id: no_interrupt
    -orig-id: URB_NO_INTERRUPT
    type: b1
    doc: no non-error interrupt needed
  - id: free_buffer
    -orig-id: URB_FREE_BUFFER
    type: b1
    doc: Free transfer buffer with the URB
  - id: dir_in
    -orig-id: URB_DIR_IN
    type: b1
    doc: Transfer from device to host
  - id: unkn1
    type: b7
  - id: map_single
    -orig-id: URB_DMA_MAP_SINGLE
    type: b1
    doc: Non-scatter-gather mapping
  - id: map_page
    -orig-id: URB_DMA_MAP_PAGE
    type: b1
    doc: HCD-unsupported S-G
  - id: dma_map_sg
    -orig-id: URB_DMA_MAP_SG
    type: b1
    doc: HCD-supported S-G
  - id: map_local
    -orig-id: URB_MAP_LOCAL
    type: b1
    doc: HCD-local-memory mapping
  - id: setup_map_single
    -orig-id: URB_SETUP_MAP_SINGLE
    type: b1
    doc: Setup packet DMA mapped
  - id: setup_map_local
    -orig-id: URB_SETUP_MAP_LOCAL
    type: b1
    doc: HCD-local setup packet
  - id: dma_sg_combined
    -orig-id: URB_DMA_SG_COMBINED
    type: b1
    doc: S-G entries were combined
  - id: aligned_temp_buffer
    -orig-id: URB_ALIGNED_TEMP_BUFFER
    type: b1
    doc: Temp buffer was alloc'd
  - id: unkn2
    type: u1
