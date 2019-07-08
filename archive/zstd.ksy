meta:
  id: zstd
  title: ZStandard compression format
  file-extension: zst
  xref:
    mime: application/zstd
    rfc: 8478
    wikidata: Q26737171
  license: Unlicense
  endian: le
doc: |
  ZStandard compressed frame.
doc-ref:
  - https://github.com/facebook/zstd/blob/master/doc/zstd_compression_format.md
  - https://tools.ietf.org/html/rfc8478

seq:
  - id: frames
    type: frame
    repeat: eos
types:
  dyn_size_int:
    params:
      - id: size
        type: u1
    seq:
      - id: value
        type:
          switch-on: size
          cases:
            1: u1
            2: u2
            4: u4
            8: u8
  integer_float:
    seq:
      - id: exponent
        -orig-id: Exponent
        type: b5
      - id: mantissa
        -orig-id: Mantissa
        type: b3
    instances:
      log:
        value: 10 + exponent
      base:
        value: 1 << log
      add:
        value: (base / 8) * mantissa
      value:
        value: base + add
  frame:
    seq:
      - id: signature
        -orig-id: Magic_Number
        type: u4
      - id: frame_content
        type:
          switch-on: signature
          cases:
            0xFD2FB528: zstd_frame
            0xEC30A437: zstd_dict
            0x184D2A50: lz4_skippable_frame
            0x184D2A51: lz4_skippable_frame
            0x184D2A52: lz4_skippable_frame
            0x184D2A53: lz4_skippable_frame
            0x184D2A54: lz4_skippable_frame
            0x184D2A55: lz4_skippable_frame
            0x184D2A56: lz4_skippable_frame
            0x184D2A57: lz4_skippable_frame
            0x184D2A58: lz4_skippable_frame
            0x184D2A59: lz4_skippable_frame
            0x184D2A5A: lz4_skippable_frame
            0x184D2A5B: lz4_skippable_frame
            0x184D2A5C: lz4_skippable_frame
            0x184D2A5D: lz4_skippable_frame
            0x184D2A5E: lz4_skippable_frame
            0x184D2A5F: lz4_skippable_frame
  lz4_skippable_frame:
    # TODO: move into a separate file
    doc-ref: https://www.lz4.org
    seq:
      - id: size
        type: u4
      - id: data
        size: size
  zstd_frame:
    seq:
      - id: header
        type: header
        -orig-id: Frame_Header
      - id: data
        type: data_block
        -orig-id: Data_Block
        repeat: expr
        repeat-expr: header.
      - id: checksum
        type: u4
        -orig-id: Content_Checksum
        if: header.flags.has_checksum
    types:
      header:
        seq:
          - id: flags
            -orig-id: Frame_Header_Descriptor
            type: flags
          - id: window_descriptor
            -orig-id: Window_Descriptor
            type: integer_float
            if: not flags.is_single_segment
          - id: dictionary_id
            type: dyn_size_int(flags.dictionary_id_size)
            -orig-id: Dictionary_ID
          - id: decompressed_size
            -orig-id: Frame_Content_Size
            type: dyn_size_int(flags.frame_content_size_size)
        types:
          flags:
            -orig-id: Frame_Header_Descriptor
            seq:
              - id: frame_content_size_size_log2
                type: b2
                -orig-id: Frame_Content_Size_flag
              - id: is_single_segment
                type: b1
                -orig-id: Single_Segment_flag
              - id: unused
                type: b1
                -orig-id: Unused_bit
                doc: currently ignored
              - id: reserved_bit
                type: b1
                -orig-id: Reserved_bit
                doc: MUST BE 0
              - id: has_checksum
                type: b1
                -orig-id: Content_Checksum_flag
              - id: dictionary_id_size
                type: b2
                -orig-id: Dictionary_ID_flag
            instances:
              frame_content_size_size:
                value: 1 << frame_content_size_size_log2 # when 0 may be 0
      block:
        seq:
          - id: header
            type: header
            -orig-id: Block_Header
          - id: content
            type:
              switch-on: header.type
              cases:
                block_type::raw: raw_block
                block_type::rle:
                block_type::compressed:
            -orig-id: Block_Content
        types:
          header:
            seq:
              - id: is_last
                type: b1
              - id: type
                type: b2
                enum: block_type
              - id: size_low
                type: b5
              - id: size_rest
                type: u2
            instances:
              size:
                value: size_rest << 5 | size_low
            enums:
              block_type:
                0:
                  id: raw
                  -orig-id: Raw_Block
                1:
                  id: rle
                  -orig-id: RLE_Block
                2:
                  id: compressed
                  -orig-id: Compressed_Block
                3:
                  id: reserved
                  -orig-id: Reserved
          raw_block:
            seq:
              - id: data
                size: _parent.header.size
          rle_block:
            seq:
              - id: data
                type: u1
                doc: _parent.header.size times
          compressed_block:
            seq:
              - id: literals
                type: literals
              - id: sequences
                type: sequences
            types:
              literals:
                seq:
                  - id: header
                    type: header
                    -orig-id: Literals_Section_Header
                  - id: huffman_tree_description
                    type:
                    -orig-id: Huffman_Tree_Description
                  - id: jump_table
                    type:
                    -orig-id: jumpTable
                    if: header.stream_count == 4 and header.type == type::compressed
                  - id: streams
                    type:
                      switch-on: header.type
                      cases:
                        type::raw: rest_raw_rle(size_format_0)
                        type::rle: rest_raw_rle(size_format_0)
                        type::compressed: rest_raw_rle(size_format_0)
                        type::treeless: rest_raw_rle(size_format_0)

                    -orig-id: Stream#
                    repeat: expr
                    repeat-expr: header.stream_count
                types:
                  header:
                    seq:
                      - id: type
                        type: b2
                        enum: type
                      - id: size_format_0
                        type: b1
                      - id: rest
                        type:
                          switch-on: type
                          cases:
                            type::raw: rest_raw_rle(size_format_0)
                            type::rle: rest_raw_rle(size_format_0)
                            _: rest_compressed_treeless(size_format_0)
                    instances:
                      stream_count:
                        value: rest.stream_count
                      regenerated_size:
                        value: rest.regenerated_size
                      compressed_size:
                        value: rest.compressed_size
                    types:
                      ## WARNING, BUG, TODO: values are LE! But I have not verified the correctness yet
                      rest_raw_rle:
                        params:
                          - id: size_format_0
                            type: b1
                        seq:
                          - id: size_format_1
                            type: b1
                          - id: sizes
                            type:
                              switch-on: full_size_format
                              cases:
                                0b00: b5  # Literals_Section_Header[0]>>3`
                                0b10: b5
                                0b01: b12 # `Regenerated_Size = (Literals_Section_Header[0]>>4) + (Literals_Section_Header[1]<<4)`
                                0b11: b20 # (Literals_Section_Header[0]>>4) + (Literals_Section_Header[1]<<4) + (Literals_Section_Header[2]<<12)
                        instances:
                          full_size_format:
                            value: size_format_0.to_i << 1 | size_format_1.to_i
                          stream_count:
                            value: 1
                      rest_compressed_treeless:
                        params:
                          - id: size_format_0
                            type: b1
                        seq:
                          - id: size_format_1
                            type: b1
                          - id: sizes
                            type:
                              switch-on: full_size_format
                              cases:
                                0b00: size_format_0x
                                0b01: size_format_0x
                                0b10: size_format_10
                                0b11: size_format_11
                        instances:
                          full_size_format:
                            value: size_format_0.to_i << 1 | size_format_1.to_i
                          stream_count:
                            value: 'full_size_format == 0b00 ? 1 : 4'
                          regenerated_size:
                            value: sizes.regenerated_size
                          compressed_size:
                            value: sizes.compressed_size
                        types:
                          size_format_0x:
                            seq:
                              - id: regenerated_size
                                type: b10
                              - id: compressed_size
                                type: b10
                          size_format_10:
                            seq:
                              - id: regenerated_size
                                type: b14
                              - id: compressed_size
                                type: b14
                          size_format_11:
                            seq:
                              - id: regenerated_size
                                type: b18
                              - id: compressed_size
                                type: b18
                  raw_literals_block:
                    seq:
                      - id: data
                        size: _parent.header.regenerated_size
                  rle_literals_block:
                    seq:
                      - id: data
                        size: 1
                  huffman_literals_block:
                    seq:

                enums:
                  type:
                    0:
                      id: raw
                      -orig-id: Raw_Literals_Block
                    1:
                      id: rle
                      -orig-id: RLE_Literals_Block
                    2:
                      id: compressed
                      -orig-id: Compressed_Literals_Block
                    3:
                      id: treeless
                      -orig-id: Treeless_Literals_Block
  zstd_dictionary:
    seq:
      - id: id
        type: u4
        -orig-id: Dictionary_ID
      - id: entropy_tables
        -orig-id: Entropy_Tables
      - id: content
        -orig-id: Content

