meta:
  id: cab
  title: Microsoft Cabinet Format
  file-extension: cab
  endian: le
  encoding: "UTF-8"
doc: |
  ????
doc-ref:
  - "https://go.microsoft.com/fwlink/?LinkId=226293"
  - "https://docs.microsoft.com/en-us/previous-versions/bb417343(v=msdn.10)"
  - "https://download.microsoft.com/download/4/d/a/4da14f27-b4ef-4170-a6e6-5b1ef85b1baa/[ms-cab].pdf"
seq:
  - id: signature
    contents: ["MSCF"]
  - id: reserved1
    type: u4
  - id: cab_size
    -orig-id: cbCabinet
    type: u4

  - id: reserved2
    type: u4

  - id: files_array_offset
    -orig-id: coffFiles
    type: u4

  - id: reserved3
    type: u4

  - id: version
    type: version

  - id: folders_count
    -orig-id: cFolders
    type: u2
  - id: files_count
    -orig-id: cFiles
    type: u2

  - id: flags
    type: cfheader_flags

  - id: set_id
    type: u2
  - id: index_in_set
    -orig-id: iCabinet
    type: u2

  - id: reserved_area_for_extensions
    type: extension_block
    if: flags.reserve_present

  - id: prev_cab
    type: adjacent_cab
    if: flags.prev_cabinet
  - id: next_cab
    type: adjacent_cab
    if:   flags.next_cabinet

  - id: folders
    type: cffolder
    repeat: expr
    repeat-expr: folders_count

instances:
  files:
    pos: files_array_offset
    type: cffile
    repeat: expr
    repeat-expr: files_count

types:
  date:
    seq:
      - id: value
        type: u2
    instances:
      year:
        type: u2
        value: value >> 9
      month:
        type: u1
        value: value >> 5 & 0b00000001111
      day:
        type: u1
        value: value & 0b0000000000011111
  time:
    seq:
      - id: value
        type: u2
    instances:
      hour:
        type: u2
        value: value >> 11
      minute:
        type: u1
        value: value >> 5 & 0b00000111111
      seconds:
        type: u1
        value: (value & 0b0000000000011111) << 1

  cfheader_flags:
    seq:
      - id: reserve_present # 0x0004
        type: b1
      - id: next_cabinet # 0x0002
        type: b1
      - id: prev_cabinet # 0x0001
        type: b1
      - id: reserved
        type: b13
  version:
    doc: file format version
    seq:
      - id: minor
        type: u1
      - id: major
        type: u1
  adjacent_cab:
    seq:
      - id: file_name
        -orig-id: ["szCabinetNext", "szCabinetPrev"]
        type: strz
      - id: disc_description
        type: strz
  extension_block:
    seq:
      - id: per_cab_size
        -orig-id: cbCFHeader
        type: u2
      - id: per_folder_size
        -orig-id: cbCFFolder
        type: u1
      - id: per_datablock_size
        -orig-id: cbCFData
        type: u1
      - id: per_cab_reserved
        -orig-id: abReserve
        size: per_cab_size

  cfdata:
    seq:
      - id: checksum
        -orig-id: csum
        type: u4

      - id: compressed_size
        -orig-id: cbData
        type: u2

      - id: uncompressed_size
        type: u2

      - id: per_datablock_reserved
        size: cfheader.cbCFData
        if: cfheader.flags.reserve_present

      - id: data
        -orig-id: ab
        size: compressed_size
  compression_method:
    seq:
      - id: major
        type: u1
        enum: major
      - id: minor
        type: u1
    enums:
      major:
        0: none
        1: ms_zip
        2: quantum
        3: lzx
  cffolder:
    seq:
      - id: data_blocks_offset
        -orig-id: coffCabStart
        type: u4
      - id: data_blocks_count
        -orig-id: cCFData
        type: u2
      - id: compression_method
        -orig-id: typeCompress
        type: u2
      - id: per_folder_reserved
        size: cfheader.cbCFFolder
        if: cfheader.flags.reserve_present
    instances:
      data:
        type: cfdata
        pos: data_blocks_offset
        repeat: expr
        repeat-expr: data_blocks_count
      compression_method_major:
        type: cfdata
        pos: data_blocks_offset
        repeat: expr
        repeat-expr: data_blocks_count
  file_attribs:
    seq:
      - id: name_is_utf #0x80
        type: b1
      - id: execute #0x40
        type: b1
      - id: archive #0x20
        type: b1
      - id: system #0x04
        type: b1
      - id: hidden #0x02
        type: b1
      - id: read_only #0x01
        type: b1
      - id: reserved
        type: b1

  cffile:
    seq:
      - id: size
        -orig-id: cbFile
        type: u4
      - id: offset
        -orig-id: uoffFolderStart
        type: u4
      - id: folder_index
        -orig-id: iFolder
        type: u2
        enum: ifold_continued
      - id: date
        type: date
      - id: time
        type: time
      - id: attribs
        type: file_attribs
      - id: name
        -orig-id: szName
        type: strz
    enums:
      ifold_continued:
        0xFFFD:
          id: continued_from_prev
        0xFFFE:
          id: continued_to_next
        0xFFFF:
          id: continued_prev_and_next
