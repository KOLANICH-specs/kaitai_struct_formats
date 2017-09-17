meta:
  id: mdf
  title: DaemonTools and Alcohol 120% proprietary format
  application:
    - Alcohol 120%
    - Alcohol 62%
    - DaemonTools
  file-extension: mdf
  xref:
    justsolve: MDF_and_MDS
    wikidata: Q3853674
  endian: le
  license: LGPL-3.0
doc: |
  Native file format of Alcohol and DaemonTools. Stores a disk image.
doc-ref:
  - https://github.com/aaru-dps/Aaru/blob/2f9b7fe0a15d8b37935b439089534a925b53bd81/Aaru.Images/Alcohol120/Alcohol120.cs
types:
  structures_dvd:
    seq:
      - id: dmi
        size: 2052
      - id: pfi
        size: 2052


  session_header:
    seq:
      - id: start #0
        type: s4
      - id: end # 4
        type: s4
      - id: sequence #8
        type: u2
      - id: all_blocks #9
        type: u1
      - id: non_track_blocks #10
        type: u1
      - id: first_track #12
        type: u2
      - id: last_track #14
        type: u2
      - id: unkn0 #16
        size: 4
      - id: track_offset #20
        type: u4
      #24
    instances:
      tracks:
        pos: track_offset
        type: track_header
        repeat: until
        repeat-until: all_blocks
    types:
      track_header:
        seq:
          - id: mode
            type: u1
            enum: track_mode
          - id: subchannel_mode
            type: u1
            enum: subchannel_mode
          - id: adr_ctl
            type: u1
          - id: tno
            type: u1
          - id: point
            type: u1
          - id: min
            type: u1
          - id: sec
            type: u1
          - id: frame
            type: u1
          - id: zero
            type: u1
          - id: pmin
            type: u1
          - id: psec
            type: u1
          - id: pframe
            type: u1
          - id: extra_offset
            type: u4
          - id: sector_size
            type: u2
          - id: unknown1
            size: 18
          - id: start_lba
            type: u4
          - id: start_offset
            type: u8
          - id: files
            type: u4
          - id: footer_offset
            type: u4
          - id: unknown2
            size: 24
          #80
        instances:
          extra:
            pos: extra_offset
            type: track_extra
            if: track.extraOffset > 0 && mode!=track_mode::DVD
          sectors:
            value: extra_offset
            if: mode==track_mode::DVD
          footer:
            pos: footer_offset
            type: footer
            if: footer_offset
        enums:
          track_mode:
            0x00: no_data
            0x02: dvd
            0xa9: audio
            0xaa: mode1
            0xab: mode2
            0xac: mode2_f1
            0xad: mode2_f2

          subchannel_mode:
            0x00: none
            0x08: interleaved
        types:
          track_extra:
            seq:
              - id: pregap
                type: u4
              - id: sectors
                type: u4
          footer:
            seq:
              - id: filename_offset
                type: u4
              - id: widechar
                type: u4
                enum: encoding
              - id: unknown1
                type: u4
              - id: unknown2
                type: u4
            instances:
              file_name_nooffset:
                pos: filename_offset
                type: str
                size: eos
                encoding:
                  switch-on: widechar
                  cases:
                    encoding::ascii: ascii
                    encoding::utf_8: utf-8
                    _: ascii
                if: filename_offset > 0 and _root.dpm_offset == 0
              file_name_offsetted:
                pos: filename_offset
                type: str
                size: _root.dpm_offset - filename_offset
                encoding:
                  switch-on: widechar
                  cases:
                    encoding::ascii: ascii
                    encoding::utf_8: utf-8
                    _: ascii
                if: filename_offset > 0 and _root.dpm_offset != 0
              file_name:
                value: '(_root.dpm_offset != 0 ? file_name_offsetted : file_name_nooffset)'
                if: filename_offset > 0
            enums:
              encoding:
                0: ascii
                1: utf_8
seq:
  - id: signature #0
    contents: [MEDIA DESCRIPTO, 0]
  - id: version #16
    type: u2
  - id: medium_type #18
    type: u2
    enum: medium_type
  - id: sessions #20
    type: u2
  - id: unknown1 #22
    size: 4
  - id: bca_length #26
    type: u2
  - id: unknown2 #28
    size: 8
  - id: bca_offset #36
    type: u4
  - id: unknown3 #40
    size: 24
  - id: structures_offset # 64
    type: u4
  - id: unknown4 # 76
    size: 12
  - id: session_offset # 80
    type: u4
  - id: dpm_offset # 84
    type: u4
instances:
  sessions:
    pos: session_offset
    type: session_header
    repeat: expr
    repeat-expr: sessions
  bca:
    pos: bca_offset
    size: bca_length
    if: bca_length > 0 && bca_offset > 0
  structures:
    pos: structures_offset
    type: structures_dvd
    if: structures_offset >= 0 && _root.medium_type == medium_type.dvd
enums:
  medium_type:
    0x00: cd
    0x01: cd_r
    0x02: cd_rw
    0x10: dvd
    0x12: dvd_r
