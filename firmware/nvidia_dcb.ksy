meta:
  id: nvidia_dcb
  title: Device Control Block 4.x
  license: MIT
  endian: le
-license-text: |
  Copyright (c) 2019, NVIDIA CORPORATION. All rights reserved.
  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
doc: |
  Device Control Blocks (DCBs) are static tables used to describe the board topology and connections external to the GPU chip.
  Each board built has specific additions to the capabilities through external devices, as well as limitations where output lines are not linked to device connectors. DCBs define the devices connected, specific information needed to configure those devices, and the external electrical connections such as HDMI and Display Port.
  DCBs do not try to explain the capabilities of the chip itself. That information is implicit in the VBIOS, firmware and drivers, which are built differently for each chip. Both the firmware and the drivers know the inherent capability of each chip, and use runtime choices to determine chip dependent code paths.
  DCB version and use
    DCB 1.x is used with Core3 VBIOS (NV5, NV10, NV11, NV15, NV20).
    DCB 2.x (2.0-2.4) is used with Core4 and Core4r2 VBIOS (NV17, NV25, NV28, NV3x).
    DCB 3.0 is used with Core5 VBIOS (NV4x, G7x).
    DCB 4.x is used with Core6, Core7, and Core8 VBIOS (G80+).
  The 4.x DCB Data Structure consists of the following parts:
    Header - The version number (e.g., 0x40 for Version 4.0), the header size, the size of each DCB Entry (currently 8 bytes), the number of valid DCB Entries, pointers to different tables, and the DCB signature. If any of the pointers here are NULL, then those tables are considered to be absent or invalid.
    Device entries list - One for each display connector (two for DVI-I connectors). Each device entry is subdivided into two main parts: Display Path Information and Device Specific Information.
doc-ref:
  - https://download.nvidia.com/open-gpu-doc/DCB/2/DCB-4.x-Specification.html
  - https://github.com/NVIDIA/open-gpu-doc/blob/master/DCB/DCB-4.x-Specification.html
params:
  - id: offset
    type: u8
    doc: |
      # Here is a simple script helping you to parse the data from files
      from kaitaistruct import KaitaiStream

      import nvidia_dcb
      from nvidia_dcb import NvidiaDcb

      signature = bytes([0xcb, 0xbd, 0xdc, 0x4e])
      offset = -(NvidiaDcb.GenericTableHeader.generic_header_size.fget(NvidiaDcb.GenericTableHeader) + 2)


      def locateDCB(fn):
        with open(fn, "rb") as f:
          data = f.read()
        found = data.find(signature)
        if found > 0:
          return found + offset


      def fromOffset(cls, fileName, offset):
        f = open(fileName, "rb")
        return cls(offset, KaitaiStream(f))
instances:
  header:
    pos: offset
    type: header
  gpio_assignment_table:
    pos: header.data.gpio_assignment_table_ptr
    type: gpio_assignment_table
  communications_control_block:
    pos: header.data.communications_control_block_ptr
    type: communications_control_block
  input_devices_table:
    pos: header.data.input_devices_table_ptr
    type: input_devices_table
    if: header.data.input_devices_table_ptr != 0
  personal_cinema_table:
    pos: header.data.personal_cinema_table_ptr
    type: personal_cinema_table
    if: header.data.personal_cinema_table_ptr != 0
  spread_spectrum_table:
    pos: header.data.spread_spectrum_table_ptr
    type: spread_spectrum_table
    if: header.data.spread_spectrum_table_ptr != 0
  i2c_devices_table:
    pos: header.data.i2c_devices_table_ptr
    type: i2c_devices_table
    if: header.data.i2c_devices_table_ptr != 0
  connector_table:
    pos: header.data.connector_table_ptr
    type: connector_table
  hdtv_translation_table:
    pos: header.data.hdtv_translation_table_ptr
    type: hdtv_translation_table
    if: header.data.hdtv_translation_table_ptr != 0
  switched_outputs_table:
    pos: header.data.switched_outputs_table_ptr
    type: switched_outputs_table
    if: header.data.switched_outputs_table_ptr != 0
types:
  version:
    seq:
      - id: value
        type: u1
    instances:
      major:
        value: value >> 4
      minor:
        value: value & 0xF
  generic_table_header:
    doc: A common part of the most of headers
    seq:
      - id: version #0
        type: version
        doc: Version number of the header and Entries.
      - id: header_size #1
        type: u1
        doc: Size of the header in bytes.
      - id: entry_count #2
        type: u1
        doc: Number of entries.
      - id: entry_size #3
        type: u1
        doc: Size of each entry in bytes.
    instances:
      generic_header_size:
        value: 4
      rest_header_size:
        value: header_size - generic_header_size
  header:
    doc: |
      An "optional" table pointer or field may be set to zero to indicate that no table is present. If the structure is not needed, then this pointer can be set to 0.
      Note: Throughout this document, a "pointer" means a byte offset relative to the start of the VBIOS image.
    seq:
      - id: generic_table_header
        type: generic_table_header
        doc: |
          version -> E.g., DCB 4.0 will start with a value of 0x40 here. A version number of zero directs the driver to use\nan internal DCB table. Optional.
          header_size -> Size of the header. For v4.0 this will be 27 bytes. Mandatory.
          entry_count -> Number of DCB Device Entries immediately following this table. Mandatory.
          entry_size -> With the start of DCB 4.0, this field should be 8. Mandatory.
      - id: data
        size: generic_table_header.rest_header_size
        type: data
      - id: entries
        size: generic_table_header.entry_size
        type: dcb_device_entry
        repeat: expr
        repeat-expr: generic_table_header.entry_count
    types:
      data:
        seq:
          - id: communications_control_block_ptr
            type: u2
            doc: Pointer to the Communications Control Block.  In v3.0 this was the I2C Control Block Pointer. Mandatory.
          - id: signature
            contents: [0xCB, 0xBD, 0xDC, N]   # "N"_DCB_DCB (little endian)
          - id: gpio_assignment_table_ptr
            type: u2
            doc: Pointer to the GPIO Assignment Table. Mandatory.
          - id: input_devices_table_ptr
            type: u2
            doc: Pointer to the Input Devices Table. Optional.
          - id: personal_cinema_table_ptr
            type: u2
            doc: Pointer to the Personal Cinema Table. Optional.
          - id: spread_spectrum_table_ptr
            type: u2
            doc: Pointer to the Spread Spectrum Table. Optional.
          - id: i2c_devices_table_ptr
            type: u2
            doc: Pointer to the I2C Devices Table. Optional.
          - id: connector_table_ptr
            type: u2
            doc: Pointer to the Connector Table. Mandatory.
          - id: flags
            type: flags
          - id: hdtv_translation_table_ptr
            type: u2
            doc: Pointer to the HDTV Translation Table. This structure is optional. Optional. Added 08-02-06 in DCB 3.0
          - id: switched_outputs_table_ptr
            type: u2
            doc: Pointer to the Switched Outputs Table.  This structure is optional. Optional. Added 11-07-06.
      flags:
        doc: |
          All undefined bits are reserved and must be set to 0.
          Note: A PIOR port cannot be used both as a Distributed Rendering connection and as an Output Display at the same time.
        seq:
          - id: boot_display_count #0
            type: b1
            doc: |
              0 - Only 1 boot display is allowed.
              1 - 2 boot displays are allowed.
          - id: reserved0 #1
            type: b3
          - id: vip_location #4
            type: b2
            enum: vip
          - id: dr_ports_pin_set_a #6
            type: b1
            doc: |
              1 - Pin Set A is routed to a SLI Finger.
              0 - Pin Set A is not attached.
          - id: dr_ports_pin_set_b #7
            type: b1
            doc: |
              1 - Pin Set B is routed to a SLI Finger.
              0 - Pin Set B is not attached.
          # A PIOR port cannot be used both as a Distributed Rendering connection and as an Output Display at the same time.
        enums:
          vip:
            0b00: no_vip
            0b01: pin_set_a
            0b10: pin_set_b
            0b11: reserved
      dcb_device_entry:
        doc: |
          There is one device entry for each output display path. The number of DCB entries is listed in the DCB Header.
          Note: For DVI-I connectors there are two entries: one for the CRT and one for the LCD. The two device entries share the same I2C port.
          Device Entries are listed in order of boot priority. The VBIOS code will iterate through the DCB entries and if a device is found, then that device will be configured. If not, the VBIOS moves to the next index in the DCB. If no device is found, the first CRT on the list should be chosen.
          GPUs earlier than G80 have a "mirror mode" feature that enables up to two display devices to be enabled by the VBIOS, and controlled through the same VGA registers. G80 and later display hardware only supports one display in VGA mode, and the VBIOS will only enable one display device.
          When Device Entries are listed, it is not allowed to have two entries for the same output device.
        seq:
          - id: display_path_information
            type: display_path_information
            size: 4
          - id: device_specific_information
            size: 4
            type:
              switch-on: display_path_information.type
              cases:
                type::tmds: dfp_specific_information
                type::lvds: dfp_specific_information
                type::sdi: dfp_specific_information
                type::display_port: dfp_specific_information
                type::crt: crt_specific_information
                type::tv: tv_specific_information
        enums:
          type:
            0x0: crt
            0x1: tv
            0x2: tmds
            0x3: lvds
            0x4: reserved0x4
            0x5: sdi
            0x6: display_port
            0x7: unknown0x7
            0x8: reserved0x8
            0xA: unknown0xa
            0xB: unknown0xb
            0xE: end_of_line #signals the SW to stop parsing any more entries.
            0xF: skip_entry #allows quick removal of entries from DCB.
        types:
          display_path_information:
            doc: |
              Display Path Information, contain the main routing information. Their format is common to all devices.
            seq:
              - id: type
                type: b4
                enum: type
                doc: |
                  This field defines the Type of the display used on this display path.
                  Note: LVDS entries must precede eDP entries to meet RM requirements and avoid glitches during detection.
              - id: edid_port
                type: b4
                doc: |
                  Each number refers to an entry in the Communications Control Block Structure that represents the port to use in order to query the EDID. This number cannot be equal to or greater than the Communication Control Block Header’s Entry Count value, except if the EDID is not retrieved via DDC (over I2C or DPAux).
                  For DFPs, if the EDID source is set to straps or SBIOS, then this field must be set to 0xF to indicate that we are not using a Communications Control Block port for this device to get the EDID.
              - id: head_bitmask
                type: b1
                repeat: expr
                repeat-expr: 4
                doc: |
                  Each bit defines the ability of that head with this device.
                  Bit n = Head n
                  GPUs before GK107 only support two heads. For those devices, bits 2 and 3 should always be zero.
                  GPUs before GK107 only support two heads. For those devices, bits 2 and 3 should always be zero.
              - id: connector_index
                type: b4
                doc: |
                  Connector table entry index.
                  This field signifies a specific entry in the Connector Table. More than one DCB device can have the same Connector Index. This number cannot be equal to or greater than the Connector Table Header’s Entry Count value.
                  Note: If two DCB entries have the same Connector Index, that still allows them to be displayed at the same time. To prevent combinations based on the connector, use the Bus field.
              - id: bus
                type: b4
                doc: |
                  Logical bus, used for mutual exclusion.
                  This field only allows for logical mutual exclusion of devices so that they cannot display simultaneously. The driver uses this field to disallow the use of a combination of two devices if they share the same bus number.
              - id: location
                type: b2
                enum: location
                doc: Location of the final stage devices, on-chip or off-chip.
              - id: boot_device_removed
                type: b1
                doc: |
                  Disables this as a boot display if set.
                  0 = This device is allowed to boot if detected.
                  1 = This device is not allowed to boot, even if detected.

              - id: blind_boot_device_removed
                type: b1
                doc: |
                  If set, disables the ability to boot if not display is detected.
                  0 = This device is allowed to boot if no devices are detected.
                  1 = This device is not allowed to boot if no devices are detected.

              - id: virtual_device
                type: b1
                doc: |
                  Indicates this is a virtual device.
                  Virtual devices are used only for remote desktop rendering. When set to 1, EDID Port should be set to 0xF (unused) and the Connector Index should reference an entry with Type="Skip Entry".
              - id: reserved
                type: b3
                doc: set to 0
            enums:
              location:
                0: internal # On Chip (internal) TV encoder, internal TMDS encoder
                1: external # On Board (external) DAC, external TMDS encoder
                2: reserved

          crt_specific_information:
            seq:
              - id: reserved
                size: 4
          dfp_specific_information:
            seq:
              - id: edid_source
                type: b2
                enum: edid_source
                doc: This field states where to get the EDIDs for the panels. If the board designer chooses to use DDC based EDIDs always, the VBIOS can override the Panel Strap to always indicate 0xF via SW Strap Overrides or through the DevInit scripts.

              - id: power_backlight_control
                type: b2
                enum: control
                doc: Power and Backlight Control.

              - id: sl_dpl
                type: b2
                doc: |
                  Sub-link/DisplayPort Link/Pad Link Assignment
                  This field specifies a board-supported sub-link mask for TMDS, LVDS, and SDI. For Display Port, this field specifies the link mask supported on the board.
                  For DCB 4.x: For TMDS, LVDS, and SDI, this field lists which sub-links in each SOR are routed to the connector on the board.
                  Possible sub-link values are:
                    Bit 0: Sub-link A
                    Bit 1: Sub-link B
                  If both sub-links are routed to the connector, specifying a dual-link connector, then bits 0 and 1 will both be set.
                  Note: Dual-link hook-up does not necessarily mean that both links should be used during programming. According to the DVI 1.0 specification, the crossover frequency of 165 MHZ should be the deciding factor for when dual-link vs. single-link connections should be used for TMDS use. This field merely indicates whether the connector has two links connected to it. It does not specify the actual use of either single-link or dual-link connections.
                  LVDS uses single-link or dual-link connections based on the individual panel model’s requirements. For example, SXGA panels may be run with single-link or dual-link LVDS connections.
                  For DisplayPort, this field describes which links in each SOR are routed to the connector on the board. Possible link values are:
                    Bit 0: DP-A (Display Port Resource A)
                    Bit 1: DP-B (Display Port Resource B)
                  Note: Unlike TMDS, LVDS, and SDI, if both links are routed to the connector, this does not indicate the presence of a dual-link connector. It simply means that both Display Port (DP) resources A and B may be used with this SOR. That is: DP-A or DP-B may be associated with an output device (OD) to output via DisplayPort, but not both simultaneously.
                  For DCB 4.1: For TMDS/LVDS/DP this field describes which links of the Pad Macro are routed to the connector on the board.
                    Bit 0: Pad Link 0
                    Bit 1: Pad Link 1

              - id: reserved0
                type: b2
                doc: set to 0
              - id: external_link_type
                type: u1
                enum: external_link_type
                doc: This field describes the exact external link used on the board. If this Location field in the Display Path of this DCB entry is set to ON CHIP, then these bits should be set to 0.

              - id: reserved1
                type: b1
              - id: hdmi_enable
                type: b1
                doc: This bit is placed here to allow the use of HDMI on this particular DFP output display.
              - id: reserved2
                type: b2
                doc: set to 0
              - id: external_communications_port
                type: b1
                enum: external_communications_port
                doc: |
                  If this device uses external I2C or DPAux communication, then this field allows us to know which port is to be used. If the device is internal to the chip, set this bit to 0 by default.
                  The Communications Control Block Header holds the primary and secondary port indices. Each index maps to an entry in the Communications control Block table, which specifies the physical port and type to use to communicate with this device.
              - id: maximum_link_rate_
                type: b3
                enum: maximum_link_rate
                doc: This field describes the maximum link rate allowed for the links within the Display Port connection. This field is only applicable to DisplayPort device types.
              - id: maximum_lane_mask
                type: b4
                enum: maximum_lane_mask
                doc: This field describes the maximum lanes that are populated on the board. This field is only applicable to DisplayPort device types.
              - id: reserved3
                type: b4
                doc: set to 0
            enums:
              edid_source:
                0:
                  id: ddc
                  doc: EDID is read via DDC.
                1:
                  id: ps_and_vbios
                  doc: EDID is determined via Panel Straps and VBIOS tables.
                2:
                  id: acpi_or_int15
                  doc: EDID is obtained using the _DDC ACPI interface or VBIOS 5F80/02 SBIOS INT15 calls.
                3: reserved
              control:
                0:
                  id: external
                  doc: This is used to define panels where we don’t have direct control over the power or backlight. For example, this value is used for most TMDS panels.
                1:
                  id: scripts
                  doc: Used for most LVDS panels.
                2:
                  id: callbacks
                  doc: VBIOS callbacks to the SBIOS.
              external_communications_port:
                0: primary
                1: secondary
              maximum_link_rate:
                0:
                  id: gbps_1_62
                  doc: 1.62 Gbps
                1:
                  id: gbps_2_70
                  doc: 2.7 Gbps
                2:
                  id: gbps_5_40
                  doc: 5.4 Gbps
                3:
                  id: gbps_8_10
                  doc: 8.1 Gbps
              maximum_lane_mask:
                0x0: n_a
                0x1: one_lane
                0x2: two_lanes_maxwell # only on Maxwell & Later chips
                0x3: two_lanes_old # deprecated, will be removed in DCB 6.0
                0x4: four_lanes_maxwell # only on Maxwell & Later chips
                0xF: four_lanes_old # deprecated, will be removed in DCB 6.0
              external_link_type:
                0:
                  id: undefined
                  doc: allows backward compatibility, assumes Single-Link.
                1:
                  id: silicon_image_164
                  doc: Single-Link TMDS. 0x70
                2:
                  id: silicon_image_178
                  doc: Single-Link TMDS. 0x70
                3:
                  id: dual_silicon_image_178
                  doc: Dual-Link TMDS. 0x70 (primary), 0x72 (secondary)
                4:
                  id: chrontel_7009
                  doc: Single-Link TMDS. 0xEA
                5:
                  id: chrontel_7019
                  doc: Dual-Link LVDS. 0xEA
                6:
                  id: national_semiconductor_ds90c387
                  doc: Dual Link LVDS.
                7:
                  id: silicon_image_164_alt
                  doc: Single-Link TMDS (Alternate Address). 0x74
                8:
                  id: chrontel_7301
                  doc: Single-Link TMDS.
                9:
                  id: silicon_image_1162
                  doc: Single Link TMDS (Alternate Address). 0x72
                10: reserved
                11:
                  id: analogix_anx9801
                  doc: 4-Lane DisplayPort (deprecated on Fermi+). 0x70 (transmitter), 0x72 (receiver)
                12:
                  id: parade_tech_dp501
                  doc: 4-Lane DisplayPort.
                13:
                  id: analogix_anx9805
                  doc: HDMI and DisplayPort (deprecated on Fermi+). 0x70, 0x72, 0x7A, 0x74
                14:
                  id: analogix_anx9805_alt
                  doc: HDMI and DisplayPort (Alternate Address) (deprecated on Fermi+). 0x78, 0x76, 0x7E, 0x7C
          tv_specific_information:
            seq:
              - id: sdtv_format
                type: b3
                enum: sdtv_format
                doc: .
              - id: reserved0
                type: b1
                doc: set to 0
              - id: dacs_lo_
                type: b4
                doc: DAC description, lower four bits.
              - id: encoder_id
                type: encoder
                doc: This field describes the exact encoder used on the board.
              - id: dacs_hi_
                type: b4
                doc: This field shows bits 4-7 of the DACs value.
              - id: external_communication_port
                type: b1
                doc: |
                  If this device uses external I2C communication, then this field allows us to know which device will be used. If the device is internal to the chip, set this bit to 0 as default.
                  Currently defined values are:
                    0 = Primary Communications Port
                    1 = Secondary Communications Port
                  The I2C Control Block Header holds the primary and secondary port indices.

              - id: connector_count
                type: b2
                doc: |
                  Count of connectors minus one.
                  Generally, there is only 1 connector per DCB display path. TVs are special since one output device could have multiple connectors.
                  If only one bit of either of the Red, Green or Blue defines in the above DACs field is set, then this field must be set to 1 connector.
                  If two bits of either of the Red, Green or Blue defines in the above DACs field is set, then this field must be set to 1 or 2 connectors for a S-Video and/or Composite connector. But those connectors cannot be displayed simultaneously.
                  If three bits of either of the Red, Green or Blue defines in the above DACs field is set, then this field must be set to 2 connectors for both a S-Video and Composite connector.
                  If the HDTV Bit is set, then we can assume that there will be connectors for YPrPb, S-Video, and Composite off of the Personal Cinema pod. So, this field should be set to 3 connectors.
              - id: hdtv_format
                type: b4
                enum: hdtv_format
                doc: This field determines the default HDTV Format.
              - id: reserved1
                type: b5
                doc: set to 0.
            instances:
              dacs:
                value: dacs_hi_ << 4 | dacs_lo_
                enum: dacs
                doc: These bits define the availability of encoder outputs that the board supports to the TV connectors.
            types:
              encoder:
                seq:
                  - id: vendor
                    type: b4
                    enum: vendor
                  - id: model
                    type: b4
                enums:
                  vendor:
                    0x0: conexant_0
                    0x4: chrontel_4
                    0x8: philips_8
                    0xc: nvidia_c
                  model_conexant_0:
                    0x0: brooktree_868
                    0x1: brooktree_869
                    0x2: conexant_870
                    0x3: conexant_871
                    0x4: conexant_872
                    0x5: conexant_873
                    0x6: conexant_874
                    0x7: conexant_875
                  model_chrontel_4:
                    0x0: chrontel_7003
                    0x1: chrontel_7004
                    0x2: chrontel_7005
                    0x3: chrontel_7006
                    0x4: chrontel_7007
                    0x5: chrontel_7008
                    0x6: chrontel_7009
                    0x7: chrontel_7010
                    0x8: chrontel_7011
                    0x9: chrontel_7012
                    0xa: chrontel_7019
                    0xb: chrontel_7021
                  model_philips_8:
                    0x80: philips_7102
                    0x81: philips_7103
                    0x82: philips_7104
                    0x83: philips_7105
                    0x84: philips_7108
                    0x85: philips_7108a
                    0x86: philips_7108b
                    0x87: philips_7109
                    0x88: philips_7109a
                  model_nvidia:
                    0xC0: nvidia_internal

            enums:
              sdtv_format:
                0x0:
                  id: ntsc_m
                  doc: US
                0x1:
                  id: ntsc_j
                  doc: Japan
                0x2:
                  id: pal_m
                  doc: NTSC Timing w/PAL Encoding - Brazilian Format
                0x3:
                  id: pal_bdghi
                  doc: US
                0x4:
                  id: pal_n
                  doc: Paraguay and Uruguay Format
                0x5:
                  id: pal_nc
                  doc: Argentina Format
                0x6: reserved6
                0x7: reserved7
              hdtv_format:
                0x0: hdtv_576i
                0x1: hdtv_480i
                0x2: hdtv_480p_60hz
                0x3: hdtv_576p_50hz
                0x4: hdtv_720p_50hz
                0x5: hdtv_720p_60hz
                0x6: hdtv_1080i_50hz
                0x7: hdtv_1080i_60hz
                0x8: hdtv_1080p_24hz

              dacs:
                0x00: reserved
                0x01: invalid01
                0x02: cvbs_on_green
                0x03: cvbs_on_green_s_video_on_red_chroma_and_green_luma
                0x04: cvbs_on_blue
                0x05: invalid05
                0x06: invalid06
                0x07: cvbs_on_blue_s_video_on_red_chroma_and_green_luma
                0x08: standard_hdtv
                0x09: hdtv_twist_1
                0x0A: scart
                0x0B: twist_2
                0x0C: scart_plus_hdtv_0c
                0x0D: standard_hdtv_without_sdtv
                0x0E: scart_twist_1
                0x0F: scart_plus_hdtv_0f
                0x11: composite_plus_hdtv_outputs
                0x12: hdtv_plus_scart_twist_1
                0x13: s_video_on_red_chroma_and_green_luma
  communications_control_block:
    doc: |
      This structure is REQUIRED in the DCB 4.x spec. It must be listed inside every DCB. The VBIOS and the (U)EFI driver will use the data from this structure.
      The Communications Control Block provides logical to physical translation of all the different ways that the GPU can use to communicate with other devices on the board or to displays. Prior to DCB 4.0 there were 3 different I2C Ports for GPUs and an extra 2 for Crush (nForce chipset) 11/17. The Northbridge, which holds the integrated GPU, only has 1.5 V signaling, but the DDC/EDID spec requires 3.3 V signaling. So, for Crush, we use two ports on the south bridge to handle the DDC voltage requirements.
      Note: Crush, also known as nForce or nForce2, is a motherboard chipset created by NVIDIA. Crush was released in mid-2001.
      For DCB 4.x, the norm will be 4 I2C ports as exposed on G80. With Display Port added in G98, we’ll expose a DPAUX port as well.
    seq:
      - id: header
        type: header
      - id: entries
        size: header.generic_table_header.entry_size
        type:
          switch-on: header.generic_table_header.version.value
          cases:
            0x40: x40_entry
            0x41: x41_entry
        repeat: expr
        repeat-expr: header.generic_table_header.entry_count
        if: header.generic_table_header.entry_size > 0 # wtf why is this 0
    types:
      port_speed:
        doc: |
          The I2C spec defines 3 different communication speeds: * Standard - 100 kHz * Fast - 400 kHz * High Speed - 3.4 MHz
          Each device on an I2C bus must comply with that speed otherwise, the lowest device on that bus will clock stall the speed to what it can handle. High Speed requires extra programming to allow a specific master to send the high speed data. There are programming requirements to also allow for the fallback between higher level speeds and lower levels speeds.
          No traffic on the I2C port may exceed the speed specified here.
          Most (perhaps all) DCBs set this field to 0.
        seq:
          - id: port_speed_
            type: b4
            enum: port_speed_
            doc: the most probably you need port_speed
        instances:
          port_speed:
            value: |
              (port_speed_::standard_100.to_i<=port_speed_.to_i and port_speed_.to_i<=port_speed_::high_speed_3400.to_i) ? (1<<(port_speed_.to_i-port_speed_::standard_100.to_i))*100 : (
                port_speed_.to_i==port_speed_::slow_60.to_i ?
                60 :
                (
                  port_speed_.to_i==port_speed_::standard_300.to_i ?
                  300 :
                  0
                )
              )
            doc: in kHz
        enums:
          port_speed_:
            0x0: default # Probably the only one we’ll ever use.
            0x1: standard_100
            0x2: standard_200
            0x3: fast_400
            0x4: fast_800
            0x5: fast_1600
            0x6: high_speed_3400
            0x7: slow_60
            0x8: standard_300

      header:
        doc: |
          Version 0x40 of the Communications Control Block, which is used for Core 6, and Core 6 revision 2, Core70, Core80, and Core82 (which associate to G8x, G9x, GT2xx, GF1xx, GKxxx, and GM10x GPUs
          There is one port entry for each port used. A DVI-I connector’s two device entries share the same I2C port.
        seq:
          - id: generic_table_header
            type: generic_table_header
            doc: |
              version -> CCB 4.0 will start with a value of 0x40 here.  A version of 0 here is invalid.
              header_size -> Size of the CCB Header in bytes.  This is typically 5 bytes.
              entry_count -> Number of CCB Entries starting directly after the end of this table.
              entry_size -> Size of each entry in bytes. This field should be 4.
          - id: data
            size: generic_table_header.rest_header_size
            type: data
            if: generic_table_header.rest_header_size > 0
        types:
          data:
            seq:
              - id: primary_communication_port
                type:
                  switch-on: _parent.generic_table_header.version.value
                  cases:
                    0x40: b4
                    0x41: u1
                doc: Index for the primary communications port.  Specifically, if we need to talk with an external device, the port referenced by this index will be the primary port to talk with that device.
              - id: secondary_communication_port
                type:
                  switch-on: _parent.generic_table_header.version.value
                  cases:
                    0x40: b4
                    0x41: u1
                doc: Index for the secondary communications port.  Specifically, if we need to talk with an external device, this port referenced by this index will be the secondary port to talk with that device.
      x40_entry:
        seq:
          - id: payload
            type:
              switch-on: access_method
              cases:
                access_method::i2c: i2c
                access_method::display_port_aux_channel: display_port_aux_channel
          - id: access_method
            type: u1
            enum: access_method
            doc: This field indicates how the software should control each port. From NV50 onward a new port mapping was implemented. Older I2C Access methods - CRTC indexed mapping and PCI IO Mapping - have been removed, but their values reserved to allow SW compatibility.
        types:
          i2c:
            seq:
              - id: physical_port
                type: b4
                enum: physical_port
                doc: Physical Nv5x Port
              - id: port_speed
                type: port_speed
              - id: hybrid_pad
                type: b1
                doc: |
                  This bit is used to tell us if we’re enabling Hybrid Pad control for this entry. Hybrid pad control requires that we switch bits in the NV_PMGR_HYBRID_PADCTL area when switching between I2C output and DPAux output. The values here are:
                    * 0 = Normal Mode - Generic I2C Port
                    * 1 = Hybrid Mode - Pad allows for switching between DPAux and I2C
              - id: physical_dp_aux_port
                type: b4
                doc: This is the physical DP Aux port used only when Hybrid Pad field is in Hybrid Mode. We need this value since NV_PMGR_HYBRID_PADCTL is indexed based on the DP Port value.
              - id: reserved
                type: b11
                doc: Set as 0
            enums:
              physical_port:
                0: ddc0
                1: ddc1
                2: ddc2
                3: i2c

          display_port_aux_channel:
            seq:
              - id: physical_display_ports
                type: b4
                doc: n = AUXCH n
              - id: reserved0
                type: b4
              - id: hybrid_pad
                type: b1
                doc: |
                  This bit is used to tell us if we’re enabling Hybrid Pad control for this entry. Hybrid pad control requires that we switch bits in the NV_PMGR_HYBRID_PADCTL area when switching between I2C output and DPAux output. The values here are:
                    * 0 = Normal Mode - Generic I2C Port
                    * 1 = Hybrid Mode - Pad allows for switching between DPAux and I2C
              - id: physical_i2c_port
                type: b4
                doc: This is the physical I2C port used only when Hybrid Pad field is in Hybrid Mode.
              - id: reserved1
                type: b11
                doc: Set as 0.

        enums:
          access_method:
            0: reserved0
            1: reserved1
            2: reserved2
            3: reserved3
            4: reserved4
            5: i2c
            6: display_port_aux_channel

      x41_entry:
        seq:
          - id: i2c_port
            type: b5
            doc: Index in PMGR for the I2C Controller that drives the physical pad denoted by this CCB entry. The value 0x1F denotes Unused, meaning that this pad does not support I2C.
          - id: dpaux_port
            type: b5
            doc: Index in PMGR for the DPAUX Controller that drives the physical pad denoted by this CCB entry. The value 0x1F denotes Unused, meaning that this pad does not support DPAUX.
          - id: reserved
            type: b18
            doc: Set as 0.
          - id: i2cport_speed_
            type: port_speed
  input_devices_table:
    doc: |
      This structure is optional. It only needs to be defined if the board provides input devices. Also, the VBIOS or FCODE does not need to use this structure. Only the drivers will use it.
      The Input Devices are listed at a location in the ROM dictated by the 16-bit Input Devices Pointer listed in the DCB Header. Currently, the maximum number of devices is 8. Each device is listed in one 8-bit entry.
      If a device has an Input Device Structure, but not a Personal Cinema Structure defined, we treat that board as a generic VIVO (Video-In, Video-Out) board.
      It is assumed that each of these Input Devices is controlled via I2C through the Primary Communications Port.
    seq:
      - id: header
        type: header
      - id: entries
        type: entry
        size: header.generic_table_header.entry_size
        repeat: expr
        repeat-expr: header.generic_table_header.entry_count
    types:
      header:
        seq:
          - id: generic_table_header
            type: generic_table_header
            doc: |
              version -> Input Devices 4.0 start with a version of 0x40.
              header_size -> Size of the Input Devices Header in Bytes. Initially, this is 4 bytes.
              entry_count -> Number of Input Devices Entries starting directly after the end of this table.
              entry_size -> Size of Each Entry in bytes. This field should be 1.
          - id: data
            size: generic_table_header.rest_header_size
            if: generic_table_header.rest_header_size > 0
      entry:
        seq:
          - id: mode
            type: b4
            doc: This field lists the Mode number that this device supports. If we encounter a Mode of 0xF, that signifies a Skip Entry. This allows for quick removal of a specific entry from the Input Devices.
          - id: type
            type: b2
            enum: type
            doc: This field describes the type of input device that is connected.

          - id: video_type
            type: b2
            enum: video_type
            doc: This field describes the video type of input device that is connected.
        enums:
          video_type:
            0: cvbs
            1: tuner
            2: s_video
          type:
            0: vcr
            1: tv
  personal_cinema_table:
    doc: |
      Note: "Personal Cinema" refers to a line of graphics boards with pre-G80 NVIDIA GPUs and on-board television tuners.
      This structure is optional. It only needs to be defined if the board is intending to provide Personal Cinema support. The VBIOS or FCODE does not need to use this structure. Only the drivers will use it.
      There are many specific defines needed for the personal cinema in order to know which devices are available. Because there are no entries needed for this table, the normal Entry Count and Entry Size will not be a part of this table for now.
      If both the Board ID and the Vendor ID are 0, then the Personal Cinema Table data should be considered invalid. This is akin to other table’s SKIP ENTRY, meaning that we should just skip this table if these IDs are both 0.
      If a device has an Input Devices Table, but not a Personal Cinema Structure defined, we treat that board as a generic VIVO (Video-In, Video-Out) board.
      It is assumed that each of these Personal Cinema Devices is controlled via I2C through the Primary Communications Port.
    seq:
      - id: version
        type: version
        doc: 'Version # of the Personal Cinema Header. The original Personal Cinema table version will start with a value of 0x40 here. If the version is 0 here, then the driver will assume that this table is invalid.'
      - id: header_size
        type: u1
        doc: Size in bytes, 12 for v4.0
      - id: data
        type: data
        size: header_size - 2
        if: header_size > 2 and version.value != 0
    types:
      data:
        seq:
          - id: board_id
            type: u1
            enum: board_id
            doc: This field lists the Personal Cinema Board ID for this board. This provides a mechanism for SW to differentiate between individual Personal Cinema boards and generic Video-In-Video-Out (VIVO) boards.
          - id: vendor_id
            type: u1
            enum: vendor_id
            doc: This field lists the Personal Cinema Vendor ID for this board.
          - id: expander_io
            type: b2
            enum: expander_io
            doc: This field describes the exact number of bits used for the expander IO bus.
          - id: tv_standard
            type: b2
            enum: tv_standard
            doc: This field describes the TV standard used for the input devices.
          - id: sound_decoder1
            type: b4
            enum: sound_decoder
            doc: This field describes the first Sound Decoder used on the board.
          - id: analog_tuner1_type
            type: u1
            enum: analog_tuner_type
            doc: This field describes the first analog-signal tuner used on the board.
          - id: demodulator1
            type: u1
            enum: demodulator
            doc: The first digital-signal tuner used this board.
          - id: sat_dish_power_control_ic
            type: b4
            enum: sat_dish_power_control_ic
            doc: Satellite Dish power controller IC type
          - id: ir_ctrl_mcu
            type: b4
            enum: ir_ctrl_mcu
            doc: The InfraRed transmitter microcontroller type
          - id: sound_decoder2
            type: b4
            enum: sound_decoder
            doc: 'Sound Decoder #2 ID'
          - id: reserved0
            type: b4
            doc: set to 0
          - id: analog_tuner2_type
            type: u1
            enum: analog_tuner_type
            doc: 'Analog Tuner #2 type.'
          - id: tuner1_features
            type: tuner_features
            doc: 'Tuner #1 Functionality, digitial TV, analog TV and FM.'
          - id: reserved1
            type: b1
            doc: set to 0
          - id: tuner2_features
            type: tuner_features
            doc: 'Tuner #2 Functionality'
          - id: reserved2
            type: b1
            doc: set to 0
          - id: demodulator2
            type: u1
            enum: demodulator
            doc: 'Demodulator #2, the second digital-signal tuner'
      tuner_features:
        seq:
          - id: digital
            type: b1
          - id: analog
            type: b1
          - id: fm
            type: b1
    enums:
      board_id:
        0x00: generic_vivo_board_or_no_personal_cinema
        0x01: p79
        0x02: p104
        0x03: p164_nv31
        0x04: p164_nv34
        0x05: p186_nv35
        0x06: p187_nv35
        0x07: p178_nv36
        0x08: p253_nv43
        0x09: p254_nv44
        0x0a: p178_nv36_a2m
        0x0b: p293
        0x0c: p178_nv36_fpga
        0x0d: p143_nv34_fpga
        0x0e: p143_nv34_non_fpga
        0x10: p256_nv43
        0x11: compro
        0x13: p274_nv41
        0x21: asus_aio
        0x22: asus_external_tuner
        0x30: customer_reserved_0
        0x31: customer_reserved_1
        0x32: customer_reserved_2
      vendor_id:
        0x00: generic
        0xde: nvidia
        0xcb: compro
        0x81: asus
      expander_io:
        0: none
        1: eight_bits
        2: sixteen_bits
        3: rf_remote
      tv_standard:
        0: ntsc
        1: pal_secam
        2: worldwide
        3: reserved
      sound_decoder:
        0: mono
        2:
          id: a2
          doc: TDA9873
        3:
          id: nicam
          doc: TDA9874
        4:
          id: btsc
          doc: TDA9850
        5:
          id: fm_fm_japan
          doc: TA8874z
        6:
          id: btsc_eiaj
          doc: SAA7133/SAA7173
        7:
          id: a2_nicam
          doc: SAA7134/SAA7174
        8:
          id: worldwide
          doc: SAA7135/SAA7175
        9:
          id: ntsc
          doc: Micronas MSP 3425G
        10:
          id: pal
          doc: Micronas MSP 3415G
        11: saa7174a
        12: saa7171
        15: not_present

      analog_tuner_type:
        0x00: not_present

        #Philips
        0x01: fi1216_mk2
        0x02: fi1216_mf
        0x03: fi1236_mk2
        0x04: fi1246_mk2
        0x05: fi1256_mk2
        0x06: fq1216_me
        0x07: fq1216_me_mk3
        0x08: fq1236_me_mk3
        0x09: tda_8275
        0x81: fm1216
        0x82: fm1216mf
        0x83: fm1236
        0x84: fm1246
        0x85: fm1256
        0x86: fm1216_me
        0x87: fm1216_me_mk3
        0x88: fm1236_me_mk3


        0x11: temic_403xfy5
        0x12: temic_400xfh5
        0x13: temic_40x6fy5
        0x14: temic_401xfy5
        0x15: temic_4136
        0x16: temic_4146

        0x17: microtune_mt2040
        0x18: microtune_mt2050
        0x19: microtune_7102dt5
        0x20: microtune_7132dt5
        0x21: microtune_mt2060
        0x22: microtune_4039fr5
        0x23: microtune_4049fm5

        #LG
        0x30: taln_m200t # pal
        0x31: taln_h200t # ntsc
        0x32: taln_s200t # SECAM L/L' & PAL B/G, I/I, D/K

        0x60: samsung_tebn9282pk01a

      demodulator:
        0x00: not_present
        0x01:
          id: tda9885
          doc: pal/ntsc analog
        0x02:
          id: tda9886
          doc: pal/ntsc/secam analog
        0x03:
          id: tda9887
          doc: pal/ntsc/secam qss analog
        0x04: philips_saa7171
        0x10: conexant_cx24121
        0x15: phillips_tda8260tw
        0x16: zarlink_mt352
        0x17: lgdt3302
        0x18: micronas_drx3960a
      sat_dish_power_control_ic:
        0: not_present
        1:
          id: lnbp21
          doc: I2C Address 0x10
      ir_ctrl_mcu:
        0: not_present
        6: pic12f629
        7: pic12ce673
  gpio_assignment_table:
    doc: |
      The GPIO Assignment table creates a logical mapping of function-based usage names to physical GPIOs within the GPU. Each pin has
        a logical ON State and
        a logical OFF State.
      Each state can be distinctly defined physically via:
        Sending output high to the GPIO,
        Sending output low to the GPIO, or
        Tristating the GPIO (Setting it to Input Mode).
      Alternately, specific GPIOs can also be assigned to carry Pulse Width Modulated (PWM) signals. This can be used for fan speed control or backlight power control.
      This table is required in all ROMs. It must be listed inside every DCB. The VBIOS and the FCODE will use the data from this structure.
    seq:
      - id: header
        type: header
      - id: entries
        size: header.generic_table_header.entry_size
        type: entry
        repeat: expr
        repeat-expr: header.generic_table_header.entry_count
    instances:
      external_master_table:
        pos: header.data.external_master_table_header_ptr
        type: external_master_table
        if: header.data.external_master_table_header_ptr != 0
    types:
      header:
        doc: |
          When moving to GF110, the HW team merged the Normal/Alternate/Sequencer modes of the GPIO into one 8 bit field in a GPIO register. In order to better manage that change, we decided to increase the revision from the initial 0x40 version to 0x41 and re-organize the bit fields in each GPIO table entry to accommodate a new field that matches the field in the HW register directly.
          Version 0x41, as used for GF11x+ / Core75 and future cores, is listed below.
        seq:
          - id: generic_table_header
            type: generic_table_header
            doc: |
              version -> The current GPIO Assignment Table version is 4.1 or a value of 0x41 in this field. If this version is 0, then the driver will assume that this table is invalid.
              header_size -> For version 4.1 this is 6 bytes.
              entry_count -> Number of GPIO Assignment Table Entries starting directly after the end of this header.
              entry_size -> For version 4.0, this was 4 bytes. For version 4.1, this is now 5 bytes.
          - id: data
            type: data
            size: generic_table_header.rest_header_size
            if: generic_table_header.rest_header_size > 0
        types:
          data:
            seq:
              - id: external_master_table_header_ptr
                type: u2
                doc: Pointer to the External GPIO Assignment Master Table. This field can be set to 0 to indicate no support for this table.
      entry:
        doc: |
          Note: The presence of the GSYNC header can be positively determined by (1 == GSYNCRasterSync) for any non-skip entry or (1 == GSYNCFlipLock) for any non-skip entry.
        seq:
          - id: pin_number
            type: b6
            doc: The GPIO number associated with this entry. Older chips have a maximum of 9 GPIO pins. G80+ have 15 GPIOs in register space. This field must be 0 if the I/O Type field is set to NV_GPIO_IO_TYPE_DEDICATED_LOCK_PIN.
          - id: io_type
            type: b1
            doc: |
              The I/O Type field is used to specify if this entry represents an actual GPIO or instead represents a similar type of entity. This field is an enumeration that currently has the following values:
                0 = NV_GPIO_IO_TYPE_GPIO - This entry represents a normal internal GPIO.
                1 = NV_GPIO_IO_TYPE_DEDICATED_LOCK_PIN - This entry represents an internal dedicated lock pin. No actual GPIO is associated with the lock pin. The GPIO Number field must be set to zero.

          - id: initialize_pin_state
            type: b1
            doc: This field specifies the initial state to set the GPIO to during boot. If this bit is 0, then the software will initialize the GPIO at boot to the settings specified by "Off Data" and "Off Enable". If this bit is 1, then the software will initialize the GPIO at boot to the settings specified by "On Data" and "On Enable".
          - id: function
            type: u1
            enum: function
            doc: This lists the function of each GPIO pin.
          - id: output_hw_select
            type: u1
            enum: output_hw_select
            doc: Output hardware function setting
          - id: input_hw_select
            type: b5
            enum: input_hw_select
            doc: Input hardware function setting
          - id: gsync_header
            type: b1
            doc: |
              GSYNC Header Connection. Possible values are:
                0 - Not Connected
                1 - Connected
              RM is responsible for discerning Raster Sync or Flip Lock from the GPIO Function.
          - id: reserved
            type: b1
          - id: pulse_width_modulate
            type: b1
            doc: If this bit is 1, then this GPIO is used with PWM.
          - id: lock_pin_number
            type: b4
            doc: The lock pin number associated with this entry. In ISO designs there are currently four lock pins that are either assigned to GPIO pins or internal dedicated pins. This only applies to a subset of GPIO functions. Depending on the chip, some lock pins are done with real GPIO’s so they have a real GPIO number and the I/O Type Field is set to NV_GPIO_IO_TYPE_GPIO, while other lock pins do not have a real GPIO so they are set to NV_GPIO_IO_TYPE_DEDICATED_LOCK_PIN and the GPIO number is meaningless (but is always set to zero). This field must be 0xF for GPIO functions that do not involve a lock pin.
          - id: off_data
            type: b1
            doc: determines in what physcial data output must be present on the GPIO pin to indicate the logical OFF signal. If this bit is 0, then the software will set the GPIO pin to 0 when it wants to turn the function off.
          - id: off_enable
            type: b1
            doc: This field determines in which physical direction the GPIO should be placed when requesting the logical function to be OFF. If this bit is 0, then the GPIO will be set as an Output when OFF is requested. If this bit is a 1, then the GPIO will be set as an Input when OFF is requested.
          - id: on_data
            type: b1
            doc: This field determines what physical data output must be present on the GPIO pin to indicate the logical ON signal. If this bit is 0, then the software will set the GPIO pin to 0 when it wants to turn the function on.
          - id: on_enable
            type: b1
            doc: |
              This field determines in which physical direction the GPIO should be placed when requesting the logical function to be ON. If this bit is 0, then the GPIO will be set as an Output when ON is requested. If this bit is a 1, then the GPIO will be set as an Input when ON is requested.
              Note: Some GPIOs have some overloading with HW Slowdown features and the detected presence of a thermal chip. HW Slowdown consists of two parts:
                a. Enabling/Disabling the functionality through GPIO 8. (Note, this functionality is only available on NV18 and NV30+ chips.)
                b. Triggering GPIO 8 when the functionality is enabled. The trigger can come from a thermal device, external power connector, some logic on the board, a combination of the above, etc. The trigger method is what the GPIO function should define, but by defining it, we understand that we must enable HW slowdown (A) as well.
              Trigger or Assert implies that the GPIO 8 is brought LOW and since the functionality is enabled (A), the HW Clocks are reduced by 2x, 4x or 8x. The opposite of trigger/assert is deassert.
              In most cases today, HW Slowdown is set to ACTIVE LOW due to the ACTIVE LOW signal from the thermal chips. We can program GPIO 8 based HW Slowdown to be ACTIVE HIGH, but then the trigger level for the line routed to GPIO 8 must follow the ACTIVE HIGH signaling.
        enums:
          function:
            3:
              id: vsync
              doc: alternate vsync signal using gpio pin.

            4: voltage_select_bit0
            5: voltage_select_bit1
            6: voltage_select_bit2
            26: voltage_select_bit3
            115: voltage_select_bit4
            116: voltage_select_bit5
            117: voltage_select_bit6
            118: voltage_select_bit7
            27:
              id: voltage_select_default
              doc: Allow switching from default voltage (1) to selected voltage (0).

            7: hotplug_signal_a
            8: hotplug_signal_b
            81: hotplug_signal_c
            82: hotplug_signal_d
            94: hotplug_signal_e
            95: hotplug_signal_f
            96: hotplug_signal_g

            9:
              id: fan_control
              doc: Can be on or off, or pulse width modulation to control speed.

            40:
              id: dac_0_select
              doc: &dac_select_doc DAC mux that allows us to switch between using the CRT (Off state) or TV (On State) filters on the board.
            12:
              id: dac_1_select
              doc: *dac_select_doc
            13:
              id: dac_1_alternate_load_detect
              doc: When the DAC 1 is not currently switched to a device that needs detection, this GPIO pin can be used to detect the alternate load on the green channel.

            14:
              id: stereo_goggles_dac_select
              doc: Chooses which DAC to use for the stereo goggles.
            15:
              id: stereo_goggles_toggle
              doc: Switch between Left and Right eyes for the stereo goggles.

            #thermal
            16:
              id: thermal_and_external_power_event_detect
              doc: 'Sense bit when there’s a thermal event or the external power connector is connected or removed from the board. If attached to GPIO 8, assumes HW Slowdown enabled (A). If thermal device is not found, HW Slowdown is disabled (A). The logical diagram of this connection is by the link: /ThermalPower.gif'
            17:
              id: thermal_event_detect
              doc: Sense bit when there’s a thermal event sent from the thermal device. Same as above, but without the Power Connected signal. Specifically, the Thermal ASSERT is routed directly to GPIO 8.
            34:
              id: required_power_sense
              doc: Similar to 16, but without the thermal half. This version is similar to Thermal and External Power Detect, but without the Thermal ASSERT signal. Specifically, the Power Connected signal is routed directly to GPIO 8. The intention of the SW is to disable HW Slowdown (A) with this function.
            35:
              id: over_temp
              doc: This GPIO will assert when the GPU has reached some adjustable temperature threshold
            39:
              id: optional_power_sense
              doc: Similar to 16 and 34 with regards to HW Slowdown, but without the thermal half and not necessary for normal non-overclocked operation.
            44:
              id: disable_power_sense
              doc: If asserted, this GPIO will remove the power sense circuit from affecting HW Slowdown. Note that HW Slowdown enable/disable (A) is not affected by the usage of this functionality. This function exists only to change the trigger method (B) for HW Slowdown. /ThermalPowerDisable.gif

            52:
              id: thermal_alert
              doc: Interrupt input from external thermal device. Indicates that the device needs to be serviced.  Although we have other thermal inputs that are tied to GPIO8, these can be assigned to any GPIO, and can cover many different situations.
            53:
              id: thermal_critical
              doc: Comparator-driven input from external thermal device. Indicates that a temperature is above a critical limit.  Although we have other thermal inputs that are tied to GPIO8, these can be assigned to any GPIO, and can cover many different situations.
            61:
              id: fan_speed_sense
              doc: This GPIO will sense a fan’s tachometer output (on 4-wire fans). In the beginning, it will be more for sensing a stuck fan than determining speed. Later GPUs will be able to measure the fan’s speed internally from the GPIO.
            73:
              id: thermal_alert_output
              doc: Output signal that indicates to other board component(s) that the gpu’s internal temp has exceeded a certain threshold for a duration longer than a programmed interval.
            76:
              id: power_alert
              doc: when this GPIO asserts, the on-board power supply controller needs attention.
            121:
              id: external_power_emergency
              doc: This GPIO provides an input to let SW know when the GPU does not have enough power to initialize.
            123:
              id: fan_with_overtemp
              doc: denotes that the pin will be driven from PWM source that has capability to MAX duty cycle based on the thermal ALERT signal, as opposed to the already present "Fan" function which only outputs PWM. This PWM source is independent from the pwm source for "Fan" function.
            120:
              id: fan_failsafe_pwm
              doc: The functionality controls FAN fail safe PWM generator. If function is present in VBIOS, GPIO should be configured as normal output and initially asserted. Once RM is loaded and FAN control is successfully initialized RM will dessert this pin to allow FAN_PWM control.

            42:
              id: sw_performance_level_slowdown
              doc: When asserted, the SW will lower it’s performance level to the lowest state. This GPIO function will act as a trigger point for the SW to lower the clocks. HW Slowdown (A) is not enabled.
            43:
              id: hw_slowdown_enable
              doc: "This function strictly allows for an undefined trigger point to cause HW Slowdown. There is no requirement to have a thermal device present in order to use HW Slowdown as in the functions Thermal and External Power Detect (16) and Thermal Event Detect (17). On assertion HW will slowdown clocks (NVCLK, HOTCLK) using either _EXT_POWER, _EXT_ALERT or _EXT_OVERT settings (depends on GPIO configured: 12, 9 & 8 respectively). Than SW will take over, limit GPU p-state to battery level and disable slowdown. On deassertion SW will reenable slowdown and remove p-state limit. System will continue running full clocks."

            111:
              id: hw_only_slowdown_enable
              doc: On assertion HW will slowdown clocks (NVCLK, HOTCLK) using _EXT_POWER settings (use only with GPIO12). No software action will be taken. On deassertion HW will release clock slowdown.

            18:
              id: vtg_rst
              doc: Input Signal from daughter card for Frame Lock interface headers.
            41: framelock_daughter_card_interrupt

            19:
              id: suspend_state
              doc: Input requesting the suspend state be entered

            20:
              id: spread_bit0
              doc: Bit 0 of output to control Spread Spectrum if the chip isn’t I2C controlled.
            21:
              id: spread_bit1
              doc: Bit 1 of output to control Spread Spectrum if the chip isn’t I2C controlled.

            22:
              id: vds_frameid_bit0
              doc: Bit 0 of the frame ID when using Virtual Display Switching.
            23:
              id: vds_frameid_bit1
              doc: Bit 1 of the frame ID when using Virtual Display Switching.

            24:
              id: fbvddq_high_low
              doc: ON = High (i.e. 1.8V), OFF = Low (i.e. 1.5V)
            46:
              id: fbvref_select
              doc: ON = High FBVREF voltage (i.e. 70% FBVDDQ), OFF = Low FBVREF voltage (i.e. 50% FBVDDQ)

            25:
              id: customer
              doc: This function is here to be used by the OEM. It just reserves the GPIO so our software will know not to use it.


            28: tuner
            29: current_share
            30: current_share_enable

            36:
              id: hdtv_select
              doc: Allows selection of lines driven between SDTV - Off state, and HDTV - On State.
            37:
              id: hdtv_alt_detect
              doc: Allows detection of the connectors that are not selected by HDTV Select. That is, if HDTV Select is currently selecting SDTV, then this GPIO would allow us to detect the presence of the HDTV connection.
            45:
              id: rset_hdtv_select
              doc: Allows selecting between SDTV, On State, and HDTV, Off State, RSET values during TV detection.
            49:
              id: inquiry_for_hd_over_sd_tv_boot_preference
              doc: Allows user to select whether to boot to SDTV or component output by default.

            60:
              id: scart_svideo_composite_select
              doc: Allows selection of lines driven between SDTV (S-Video, Composite) and SDTV (SCART).

            69:
              id: scart_aspect_ratio_field_bit0
              doc: &scart_aspect_ratio_field_doc |
                0: 4:3(12V)
                1: 16:9(6V)
                2: Undefined
                3: SCART inactive (0 V)
            70:
              id: scart_aspect_ratio_field_bit_1
              doc: *scart_aspect_ratio_field_doc

            71:
              id: hd_dongle_strap_field_bit_0
              doc: &hd_dongle_strap_field_bit_doc GPIOs 71 and 72 define a 2 bit HD Dongle Strap Field. These two bits index into an array found at the HDTV Translation Table that will determine the default HD standard.
            72:
              id: hd_dongle_strap_field_bit_1
              doc: *hd_dongle_strap_field_bit_doc

            48:
              id: generic_initialized
              doc: This GPIO is used, but does not have a specific function assigned to it or has a function defined elsewhere. System software should initialize this GPIO using the _INIT values for the chip. This function should be specified when a GPIO needs to be set statically during initialization. This is different than function 25, which implies that the GPIO is not used by NVIDIA software.


            50:
              id: digital_encoder_interrupt_enable
              doc: For Si1930uC, a GPIO will be set ON to trigger interrupt to Si1930uC to enable I2C communication. When I2C transactions to the Si1930uC are complete, the drivers will set this GPIO to OFF.
            51:
              id: i2c_mode_select
              doc: Selects I2C communications between either DDC or I2C

            63:
              id: ext_sync_0
              doc: Used with external framelock with GSYNC products. It also could be used for raster lock.

            64: sli_raster_sync_a # This signal is carried across the SLI bus to synchronize the RG between GPUs. This signal will always be set as Alternate.
            65: sli_raster_sync_b # This signal is carried across the SLI bus to synchronize the RG between GPUs. This signal will always be set as Alternate. This signal is just the second GPIO that can be used for Raster sync from each GPU. It should only be defined when we have 2 pin sets being used on one board to allow more than two GPUs to run in SLI mode. One will be used with one pin set for input and the other will be used with the other pin set for output.

            66:
              id: swap_ready_in_a
              doc: &swap_ready_in_doc This signal, which is related to Fliplocking, is used to sense the state of the FET drain, which is pulled high and is connected to the Swap Ready pin on the Distributed Rendering connector.
            112:
              id: swap_ready_in_b
              doc: *swap_ready_in_doc
            67:
              id: swap_ready_out
              doc: This signal, which is related to Fliplocking, is used to drive the gate of an external FET.


            74:
              id: display_port_to_dvi_dongle_present_a
              doc: &display_port_to_dvi_dongle_present_doc when this GPIO asserts, we need to configure DisplayPort encoder to output TMDS signal.
            75:
              id: display_port_to_dvi_dongle_present_b
              doc: *display_port_to_dvi_dongle_present_doc
            83:
              id: display_port_to_dvi_dongle_present_c
              doc: *display_port_to_dvi_dongle_present_doc
            84:
              id: display_port_to_dvi_dongle_present_d
              doc: *display_port_to_dvi_dongle_present_doc

            77:
              id: dac_0_load_detect
              doc: When the DAC 0 is not currently switched to a device that needs detection, this GPIO pin can be used to detect the alternate display’s load on the green channel.
            78:
              id: analogix_encoder_external_reset
              doc: For Analogix encoder, a GPIO is used to control the RESET# line.
            79:
              id: i2c_scl_keeper_circuit_enable
              doc: This allows our GPU to properly communicate with the Analogix chip. The Analogix Encoder implements clock stretching in a manner that our SW emulated I2C cannot properly handle. To workaround this issue, a keeper circuit is added to detect slave issued stretches on the SCL and hold the SCL line. The keeper circuit is turned on and off at specific points during the I2C transaction. See {{Bug|273429}}. OFF = Normal operation (do nothing), ON = Enable the hardware to detect slave-issued stretches on the SCL line and hold SCL low.
            80:
              id: dvi_to_dac_connector_switch
              doc: This GPIO allows for DAC 0 (TV) to be selected to route to the DVI Connector when the GPIO is set to the logical OFF state. When the GPIO is set to logical ON state, DAC 1 (CRT) will be routed to the DVI connector.
            85:
              id: maxim_max6305_compatible_external_reset_controller
              doc: Enabled is Active Low so init value should be Active High [No inversions]

            87: spdif_input
            88: toslink_input
            89:
              id: spdif_toslink_select
              doc: When GPIO is set LOW, SPDIF is selected. When GPIO is set HI, TOSLINK is selected.

            90:
              id: dpaux_i2c_select_a
              doc: &dpaux_i2c_select_doc When this GPIO is set to Logical ON state, DPAUX will be selected. Logical OFF state selects I2C.
            91:
              id: dpaux_i2c_select_b
              doc: *dpaux_i2c_select_doc
            92:
              id: dpaux_i2c_select_c
              doc: *dpaux_i2c_select_doc
            93:
              id: dpaux_i2c_select_d
              doc: *dpaux_i2c_select_doc


            99:
              id: gpio_external_device_1_interrupt
              doc: Used to surface an interrupt from a GPIO external device
            106:
              id: switched_outputs
              doc: This GPIO is used by the switched outputs table. A switched outputs GPIO must be processed by the INIT_GPIO_ALL devinit opcode and set to its init state.
            107:
              id: customer_asyncronous_read_write
              doc: Allows a customer to use the GPIO for whatever purpose they want.

            # mxm_3_0_direct_gpio_*: Access to MXM 3.0 bus’s Direct GPIO*. Once the system has the MXM structure/GPIO Device structure which defines usage of Direct GPIO*, this GPU’s GPIO is the physical pin to take on any enabling/detection/disabling function defined in the MXM Output Device data structure with MXM Direct GPI*.
            108: mxm_3_0_direct_gpio0 # GPIO0 (pin 26)
            109: mxm_3_0_direct_gpio1 # GPIO1 (Pin 28)
            110: mxm_3_0_direct_gpio2 # GPIO2 (Pin 30)

            113: trigger_condition_for_pmu # Can either be triggered by system notify bit set in SBIOS postbox command register or an error entering into deep-idle.
            114: reserved_for_swap_ready_out_b

            119: lvds_fast_switch_mux


            122:
              id: nvvdd_psi
              doc: |
                The NVVDD Power State Indicator (PSI) signals the NVVDD power supply controller to switch to reduced phase operation (typically 1 or 2 phases) for efficiency in low power states. Here are the logical states:
                  ON state # Enable low power state (reduced phase operation)
                  OFF state # Disable low power state (all phase operation)


            128:
              id: smpbi_event_notification
              doc: Notifies the EC (or client of the SMBus Post Box Interface) of a pending GPU event requiring its attention.
            129:
              id: pwm_based_serial_vid_voltage_control_for_nvvdd

            86:
              id: active_display_in_sli_mode
              doc: Active display LED to indicate the GPU with active display in SLI mode.
            124:
              id: posted_gpu_led
              doc: to indicate the GPU that was POSTed by the SBIOS.
            131:
              id: sli_bridge_led_brightness
              doc: Allow SLI Bridge brightness adjustment via PWM. (Must have PWM set when this is selected.)
            132:
              id: cover_logo_led_brightness
              doc: Allow Cover LOGO brightness adjustment via PWM. (Must have PWM set when this is selected.)

            133:
              id: panel_self_refresh_frame_lock_a
              doc: This function is defined for Self-Refresh Panel. The SR panel will send the frame-lock interrupt to GPU to sync the raster frame signal.

            134:
              id: fb_clamp
              doc: This function is used to monitor the FB clamp signal driven by the Embedded Controller (EC) for JT memory self-refresh entry and exit.
            135:
              id: fb_clamp_toggle_request
              doc: This function is used to request the Embedded Controller (EC) to toggle the FB clamp signal.

            #LCDn corresponds to the LCDn defined in the LCD ID field in the Connector Table.
            0: lcd0_backlight_control
            1: lcd0_power_control
            2: lcd0_power_status
            31: lcd0_self_test
            32: lcd0_lamp_status
            33:
              id: lcd0_brightness
              doc: &lcd_brightness_doc Allow brightness adjustment via PWM. (Must have PWM set when this is selected.).

            138: lcd1_backlight_control
            139: lcd1_power_control
            140: lcd1_power_status
            141: lcd1_self_test
            142: lcd1_lamp_status
            143:
              id: lcd1_brightness
              doc: *lcd_brightness_doc

            144: lcd2_backlight_control
            145: lcd2_power_control
            146: lcd2_power_status
            147: lcd2_self_test
            148: lcd2_lamp_status
            149:
              id: lcd2_brightness
              doc: *lcd_brightness_doc

            150: lcd3_backlight_control
            151: lcd3_power_control
            152: lcd3_power_status
            153: lcd3_self_test
            154: lcd3_lamp_status
            155:
              id: lcd3_brightness
              doc: *lcd_brightness_doc

            156: lcd4_backlight_control
            157: lcd4_power_control
            158: lcd4_power_status
            159: lcd4_self_test
            160: lcd4_lamp_status
            161:
              id: lcd4_brightness
              doc: *lcd_brightness_doc

            162: lcd5_backlight_control
            163: lcd5_power_control
            164: lcd5_power_status
            165: lcd5_self_test
            166: lcd5_lamp_status
            167:
              id: lcd5_brightness
              doc: *lcd_brightness_doc

            168: lcd6_backlight_control
            169: lcd6_power_control
            170: lcd6_power_status
            171: lcd6_self_test
            172: lcd6_lamp_status
            173:
              id: lcd6_brightness
              doc: *lcd_brightness_doc

            174: lcd7_backlight_control
            175: lcd7_power_control
            176: lcd7_power_status
            177: lcd7_self_test
            178: lcd7_lamp_status
            179:
              id: lcd7_brightness
              doc: *lcd_brightness_doc

            10: reserved10
            11: reserved11
            38: reserved38
            47: reserved47
            54: reserved54
            55: reserved55
            56: reserved56
            57: reserved57
            58: reserved58
            59: reserved59
            62: reserved62
            68: reserved68
            125: reserved125
            126: reserved126
            127: reserved127
            130: reserved130
            136: reserved136
            137: reserved137
            180: reserved180

            0xFF:
              id: skip_entry
              doc: This allows for quick removal of an entry from the GPIO Assignment table.

          output_hw_select:
            0x00: normal
            0x40: raster_sync_0
            0x41: raster_sync_1
            0x42: raster_sync_2
            0x43: raster_sync_3
            0x48: stereo_0
            0x49: stereo_1
            0x4a: stereo_2
            0x4b: stereo_3
            0x50: swap_ready_out_0
            0x51: swap_ready_out_1
            0x52: swap_ready_out_2
            0x53: swap_ready_out_3
            0x58: thermal_overt
            0x59: fan_alert
            0x5a: thermal_load_step_0
            0x5b: thermal_load_step_1
            0x5c: pwm_output
            0x80: sor0_tmds_out_pwm
            0x81: sor0_tmds_out_pina
            0x82: sor0_tmds_out_pinb
            0x84: sor1_tmds_out_pwm
            0x85: sor1_tmds_out_pina
            0x86: sor1_tmds_out_pinb
            0x88: sor2_tmds_out_pwm
            0x89: sor2_tmds_out_pina
            0x8a: sor2_tmds_out_pinb
            0x8c: sor3_tmds_out_pwm
            0x8d: sor3_tmds_out_pina
            0x8e: sor3_tmds_out_pinb

          input_hw_select:
            0x00:
              id: none
              doc: No Input function needs to be programmed on the given pin. Note that 0 is not a valid input value in HW.
            0x01: aux_hpd_0
            0x02: aux_hpd_1
            0x03: aux_hpd_2
            0x04: aux_hpd_3
            0x05: aux_hpd_4
            0x06: aux_hpd_5
            0x07: aux_hpd_6
            0x09: raster_sync_0
            0x0a: raster_sync_1
            0x0b: raster_sync_2
            0x0c: raster_sync_3
            0x11: swap_ready_0
            0x12: swap_ready_1
            0x15: thermal_overtemp
            0x16: thermal_alert
            0x17: power_alert
            0x18: tach
      external_master_table:
        doc: |
          Some boards require extra control, since we don’t have enough internal GPIO pins to manage them. The board designers add an external chip that is used to control more GPIO pins on the board. Because we expect that there could be more than just one external GPIO controller on the board, we have separated the tables into Master and Specific. The Master table lists pointers to all the different external GPIO controllers on the board. The Specific Table lists the data associated with one controller on the board. A pointer to the External GPIO Assignment Master Table is found in the GPIO Assignment Table Header.
          The Master Table is made up of two parts: the Header and the Entries. The Entries follow immediately after the Header.
        seq:
          - id: header
            type: header
          - id: entries
            size: header.generic_table_header.entry_size
            type: entry
            repeat: expr
            repeat-expr: header.generic_table_header.entry_count
        types:
          entry:
            seq:
              - id: specific_table
                type: specific_table_ptr
            types:
              external_specific_table:
                seq:
                  - id: header
                    type: header
                  - id: type
                    type: u1
                    enum: type
                    doc: The actual chip used to control the GPIO pins.
                  - id: i2c_address
                    type: u1
                    doc: 7-bit I2C communication Address left shifted to bits 7:1, with a 0 in bit 0. This is the standard I2C address specification for SW.
                  - id: external_device_interrupt_number
                    type: b2
                    enum: external_device_interrupt_number
                    doc: This field gives the number of the external interrupt pin that is used to signal interrupt requests by this device.
                  - id: reserved0
                    type: b2
                  - id: external_communications_port
                    type: b1
                    doc: This field defines which communications port is used for this device. See the I2C Control Block Header for the listing of the Primary and Secondary Communication ports.
                  - id: reserved1
                    type: b3
              specific_table_ptr:
                seq:
                  - id: ptr
                    type: u2
                instances:
                  table:
                    io: _root._io
                    pos: ptr
                    type: external_specific_table

        enums:
          external_device_interrupt_number:
            0: no_interrupts
            1: gpio_expansion_1_interrupt
            2: reserved2
            3: reserved3

          type:
            0:
              id: unknown
              doc: Used to signify to skip an entire Specific Table.
            1:
              id: pca9555_personal_cinema_vivo
              doc: for 10-pin Personal Cinema VIVO pods
            2:
              id: adt7473
              doc: Automatic Fan Controller Chip. There are 3 physical fan controllers on this chip. To reference any of these, use the GPIO Number to differentiate each controller.
            3:
              id: cx25875
              doc: General Purpose Output pins
            4:
              id: pca9555_for_gpio_mxm_hdmi
              doc: pins on MXM external HDMI control
            5:
              id: pca9536_for_gpio_hdmi_dvi_mux
              doc: pins for HDMI/DVI Multiplexing
            6: pca9555_for_gpios
            7: pca9536_for_gpios
            8: pca9555_for_napoleon
            9: anx9805_for_gpios
            10: pic18f24k20_gpio_expander
          pca9555_personal_cinema_vivo:
            0:
              id: skip_entry
              doc: &gpio_assignment_table_skip_entry_doc This allows for quick removal of an entry from the GPIO Assignment table.
            1:
              id: dterm_line_1a
              doc: &dterm_line_doc used to control Japanese HDTV sets.
            2:
              id: config_480p576p
              doc: indicates whether the user desires 480p/576p support
            3:
              id: dterm_line_1b
              doc: *dterm_line_doc
            4:
              id: config_720p
              doc: indicates whether the user desires 720p support
            5:
              id: dterm_line_2a
              doc: *dterm_line_doc
            6:
              id: config_1080i
              doc: indicates whether the user desires 1080i support
            7:
              id: dterm_line_2b
              doc: *dterm_line_doc
            8:
              id: dterm_line_3a
              doc: *dterm_line_doc
            9:
              id: pod_load_det
              doc: used to detect connections to SDTV connectors
            10:
              id: dterm_line_3b
              doc: *dterm_line_doc
            11:
              id: pod_sel_2nd_dev
              doc: used to activate SDTV connectors
            12:
              id: dterm_sense
              doc: used to detect connections to Japanese HDTV connectors
            13: config_sdtv_not_component # indicates whether the user prefers SDTV or component output as the boot default.
            14:
              id: pod_locale_bit0
              doc: used to indicate the geopolitical locale of the POD design. See interpretation below.
            15:
              id: pod_locale_bit1
              doc: used to indicate the geopolitical locale of the POD design. See interpretation below.
          adt7473:
            0:
              id: skip_entry
              doc: *gpio_assignment_table_skip_entry_doc
            1:
              id: fancontrol
              doc: This GPIO will provide on, off, or on with PWM control. In addition, when set as an input, the fan controller will switch to automatic temperature-based fan control.
          cx25875:
            0:
              id: skip_entry
              doc: *gpio_assignment_table_skip_entry_doc
            1:
              id: scart_rgb
              doc: Used to control the TV output as Composite (low) or RGB format (high).
            2:
              id: scart_video_aspect
              doc: used to control ouput picture as 16x9 (low) or 4x3 (high).
          pca9555_for_gpio_mxm_hdmi:
            0:
              id: skip_entry
              doc: *gpio_assignment_table_skip_entry_doc
            1: digital_encoder_interrupt_enable # used to control I2C CLK line for SI1930 firmware update.
            2: si1930uc_programming # used to control SI1930 firmware update.
            3: si1930uc_reset # used to control reset signal of SI1930 uC.
          pca9536_for_gpio_hdmi_dvi_mux:
            0:
              id: skip_entry
              doc: *gpio_assignment_table_skip_entry_doc
            1:
              id: dvi_hdmi_select
              doc: controls whether the display data is routed to the DVI device or to the HDMI device.
            2:
              id: i2c_hdmi_enable
              doc: enables or disables the I2C bus for the HDMI device.
            3:
              id: i2c_dvi_enable
              doc: enables or disables the I2C bus for the DVI device.
          pca9555_9536_for_gpios:
            0:
              id: skip_entry
              doc: *gpio_assignment_table_skip_entry_doc
            1:
              id: output_device_control
              doc: Used for DDC Bus Expander or Mux control (Switched Outputs)

            5: japanese_d_connector_line_1
            6: japanese_d_connector_line_2
            7: japanese_d_connector_line_3
            8: japanese_d_connector_plug_insertion_detect
            9: japanese_d_connector_spare_line1
            10: japanese_d_connector_spare_line2
            11: japanese_d_connector_spare_line3

            12: voltage_select_bit0
            13: voltage_select_bit1
            14: voltage_select_bit2
            15: voltage_select_bit3
            16: voltage_select_bit4
            17: voltage_select_bit5
            18: voltage_select_bit6
            19: voltage_select_bit7

            31: lcd_self_test
            32: lcd_lamp_status

            36:
              id: hdtv_select
              doc: Allows selection of lines driven between SDTV (OFF state) and HDTV (ON state)
            37:
              id: hdtv_alt_detect
              doc: Allows detection of the connectors that are not selected by HDTV Select. That is, if HDTV Select is currently selecting SDTV, then this GPIO would allow us detect the presence of the HDTV connection.
          pca9555_for_napoleon:
            0:
              id: skip_entry
              doc: This allows for quick removal of an entry from the GPIO Assignment table.
            1: out_led_for_480_576i
            2: out_led_for_480_576p
            3: out_led_for_720p
            4: out_led_for_1080i
            5: out_led_for_1080p
            6: in_hdaudio_signal_detect
            7: in_spdif_0_coax_signal_detect
            8: in_spdif_1_header_signal_detect
            9:
              id: out_spdif_input_select
              doc: 0. Coax, 1. Header
            10:
              id: in_panic_button
              doc: Resets screen resolution to the lowest possible setting
            11:
              id: in_resolution_change_button
              doc: Changes the screen resolution to its next highest setting
          anx9805_for_gpios:
            0:
              id: skip_entry
              doc: *gpio_assignment_table_skip_entry_doc
            1:
              id: dp2dvi_dongle_bit_a
              doc: &dp2dvi_dongle_bit_doc This GPIO is used to detect DP2DVI dongle’s presence (input) and is associated with the Connector Table’s DP2DVI A (B, C, D) bit.
            2:
              id: dp2dvi_dongle_bit_b
              doc: *dp2dvi_dongle_bit_doc
            3:
              id: dp2dvi_dongle_bit_c
              doc: *dp2dvi_dongle_bit_doc
            4:
              id: dp2dvi_dongle_bit_d
              doc: *dp2dvi_dongle_bit_doc
          pic18f24k20_gpio_expander:
            0:
              id: skip_entry
              doc: *gpio_assignment_table_skip_entry_doc
            1:
              id: output_device_control
              doc: Used for DDC Bus Expander or Mux control (Switched Outputs).
  spread_spectrum_table:
    doc: |
      This table is not required in the ROM. This table only needs to be defined if the specific board requires spread spectrum. This table will be used by both the VBIOS and the driver.
    seq:
      - id: header
        type: header
      - id: entries
        size: header.generic_table_header.entry_size
        type: entry
        repeat: expr
        repeat-expr: header.generic_table_header.entry_count
    types:
      header:
        seq:
          - id: generic_table_header
            type: generic_table_header
            doc: |
              version -> The current Spread Spectrum Table is version with 4.1, a value of 0x41 for this field. If the version is 0, then this table will be considered invalid and the driver will not use spread spectrum.
              header_size -> Version 4.1 starts with 5 bytes.
              entry_count -> Number of Spread Spectrum Table Entries starting directly after the end of this table.
              entry_size -> Size of Each Entry in bytes. Version 4.1 are currently 2 bytes each.
          - id: data
            size: generic_table_header.rest_header_size
            type: data
            if: generic_table_header.rest_header_size > 0
        types:
          data:
            seq:
              - id: flags
                type: u1
                doc: Flags for Spread Spectrum, currently unused. All bits are reserved and set to 0.
      entry:
        doc: |
          Notes:
          The Frequency Delta and Type fields inside the Entry above are only used when VPLL Source is set to 3 (i.e., Self, PLL Internal Mechanism). When calculating the configuration for the VPLL’s own spread, Frequency Delta should be interpreted as delta from target frequency such that center spread has a bandwidth of
            (2 x SpreadSpectrumTableEntry.FrequencyDelta)
          and down spread has a bandwidth of
            (1 x SpreadSpectrumTableEntry.FrequencyDelta)
          The target modulation frequency is assumed to be 33 kHz.
        seq:
          - id: valid
            type: b1
            doc: Set if this is a valid entry. 0 = invalid and should be skipped, 1 = valid.
          - id: vpll_spread_source
            type: b2
            enum: vpll_spread_source
          - id: reserved0
            type: b1
            doc: Reserved, set as 0
          - id: dcb_index
            type: b4
            doc: This field lists the associated DCB Index device that should enable spread on VPLL while in use.
          - id: frequency_delta
            type: b6
            doc: Delta from target frequency in 0.05% units
          - id: spread_type
            type: b1
            doc: Spread profile type, 0 = center, 1 = down
          - id: reserved1
            type: b1
            doc: Reserved, set as 0
        enums:
          vpll_spread_source:
            0: reference_internal_0
            1: reference_internal_1
            2: reference_external
            3: self_pll_internal_mechanism
  i2c_devices_table:
    doc: |
      This table is not required in the ROM. This table only needs to be defined if the board requires some specific driver handling of an I2C device. This table will be used only by the the driver.
      Specifically, this table grew from the need to define various new I2C HW monitoring devices as well as HDTV chips.
    seq:
      - id: header
        type: header
      - id: entries
        size: header.generic_table_header.entry_size
        type: entry
        repeat: expr
        repeat-expr: header.generic_table_header.entry_count
    types:
      header:
        seq:
          - id: generic_table_header
            type: generic_table_header
            doc: |
              version -> The version will start with 4.0, a value of 0x40 here. If this version is 0, then the driver will consider this table as invalid and will not use any of the data present here.
              header_size -> Initially, this is 5 bytes.
              entry_count -> Number of I2C Device Table Entries starting directly after the end of this table.
              entry_size -> Version 4.0 starts with 4 bytes
          - id: flags
            type: flags
            size: generic_table_header.rest_header_size
            if: generic_table_header.rest_header_size > 0
      flags:
        seq:
          - id: disable_external_device_probing
            type: b1
            doc: The driver spends some time probing for external devices like the framelock, SDI boards, or Thermal devices not found in the thermal tables. This bit is added to notify the driver that probing isn’t required because the board doesn’t support it. If set to 0, probing will still occur as normal. If set to 1, it will disable the probing on the board.
          - id: reserved
            type: b7
      entry:
        seq:
          - id: type
            type: u1
            enum: type
            doc: Device (chip) type
          - id: i2c_address
            type: u1
            doc: 8-bit aligned, right shifted 7-bit address of the I2C device. The I2C spec defines 7 bits for the address [7:1] of the device with 1 bit for R/W [0:0]. So, generally, most addresses are listed in their 8 bit adjusted form with 0 for the R/W bit. This field must list that 8-bit adjusted address.
          - id: reserved0
            type: b4
            doc: set to 0
          - id: external_communications_port
            type: b1
            doc: This field defines which communications port is used for this device. See the I2C Control Block Header for the listing of the Primary and Secondary Communication ports.
          - id: write_access_privilege_level
            type: b3
            enum: write_access_privilege_level
            doc: This field defines the write access privileges to specific levels.
          - id: read_access_privilege_level
            type: b3
            doc: This field defines the read access privileges to specific levels.
            enum: read_access_privilege_level
          - id: reserved1
            type: b5
            doc: set to 0
        enums:
          type:
            0xFF:
              id: skip_entry
              doc: This allows for quick removal of an entry from the I2C Devices Table.

            #thermal chips
            0x01: thermal_chip_adm_1032
            0x02: thermal_chip_max_6649
            0x03: thermal_chip_lm99
            0x06: thermal_chip_max_1617
            0x07: thermal_chip_lm64
            0x0a: thermal_chip_adt7473
            0x0b: thermal_chip_lm89
            0x0c: thermal_chip_tmp411
            0x0d: thermal_chip_adt7461
            0x04: thermal_chip_deprecated04
            0x05: thermal_chip_deprecated05
            0x08: thermal_chip_deprecated08
            0x09: thermal_chip_deprecated09
            #I2C ANALOG TO DIGITAL CONVERTERS
            0x30: adc_ads1112
            #I2C POWER CONTROLLERS
            0xC0:
              id: i2c_power_pic16f690_mcu
              doc: deprecated on Fermi+
            0x40: i2c_power_vt1103
            0x41:
              id: i2c_power_px3540
              doc: Primarion PX3540 Digital Multiphase PWM Voltage Controller
            0x42: i2c_power_vt1165
            0x43:
              id: i2c_power_chil_chl82xx
              doc: 8203/8212/8213/8214
            0x44: i2c_power_ncp4208
            #SMBUS POWER CONTROLLERS
            0x48: smbus_power_chil_chl8112a_b_8225_8228
            0x49: smbus_power_chil_chl8266_8316
            0x4a: smbus_power_ds4424n
            0x4b: smbus_power_nct3933u
            #POWER SENSORS
            0x4c: power_ina219
            0x4d: power_ina209
            0x4e: power_ina3221
            #1 CLOCK GENERATORS
            0x50: clock_cypress_cy2xp304
            #GPIO CONTROLLERS
            0x60:
              id: gpio_philips_pca9555
              doc: device for EIAJ-4120 - Japanese HDTV support
            0x82:
              id: gpio_texas_instruments_pca9536
              doc: device for general-purpose remote I/O expansion
            #FAN CONTROLS
            0x70:
              id: fan_adt7473
              doc: dBCool Fan Controller
            0x71: fan_reserved71
            0x72: fan_reserved72
            #HDMI COMPOSITOR/CONVERTER DEVICES
            0x80:
              id: hdmi_si1930uc
              doc: Silicon Image Microcontroller SI1930uC device for HDMI Compositor/Converter
            #GPU I2CS CONTROLLERS
            0xB0: i2c_gt21x_gf10x
            0xB1: i2c_gf11x_and_beyond
            #DISPLAY ENCODER TYPES
            0xD0: display_encoder_anx9805
          write_access_privilege_level:
            0x0: reserved0
            0x1: reserved1
            0x2: reserved2
            0x3: reserved3
            0x4: reserved4
            0x5: reserved5
            0x6: reserved6
            0x7: reserved7
          read_access_privilege_level:
            0x0: reserved0
            0x1: reserved1
            0x2: reserved2
            0x3: reserved3
            0x4: reserved4
            0x5: reserved5
            0x6: reserved6
            0x7: reserved7
  connector_table:
    doc: |
      This table is required in the ROM. This table should always be defined to allow graphical representations of the board to be created. This table will be used only by the the driver.
      For purposes of this table a connector is defined as the end point on the display path where one display can be attached. This may be the card edge or attachment points on a breakout cable.
      A connector can only output one stream at a time. So, if you have a Low-Force Helix (LFH) port on the back of the card, the connector is defined as a DVI-I adapter of that breakout cable. That is, there are 2 connectors for every 1 LFH port on the back of a card.
      Notes: There are some connector types, 0x50 through 0x57, that require extra code in the detection routines inside any code that uses the DCB. For Mobile systems, some connectors might only be on the actual body of the notebook. Also, some connectors might only show up on the docking station. Therefore we need to make sure that we don’t allow anyone to select a device that is not actually present. So, when we see connectors with the "if not docked" and "if docked" text in the description, we must make sure that our detection code checks the docked condition first and possibly culls any further detection attempts if the docked condition is not met.
    seq:
      - id: header
        type: header
      - id: entries
        size: header.generic_table_header.entry_size
        type: entry
        repeat: expr
        repeat-expr: header.generic_table_header.entry_count
    types:
      header:
        seq:
          - id: generic_table_header
            type: generic_table_header
            doc: |
              version -> The Version will start with 4.0, a value of 0x40 here. If this version is 0, then the driver will consider this table as invalid and will not use any of the data present here.
              header_size -> Initially, this is 5 bytes.
              entry_count -> Number of Connector Table Entries starting directly after the end of this table header.
              entry_size -> Currently 4 bytes.
          - id: data
            size: generic_table_header.rest_header_size
            type: data
            if: generic_table_header.rest_header_size > 0
        types:
          data:
            seq:
              - id: platform
                type: u1
                enum: platform
                doc: This field specifies the layout of the connectors.
      entry:
        seq:
          - id: type
            type: u1
            doc: Connector Type
          - id: location
            type: b4
            doc: Physical location description. Specific locations depend on the platform type. The SW could define Real location as ((Platform Type << 4) | This Location Field) if it’s easier to deal with a single number rather than two separate lists. Generally, a value of 0 defines the South most connector, which is the connector on the bracket closest to the AGP/PCI connector. The specific values here are to be determined.
          - id: hotplug_interrupt_generation_a
            type: b1
            doc: This field dictates if this connector triggers the Hotplug A interrupt. If defined, then the Hotplug A interrupt must be defined inside the GPIO Assignment table.
          - id: hotplug_interrupt_generation_b
            type: b1
            doc: This field dictates if this connector triggers the Hotplug B interrupt. If defined, then the Hotplug B interrupt must be defined inside the GPIO Assignment table.
          - id: dp2dvi_a
            type: b1
            doc: This field indictates if this connector is connected to DP to DVI present A. If defined, then the DisplayPort to DVI dongle A present must be defined inside the GPIO Assignment table.
          - id: dp2dvi_b
            type: b1
            doc: This field indictates if this connector is connected to DP to DVI present B. If defined, then the DisplayPort to DVI dongle B present must be defined inside the GPIO Assignment table.
          - id: hotplug_interrupt_generation_c
            type: b1
            doc: This field dictates if this connector triggers the Hotplug C interrupt. If defined, then the Hotplug C interrupt must be defined inside the GPIO Assignment table.
          - id: hotplug_interrupt_generation_d
            type: b1
            doc: This field dictates if this connector triggers the Hotplug D interrupt. If defined, then the Hotplug D interrupt must be defined inside the GPIO Assignment table.
          - id: dp2dvi_c
            type: b1
            doc: This field indictates if this connector is connected to DP to DVI present C. If defined, then the DisplayPort to DVI dongle C present must be defined inside the GPIO Assignment table.
          - id: dp2dvi_d
            type: b1
            doc: This field indictates if this connector is connected to DP to DVI present D. If defined, then the DisplayPort to DVI dongle D present must be defined inside the GPIO Assignment table.
          - id: dpaux_i2c_select_a
            type: b1
            doc: This field indictates if this connector is connected to DPAUX/I2C select A. If defined, then the DPAUX/I2C select A must be defined inside the GPIO Assignment table.
          - id: dpaux_i2c_select_b
            type: b1
            doc: This field indictates if this connector is connected to DPAUX/I2C select B. If defined, then the DPAUX/I2C select B must be defined inside the GPIO Assignment table.
          - id: dpaux_i2c_select_c
            type: b1
            doc: This field indictates if this connector is connected to DPAUX/I2C select C. If defined, then the DPAUX/I2C select C must be defined inside the GPIO Assignment table.
          - id: dpaux_i2c_select_d
            type: b1
            doc: This field indictates if this connector is connected to DPAUX/I2C select D. If defined, then the DPAUX/I2C select D must be defined inside the GPIO Assignment table.
          - id: hotplug_interrupt_generation_e
            type: b1
            doc: This field dictates if this connector triggers the Hotplug E interrupt. If defined, then the Hotplug E interrupt must be defined inside the GPIO Assignment table.
          - id: hotplug_interrupt_generation_f
            type: b1
            doc: This field dictates if this connector triggers the Hotplug F interrupt. If defined, then the Hotplug F interrupt must be defined inside the GPIO Assignment table.
          - id: hotplug_interrupt_generation_g
            type: b1
            doc: This field dictates if this connector triggers the Hotplug G interrupt. If defined, then the Hotplug G interrupt must be defined inside the GPIO Assignment table.
          - id: panel_self_refresh_frame_lock_interrupt_a
            type: b1
            doc: This field dictates if this connector triggers the FrameLock A interrupt.
          - id: lcd_interrupt_gpio
            type: b3
            doc: This field dictates if this connector is connected to LCD# GPIO(s). If defined, then the LCD# GPIO(s) must be defined inside the GPIO Assignment table. LCD ID field only applies to the connector types listed below. All other types must set this field to 0. If defined, then the FrameLock A interrupt must be defined inside the GPIO Assignment table.
          - id: reserved
            type: b1
            doc: set to 0
        enums:
          type:
            0xFF:
              id: skip_entry
              doc: This allows for quick removal of an entry from the Connector Table.
            0x00: vga_15_pin
            0x01: dvi_a
            0x02: pod_vga_15_pin
            0x10: tv_composite_out
            0x11: tv_svideo_out
            0x12:
              id: tv_svideo_breakout_composite
              doc: Used for board that list 2 of the RGB bits in the TVDACs field
            0x13: tv_hdtv_component_yprpb
            0x14: tv_scart_connector
            0x16: tv_composite_scart_over_the_blue_channel_of_eiaj4120
            0x17: tv_hdtv_eiaj4120
            0x18: pod_hdtv_yprpb
            0x19: pod_svideo
            0x1a: pod_composite
            0x20: dvi_i_tv_svideo
            0x21: dvi_i_tv_composite
            0x22:
              id: dvi_i_tv_svideo_breakout_composite
              doc: Used for board that list 2 of the RGB bits in the TVDACs field
            0x30: dvi_i
            0x31: dvi_d
            0x32: apple_display_connector
            0x38: lfh_dvi_i_1
            0x39: lfh_dvi_i_2
            0x3c: bnc
            0x40: lvds_spwg_non_removeable
            0x41: lvds_oem_non_removeable
            0x42: lvds_spwg_removeable
            0x43: lvds_oem_removeable
            0x45: tmds_oem_non_removeable
            0x46:
              id: displayport_external_connector
              doc: as a special case, if the "Location" field is 0 and the "Platform" type in the Connector Table Header is 7 (Desktop with Integrated full DP), this indicates a non-eDP DisplayPort Internal Connector, which is non-removeable
            0x47: displayport_internal_connector_non_removeable
            0x48: displayport_mini_external_connector
            0x50: vga_15_pin_connector_not_docked
            0x51: vga_15_pin_connector_docked
            0x52: dvi_i_connector_not_docked
            0x53: dvi_i_connector_docked
            0x54: dvi_d_connector_not_docked
            0x55: dvi_d_connector_docked
            0x56: displayport_external_connector_not_docked
            0x57: displayport_external_connector_docked
            0x58: displayport_mini_external_connector_not_docked
            0x59: displayport_mini_external_connector_if_docked
            0x60: din_stereo_3_pin_connector
            0x61: hdmi_a_connector
            0x62: audio_spdif_connector
            0x63: hdmi_c_connector
            0x64: lfh_dp_1
            0x65: lfh_dp_2
            0x70: virtual_connector_for_wifi_display

    enums:
      platform:
        0x00: normal_add_in_card
        0x01:
          id: two_back_plate_add_in_cards
          doc: Used for tall fan sinks that cause adjacent PCI connection to be unusable
        0x02:
          id: configurable_add_in_card
          doc: All I2C ports need to be rescanned at boot for possible external device changes.
        0x07: desktop_with_integrated_full_dp
        0x08:
          id: mobile
          doc: Mobile Add-in Card. Generally have LVDS-SPWG connector on the north edge of the card away from the AGP/PCI bus.
        0x09: mxm_module
        0x10: mobile_with_all_displays_on_back
        0x11: mobile_with_all_connectors_on_back_and_left
        0x18: mobile_with_extra
        0x20:
          id: crush_normal
          doc: Crush (nForce chipset) normal back plate design
  hdtv_translation_table:
    seq:
      - id: header
        type: header
      - id: entries
        size: header.generic_table_header.entry_size
        type: entry
        repeat: expr
        repeat-expr: header.generic_table_header.entry_count
    types:
      header:
        seq:
          - id: generic_table_header
            type: generic_table_header
            doc: |
              version -> . The HDTV Translation Table version will start with 0 in this field.
              header_size -> Initially, this is 4 bytes.
              entry_count -> Number of HDTV Translation Table Entries starting directly after the end of this header.
              entry_size -> Initially, this is 1 byte.
          - id: extra_data
            size: generic_table_header.rest_header_size
            if: generic_table_header.rest_header_size > 0
      entry:
        seq:
          - id: hd_standard
            type: b4
          - id: reserved
            type: b4
        enums:
          hd_standard:
            0: hd576i
            1: hd480i
            2: hd480p_60
            3: hd576p_50
            4: hd720p_50
            5: hd720p_60
            6: hd1080i_50
            7: hd1080i_60
            8: hd1080p_24
  switched_outputs_table:
    doc: |
      There are new designs that allow to change the routing of device detection, selection, switching and I2C switching by way of a GPIO. This table assigns the relationship of the routing to specific DCB indices.
    seq:
      - id: header
        type: header
      - id: entries
        size: header.generic_table_header.entry_size
        type: entry
        repeat: expr
        repeat-expr: header.generic_table_header.entry_count
    types:
      header:
        seq:
          - id: generic_table_header
            type: generic_table_header
            doc: |
              version -> The Switched Outputs Table will version will start with 0x10 in this field.
              header_size -> Initially, this is 4 bytes.
              entry_count -> Number of HDTV Translation Table Entries starting directly after the end of this header.
              entry_size -> Initially, this is 5 bytes.
          - id: extra_data
            size: generic_table_header.rest_header_size
            if: generic_table_header.rest_header_size > 0
      entry:
        seq:
          - id: dcb_table_index
            type: b5
            doc: This index is used to determine which entry in the DCB table this Switched Output Table entry goes with.
          - id: reserved0
            type: b3
            doc: set to 0
          - id: selection
            type: gpio
          - id: detection_switching
            type: gpio
          - id: detection_load
            type: gpio
          - id: ddc_port_switching
            type: gpio

        types:
          gpio:
            seq:
              - id: type
                type: b1
                doc: |
                  This flag determines the location of the control for the GPIO that controls the feature. Defined values are:
                  0 = Internal GPIO or GPU controlled GPIO
                  1 = External GPIO
              - id: number
                type: b5
                doc: This field describes the GPIO number that controls the feature. If the value is set to 0x1F, then this functionality is not used. The
              - id: state
                type: b1
                doc: |
                  This flag tells the logical GPIO state in order to select or enable the associated DCB index for this entry. The physical logic here is found in the GPIO Assignment Table. Defined values are:
                    0 = Logical OFF state.
                    1 = Logical ON state.

              - id: reserved
                type: b1
                doc: set to 0
