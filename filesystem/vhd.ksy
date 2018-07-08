meta:
  id: vhd
  file-extension: vhd
  endian: be
  encoding: UTF-16
  title: Virtual Hard Disk Image Format
  application:
    - HyperV
    - Windows 7+
    - Virtual PC
  xrefs:
    forensicswiki: "Virtual_Hard_Disk_(VHD)"
    wikidata: Q1326659
    mime: application/x-vhd

doc: It's a file format used by Microsoft virtualization software
doc-ref: https://download.microsoft.com/download/f/f/e/ffef50a5-07dd-4cf8-aaa3-442c0673a029/Virtual%20Hard%20Disk%20Format%20Spec_10_18_06.doc
seq:
  - id: footer
    -orig-id: Copy of hard disk footer
    type: 'hardcode_header("conectix")'
  - id: header
    -orig-id: Dynamic Disk Header
    type: 'hardcode_header("cxsparse")'
instances:
  footer_copy:
    -orig-id: Hard Disk Footer
    pos: _io.size - footer._io.size
    size: footer._io.size
    #type: footer

types:
  uuid:
    seq:
      - id: uuid
        size: 16
  timestamp:
    seq:
      - id: ts_
        type: u4
    instances:
      offset:
        value: 946684800
        doc: "2000-01-01T00:00:00+00:00"
      value:
        value: 'ts_ + offset'
  version:
    seq:
      - id: minor
        type: u2
      - id: major
        type: u2
  header_container:
    seq:
      - id: signature
        -orig-id: Cookie
        type: str
        encoding: ascii
        size: 8
      - id: header
        type: header_selector(signature)
  hardcode_header:
    params:
      - id: signature
        -orig-id: Cookie
        type: str
        #encoding: ascii
    seq:
      - id: signature_
        contents: signature
      - id: header
        type: header_selector(signature)
  header_selector:
    params:
      - id: signature
        -orig-id: Cookie
        #size: 8
        type: str
        #encoding: ascii
    seq:
      - id: header
        type:
          switch-on: signature
          cases:
            '"conectix"': footer
            '"cxsparse"': header
  
    types:
      footer:
        seq:
          - id: features
            -orig-id: Features
            type: features
          - id: version
            -orig-id: File Format Version
            type: version
          - id: data_ptr
            -orig-id: Data Offset
            type: u8
          - id: timestamp
            -orig-id: Time Stamp
            type: timestamp
          - id: creator
            -orig-id: Creator Application
            size: 4
            type: str
            encoding: ascii
            doc: |
                - "vpc ": Microsoft Virtual PC
                - "vs  ": Microsoft Virtual Server
          - id: creator_version
            -orig-id: Creator Version
            type: version
          - id: creator_host_os
            -orig-id: Creator Host OS
            type: u4
            enum: os
          - id: original_size
            -orig-id: Original Size
            type: u8
          - id: current_size
            -orig-id: Current Size
            type: u8
          - id: geometry
            -orig-id: Disk Geometry
            type: geometry
          - id: type
            -orig-id: Disk Type
            type: u4
            enum: type
          - id: checksum
            -orig-id: Checksum
            type: u4
          - id: uuid
            -orig-id: Unique Id
            type: uuid
          - id: is_in_saved_state
            -orig-id: Saved State
            type: u1
          - id: reserved
            -orig-id: Reserved
            size: 427
        types:
          geometry:
            seq:
              - id: cylinder
                -orig-id: Cylinder
                type: u2
              - id: heads
                -orig-id: Heads
                type: u1
              - id: sectors
                -orig-id: Sectors per track/cylinder
                type: u1
          features:
            seq:
              - id: reserved0
                type: b6
              - id: reserved
                type: b1
                doc: "Must be true"
                #contents: true
              - id: temporary
                type: b1
              - id: reserved1
                type: b24
        enums:
          type:
            0:
              id: none
              -orig-id: None
            1:
              id: reserved1
              -orig-id: Reserved (deprecated)
            2:
              id: fixed
              -orig-id: Fixed hard disk
            3:
              id: differencing
              -orig-id: Differencing hard disk
            4:
              id: dynamic
              -orig-id: Dynamic hard disk
            5:
              id: reserved5
              -orig-id: Reserved (deprecated)
            6:
              id: reserved6
              -orig-id: Reserved (deprecated)
          os:
            0x5769326B: windows #"Wi2k"
            0x4D616320: macintosh #"Mac "
      header:
        seq:
          - id: next_struct_ptr
            -orig-id: Data Offset
            type: u8
          - id: block_allocation_table_ptr
            -orig-id: Table Offset
            type: u8
          - id: version
            -orig-id: Header Version
            type: version
          - id: block_count
            -orig-id: Max Table Entries
            type: u4
          - id: block_data_size
            -orig-id: Block Size
            type: u4
            -default: 0x00200000 # 2 MB
          - id: checksum
            -orig-id: Checksum
            type: u4
          - id: parent_uuid
            -orig-id: Parent Unique ID
            type: uuid
          - id: parent_timestamp
            -orig-id: Parent Time Stamp
            type: timestamp
          - id: reserved0
            -orig-id: Reserved
            type: u4
          - id: parent_file_name
            -orig-id: Parent Unicode Name
            type: strz
            #type: str
          - id: parent_locators
            -orig-id: Parent Locator Entry
            type: parent_locator
            repeat: expr
            repeat-expr: 8
          - id: reserved1
            -orig-id: Reserved
            size: 256
        instances:
          block_sector_size:
            value: 512
          next_struct:
            pos: next_struct_ptr
            io: _root._io
            type: header_container
            if: next_struct_ptr != 0XFFFFFFFFFFFFFFFF
          block_sectors_count:
            value: block_data_size/block_sector_size
          block_allocation_table:
            pos: block_allocation_table_ptr
            type: block_allocation_table
        types:
          parent_locator:
            seq:
              - id: code
                -orig-id: Platform Code
                type: u4
                enum: code
              - id: data_space
                -orig-id: Data Space
                type: u4
              - id: data_size
                -orig-id: Platform Data Length
                type: u4
              - id: reserved
                -orig-id: Reserved
                type: u4
              - id: data_offset
                -orig-id: Platform Data Offset
                type: u8
            enums:
              code:
                0:
                  id: none
                  -orig-id: None
                  doc: deprecated
                0x57693272:
                  id: win2k_relative
                  -orig-id: Wi2r
                  doc: deprecated
                0x5769326B:
                  id: win2k_absolute
                  -orig-id: Wi2k
                  doc: deprecated
                0x57327275:
                  id: win2k_relative_unicode
                  -orig-id: W2ru
                0x57326B75:
                  id: win2k_absolute_unicode
                  -orig-id: W2ku
                0x4D616320:
                  id: mac
                  -orig-id: Mac
                0x4D616358:
                  id: mac_x
                  -orig-id: MacX
          
          block_allocation_table:
            seq:
              - id: offsets
                type: block_ptr
                repeat: expr
                repeat-expr: _parent.block_count
            types:
              block_ptr:
                seq:
                  - id: ptr
                    type: u8
                instances:
                  used:
                    value: ptr != 0XFFFFFFFFFFFFFFFF
                  block:
                    pos: ptr
                    type: block
                    #size: _parent._parent.block_data_size #WTF
                    if: used
                types:
                  block:
                    seq:
                      - id: valid
                        -orig-id: bitmap
                        type: b1
                        repeat: expr
                        repeat-expr: _parent._parent._parent.block_sectors_count
                      - id: sectors
                        type: sector(_index)
                        repeat: expr
                        repeat-expr: _parent._parent._parent.block_sectors_count
                    types:
                      sector:
                        params:
                          - id: idx
                            type: u8
                        seq:
                          - id: data
                            size: _parent._parent._parent._parent.block_sector_size
                            #if: _parent.valid[idx] # BUG: contradicts the docs, it seems I have an error somewhere
