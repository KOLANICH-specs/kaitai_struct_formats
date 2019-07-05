meta:
  id: tcl_cookfs
  title: Tcl cookfs
  application: tcl
  file-extension: cfs
  endian: be
  encoding: utf-8

doc: |
  A Tcl virtual file system for archivation

doc-ref:
  - https://sourceforge.net/p/cookit/code/HEAD/tree/cookfs/generic/cookfs.c
  - https://tclcommunityassociation.org/wub/proceedings/Proceedings-2010/WojciechKocjan/Cookfs-Paper/Cookfs-Paper.pdf



instances:
  directory_marker_count_of_blocks:
    value: 0xFFFFFFFF
    -orig-id: COOKFS_NUMBLOCKS_DIRECTORY
types:
  cookfs_signature:
    seq:
      - id: cfs
        contents: ["CFS"]
  index_suffix:
    seq:
      - id: index_length
        -orig-id: indexLength
        type: u4
      - id: page_count
        -orig-id: pageCount
        type: u4
      - id: default_compression
        type: u1
        enum: compression
        -orig-id: compression
      - id: cfs_signature
        type: cookfs_signature
      - id: signature
        contents: ["0002"]
        -orig-id: "rc->fileSignature"
    instances:
      index_full_size:
        value: (page_count * (16 + 4)) + index_length # BUG in KSC? cannot access the types. index_t.md5.size=16, index_t.page_size.size=4
      index_pos:
        value: _io.pos - index_full_size
      index:
        pos: index_pos
        size: index_full_size
        type: index_t
      #data_initial_offset:
      #  value: "(index_pos - index.pages_sizes[index.pages_sizes.size-1].cumulative.to_i).to_i" # todo: check
      #  -orig-id: dataInitialOffset
      data_initial_offset:
        value: 0
        -orig-id: dataInitialOffset
    types:
      index_t:
        seq:
          - id: checksums
            type: md5
            repeat: expr
            repeat-expr: _parent.as<index_suffix>.page_count
          - id: pages_sizes
            type: page_size(_index)
            repeat: expr
            repeat-expr: _parent.as<index_suffix>.page_count
          - id: index
            size: _parent.as<index_suffix>.index_length
        types:
          md5:
            seq:
              - id: value
                size: 16
          page_size:
            params:
              - id: idx
                type: u4
            seq:
              - id: size
                type: u4
                -orig-id: "dataPagesSize[idx]"
            instances:
              cumulative:
                value: "(idx == 0? 0 : _parent.as<index_t>.pages_sizes[idx-1].cumulative.as<u4>) + size"
              offset:
                value: "(_parent.as<index_t>._parent.as<index_suffix>.data_initial_offset + cumulative)"
              page:
                pos: offset
                type: page
            types:
              page:
                seq:
                  - id: compression
                    type: u1
                    enum: compression
                  - id: data_processed
                    #size: _parent.size
                    type:
                      switch-on: compression
                      cases:
                        "compression::bzip2": decompressed_bzip
                        "compression::zlib": decompressed_zlib
                        _: uncompressed
                types:
                  uncompressed:
                    seq:
                      - id: value
                        size: _parent.as<page>._parent.as<page_size>.size
                  decompressed_bzip:
                    seq:
                      - id: value
                        size: _parent.as<page>._parent.as<page_size>.size
                        process: bzip2
                  decompressed_zlib:
                    seq:
                      - id: value
                        size: _parent.as<page>._parent.as<page_size>.size
                        process: deflate
  file_index:
    seq:
      - id: cfs_signature
        type: cookfs_signature
      - id: signature
        contents: ["2.200"]
        -orig-id: COOKFS_FSINDEX_HEADERSTRING
      - id: root
        type: directory
      - id: metadata
        type: metadata
    types:
      metadata:
        seq:
          - id: count
            type: u4
          - id: items
            type: item
            repeat: expr
            repeat-expr: count
        types:
          item:
            seq:
              - id: size
                type: u4
              - id: payload
                size: size
                type: key_value_pair
            types:
              key_value_pair:
                seq:
                  - id: key
                    -orig-id: paramName
                    type: strz
                  - id: value
                    size-eos: true
      directory:
        seq:
          - id: count
            type: u4
            -orig-id: childCount
          - id: files
            type: file
            repeat: expr
            repeat-expr: count
      file:
        seq:
          - id: file_name_length
            type: u1
            -orig-id: fileNameLength
          - id: file_name
            type: strz
            size: file_name_length
            -orig-id: fileName
          - id: modification_time
            type: u8
            -orig-id: fileTime
          - id: blocks_count
            type: u4
            -orig_id: fileBlocks
          - id: payload
            type:
              switch-on: is_directory
              cases:
                true: directory
                false: just_file
        instances:
          is_directory:
            value: blocks_count == _root.directory_marker_count_of_blocks
        types:
          just_file:
            seq:
              - id: descriptors
                type: block_descriptor
                -orig-id: "itemNode->data.fileInfo.fileBlockOffsetSize"
                repeat: expr
                repeat-expr: _parent.as<file>.blocks_count
            types:
              block_descriptor:
                doc: "aka `block-offset-size` triplet"
                seq:
                  - id: block
                    type: u4
                    -orig-id: "fileBlockOffsetSize[i*3 + 0]"
                  - id: offset
                    type: u4
                    -orig-id: "fileBlockOffsetSize[i*3 + 1]"
                  - id: size
                    type: u4
                    -orig-id: "fileBlockOffsetSize[i*3 + 2]"
                    doc: "size of the block. `fileSize` is the sum of all these sizes"

enums:
  compression:
    0x00:
      id: none
    0x01:
      id: zlib
    0x02:
      id: bzip2
    0xFF:
      id: custom
