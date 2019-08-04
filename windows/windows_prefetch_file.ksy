meta:
  id: windows_prefetch_file
  title: Windows Prefetch File 
  application: Microsoft Windows Prefetcher
  file-extension: pf
  xref:
    forensicswiki: Windows_Prefetch_File_Format
    wikidata: Q4047325
  license: GFDL-1.0
  endian: le
  encoding: utf-16le

doc: |
  Windows Prefetcher service collects info about apps launches to optimize their startup.

doc-ref:
  - https://github.com/libyal/libscca/blob/master/documentation/Windows%20Prefetch%20File%20(PF)%20format.asciidoc

types:
  ntfs_file_reference:
    seq:
      - id: mft_entry_index
        size: 6
      - id: sequence_number
        type: u2
  string_descriptor:
    seq:
      - id: offset
        type: u4
      - id: length_minus_one
        type: u4
        doc: Does not include the end-of-string character
    instances:
      value:
        pos: offset
        size: "(length_minus_one + 1) * 2"
        type: strz
  
  string_descriptor_size_only:
    seq:
      - id: length_minus_one
        type: u2
        doc: Does not include the end-of-string character
      - id: value
        type: strz
        size: "(length_minus_one + 1) * 2"
        
  
  compressed_header:
    seq:
      - id: signature
        contents: ["MAM"]
      - id: flags
        type: flags
      - id: uncompressed_size
        type: u4
    types:
      flags:
        seq:
          - id: checksum_present # ?
            type: b1
          - id: unkn0
            type: b4
          - id: unkn1
            type: b1
            doc: "usually set"
          - id: unkn0
            type: b2
  uncompressed_header:
    seq:
      - id: format_version
        type: u4
        enum: version
      - id: Signature
        contents: ["SCCA"]
      - id: unkn0
        type: u4
      - id: file_size
        type: u4
      - id: executable_filename
        type: strz
        size: 60
        encoding: utf-16le
        doc: |
          The executable filename will store a maximum of 29 characters. Dependent on the Windows version the unused bytes of the executable filename can contain remnant data. Windows 8.1 seems to fill the unused bytes with 0-byte values.
      - id: prefetch_hash
        type: u4
        doc: the same as in the file name
      - id: flags
        type: flags
    types:
      flags:
        seq:
          - id: unkn0
            type: b7
          - id: boot
            type: b1
          - id: unkn1
            type: b24
    enums:
      version:
        16: win_2k
        17: win_xp_2003
        23: win_vista_7
        26: win_8
        30: win_10
  
  file_information:
    seq:
      - id: metrics_offset
        type: u4
      - id: metrics_count
        type: u4
      - id: trace_chains_offset
        type: u4
      - id: trace_chains_count
        type: u4
      - id: filename_strings_offset
        type: u4
      - id: filename_strings_size
        type: u4
      - id: volumes_information_offset
        type: u4
      - id: volumes_count
        type: u4
      - id: volumes_information_size
        type: u4
      - id: unkn0
        size: 8
        if: version >= 23
      - id: last_run_times
        type: u8
        repeat: expr
        repeat-expr: "(version < 24 ? 1 : 8)"
      - id: unkn0
        size: "(16 ? version < 30 : 8)"
      - id: run_count
        type: u4
      - id: unkn1
        type: u4
      - id: unkn2
        type: u4
        if: version >= 23
      - id: unkn3
        type: u4
        if: version >= 30
      - id: unkn4
        size: 76
        if: version >= 23
      - id: unkn5
        size: 12
        if: version >= 26

  metric:
    seq:
      - id: unkn0
        type: u4
        doc: |
          Prefetch start time in ms?
          Could be the index into the trace chain array as well, is this relationship implicit or explicit?
      - id: unkn1
        type: u4
      - id: unkn2
        type: u4
        doc: average prefetch duration in ms?
      - id: unkn2
        type: u4
        doc: |
          Prefetch duration in ms? 
          Could be the number of entries in the trace chain as well, is this relationship implicit or explicit?
      - id: Filename
        type: string_descriptor
      - id: unkn3
        type: u4
        doc: flags? Seen: 0x00000001, 0x00000002, 0x00000003, 0x00000200, 0x00000202
      - id: file_reference
        type: ntfs_file_reference
        if: version >= 24
  trace_chain:
    doc: |
      A trace chain is similar to a File Allocation Table (FAT) chain where the array entries form chains and -1 (0xffffffff) is used to mark the end-of-chain. The chains in the trace chains array correspond with the entries in the file metrics array, meaning the first trace chain relates to the first file metrics array entry.
    seq:
      - id: next_idx
        type: u4
        doc: Contains the next trace chain array entry index in the chain, where the first entry index starts with 0, or -1 (0xffffffff) for the end-of-chain.
        if: version < 30
      - id: total_block_load_count
        type: u4
        doc: Total number of blocks loaded (or fetched). The block size 512k (512 x 1024) bytes
      - id: flags
        type: u1
        doc: Seen: 0x02, 0x03, 0x04, 0x08, 0x0a
      - id: unkn0
        type: u1
        doc: Sample duration in ms? seen 1
      - id: unkn1
        type: s2
        doc: seen 0x0001, 0xffff, etc.

  volume_information:
    seq:
      - id: device_path
        type: string_descriptor
        doc: relative from the start of the volume information
      - id: creation_time
        type: u8
      - id: serial_number
        type: u4
      - id: file_references_offset
        type: u4
      - id: file_references_data_size
        type: u4
      - id: directory_strings_offset
        type: u4
      - id: directory_strings_count
        type: u4
      - id: unkn0
        type: u4
        doc: Does this value relate to the remnant data in the file references array?
      - id: unkn1
        size: 24
        if: version >= 23
      - id: unkn2
        type: u4
        if: version >= 23 and version <= 30
      - id: unkn3
        type: u4
        doc: Copy of the number of directory strings?
        if: version >= 23
      - id: unkn4
        size: 24
        if: version >= 23
      - id: unkn5
        type: u4
        if: version >= 23 and version <= 30
      - id: unkn6
        type: u4
        doc: alignment padding?
        if: version >= 23
    instances:
      directory_strings:
        pos: directory_strings_offset
        type: string_descriptor_size_only
        repeat: expr
        repeat-expr: directory_strings_count
      file_references:
        pos: file_references_offset
        size: file_references_data_size
        type: file_references
    types:
      file_references:
        seq:
          - id: unkn0
            type: u4
            doc: Version?
          - id: count
            type: u4
          - id: references
            type: ntfs_file_reference
            repeat: expr
            repeat-expr: count
            doc: |
              First 8 bytes of the array not used? Remnant data or volume identifier?
              Do the file references represent file handles used by the executable? They seem to refer to files e.g. DLL.
