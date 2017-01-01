meta:
  id: rar
  title: RAR (Roshall ARchiver) archive files
  application: RAR archiver
  file-extension: rar
  xref:
    forensicswiki: RAR
    justsolve: RAR
    loc: fdd000450
    mime:
      - application/vnd.rar
      - application/x-rar-compressed
    pronom:
      - x-fmt/264 # RAR 2.0
      - fmt/411 # RAR 2.9
      - fmt/613 # RAR 5.0
    wikidata: Q243303
  license: CC0-1.0
  ks-version: 0.7
  imports:
    - /common/dos_datetime
  endian: le
doc: |
  RAR is a archive format used by popular proprietary RAR archiver,
  created by Eugene Roshal. There are two major versions of format
  (v1.5-4.0 and RAR v5+).

  File format essentially consists of a linear sequence of
  blocks. Each block has fixed header and custom body (that depends on
  block type), so it's possible to skip block even if one doesn't know
  how to process a certain block type.
doc-ref: http://acritum.com/winrar/rar-format
seq:
  - id: magic
    type: magic_signature
    doc: File format signature to validate that it is indeed a RAR archive
  - id: blocks
    type:
      switch-on: magic.version
      cases:
        0: block
        1: block_v5
    repeat: eos
    doc: Sequence of blocks that constitute the RAR file
types:
  magic_signature:
    doc: |
      RAR uses either 7-byte magic for RAR versions 1.5 to 4.0, and
      8-byte magic (and pretty different block format) for v5+. This
      type would parse and validate both versions of signature. Note
      that actually this signature is a valid RAR "block": in theory,
      one can omit signature reading at all, and read this normally,
      as a block, if exact RAR version is known (and thus it's
      possible to choose correct block format).
    seq:
      - id: magic1
        contents:
          - 'Rar!'
          - 0x1a
          - 0x07
        doc: "Fixed part of file's magic signature that doesn't change with RAR version"
      - id: version
        type: u1
        doc: |
          Variable part of magic signature: 0 means old (RAR 1.5-4.0)
          format, 1 means new (RAR 5+) format
      - id: magic3
        contents: [0]
        if: version == 1
        doc: New format (RAR 5+) magic contains extra byte
  block:
    doc: |
      Basic block that RAR files consist of. There are several block
      types (see `block_type`), which have different `body` and
      `add_body`.
    seq:
      - id: crc16
        type: u2
        doc: CRC16 of whole block or some part of it (depends on block type)
      - id: block_type
        type: u1
        enum: block_types
      - id: flags
        type: u2
      - id: block_size
        type: u2
        doc: Size of block (header + body, but without additional content)
      - id: add_size
        type: u4
        if: has_add
        doc: Size of additional content in this block
      - id: body
        size: body_size
        type:
          switch-on: block_type
          cases:
            'block_types::file_header': block_file_header
      - id: add_body
        size: add_size
        if: has_add
        doc: Additional content in this block
    instances:
      has_add:
        value: 'flags & 0x8000 != 0'
        doc: True if block has additional content attached to it
      header_size:
        value: 'has_add ? 11 : 7'
      body_size:
        value: block_size - header_size
  block_file_header:
    seq:
      - id: low_unp_size
        type: u4
        doc: Uncompressed file size (lower 32 bits, if 64-bit header flag is present)
      - id: host_os
        type: u1
        enum: oses
        doc: Operating system used for archiving
      - id: file_crc32
        type: u4
      - id: file_time
        size: 4
        type: dos_datetime
        doc: Date and time in standard MS DOS format
      - id: rar_version
        type: u1
        doc: RAR version needed to extract file (Version number is encoded as 10 * Major version + minor version.)
      - id: method
        type: u1
        enum: methods
        doc: Compression method
      - id: name_size
        type: u2
        doc: File name size
      - id: attr
        type: u4
        doc: File attributes
      - id: high_pack_size
        type: u4
        doc: Compressed file size, high 32 bits, only if 64-bit header flag is present
        if: '_parent.flags & 0x100 != 0'
      - id: file_name
        size: name_size
      - id: salt
        type: u8
        if: '_parent.flags & 0x400 != 0'
#     - id: ext_time
#       variable size
#       if: '_parent.flags & 0x1000 != 0'
  block_v5:
    {}
    # not yet implemented
  dos_time:
    seq:
      - id: time
        type: u2
      - id: date
        type: u2
    instances:
      year:
        value: '((date & 0b1111_1110_0000_0000) >> 9) + 1980'
      month:
        value: '(date & 0b0000_0001_1110_0000) >> 5'
      day:
        value: 'date & 0b0000_0000_0001_1111'
      hours:
        value: '(time & 0b1111_1000_0000_0000) >> 11'
      minutes:
        value: '(time & 0b0000_0111_1110_0000) >> 5'
      seconds:
        value: '(time & 0b0000_0000_0001_1111) * 2'

####### copyed from my draft code follows
  base_block:
  - id: high_pos_av
    type: u2
  - id: pos_av
    type: u4
  - id: comment_in_header
    type: u1
    # bool
  - id: pack_comment
    type: u1
    # bool
  - id: locator
    type: u1
    # bool
  - id: q_open_offset
    type: u8
  - id: q_open_max_size
    type: u8
  - id: rr_offset
    type: u8
  - id: rr_max_size
    type: u8

  block_header:
    - id: host_os
      type: u1
    - id: unp_ver
      type: u1
    - id: method
      type: u1
    - id: file_attr_or_sub_flags
      type: u4
    - id: file_name
      type: str
      size: NM
      encoding: UTF-32
    - id: sub_data
      size: NM
      encoding: UTF-32
    - id: m_time
      type: rar_time
    - id: c_time
      type: rar_time
    - id: a_time
      type: rar_time
    - id: pack_size
      type: u8
    - id: unp_size
      type: u8
    - id: max_size
      type: u8 # Reserve size bytes for vint of this size.
    - id: file_hash
      type: hash_value
    - id: split_before
      type: u1
    - id: split_after
      type: u1
    - id: unknown_unp_size
      type: u1
    - id: encrypted
      type: u1
    - id: crypt_method
      type: CRYPT_METHOD
    - id: salt_set
      type: u1
    - id: salt
      len: SIZE_SALT50
      type: u1
    - id: init_v
      len: SIZE_INITV
      type: u1
    - id: use_psw_check
      type: u1
    - id: psw_check
      len: SIZE_INITV
      type: u1
    - id: use_hash_key
      type: u1
    - id: hash_key
      seq:
      len: SHA256_DIGEST_SIZE
      type: u1
    - id: lg2_count
      type: u4
    - id: solid
      type: u1
    - id: dir
      type: u1
    - id: comment_in_header
      type: u1
    - id: version
      type: u1
    - id: win_size
      type: size_t
    - id: inherited
      type: u1
    - id: large_file
      type: u1
    - id: Sub_Block
      type: u1
    - id: host_system_type
      type: HOST_SYSTEM_TYPE
    - id: redir_type
      type: FILE_SYSTEM_REDIRECT
    - id: redir_name
      type: wstr
      size: NM
      encoding: UTF-32
    - id: dir_target
      type: u1
    - id: unix_owner_set
      type: u1
    - id: unix_owner_numeric
      type: u1
    - id: unix_group_numeric
      type: u1
    - id: unix_owner_name
      type: u1
      size: NM
      encoding: ASCII
    - id: unix_group_name
      type: u1
      size: NM
      encoding: ASCII
    - id: unix_owner_id
      type: u4
    - id: unix_group_id
      type: u4
    

  base_block:
    seq:
      - id: arc_data_crc
        type: u4
        doc: Optional CRC32 of entire archive up to start of EndArcHeader block. Present in RAR 4.x archives if EARC_DATACRC flag is set.
      - id: vol_number
        type: u4
        doc: Optional number of current volume.
      #7 additional zero bytes can be stored here if EARC_REVSPACE is set.
      - id: Next_Volume
        type: u4 # bool
        doc:  Not last volume.
      - id: data_crc
        type: u4 # bool
      - id: rev_space
        type: u4 # bool
      - id: store_vol_number
        type: u4 # bool
  crypt_header:
    seq:
      - id: use_psw_check
        type: u4 # bool
      - id: lg2_count
        type: u4
      - id: salt
        size: SIZE_SALT50
      - id: psw_check
        size: SIZE_PSWCHECK


// SubBlockHeader and its successors were used in RAR 2.x format.
// RAR 4.x uses FileHeader with HEAD_SERVICE HeaderType for subblocks.
struct SubBlockHeader:BlockHeader
{
  ushort SubType;
  byte Level;
};


struct CommentHeader:BaseBlock
{
  ushort UnpSize;
  byte UnpVer;
  byte Method;
  ushort CommCRC;
};


struct ProtectHeader:BlockHeader
{
  byte Version;
  ushort RecSectors;
  uint TotalBlocks;
  byte Mark[8];
};


struct AVHeader:BaseBlock
{
  byte UnpVer;
  byte Method;
  byte AVVer;
  uint AVInfoCRC;
};


struct SignHeader:BaseBlock
{
  uint CreationTime;
  ushort ArcNameSize;
  ushort UserNameSize;
};


struct UnixOwnersHeader:SubBlockHeader
{
  ushort OwnerNameSize;
  ushort GroupNameSize;
/* dummy */
  char OwnerName[256];
  char GroupName[256];
};


struct EAHeader:SubBlockHeader
{
  uint UnpSize;
  byte UnpVer;
  byte Method;
  uint EACRC;
};


struct StreamHeader:SubBlockHeader
{
  uint UnpSize;
  byte UnpVer;
  byte Method;
  uint StreamCRC;
  ushort StreamNameSize;
  char StreamName[260];
};


struct MacFInfoHeader:SubBlockHeader
{
  uint fileType;
  uint fileCreator;
};

enums:
  block_types: #HEADER_TYPE
    # RAR 1.5 - 4.x header types.
    0x72: marker # HEAD3_MARK
    0x73: archive_header # HEAD3_MAIN
    0x74: file_header # HEAD3_FILE
    0x75: old_style_comment_header # HEAD3_CMT
    0x76: old_style_authenticity_info_76 # HEAD3_AV
    0x77: old_style_subblock # HEAD3_OLDSERVICE
    0x78: old_style_recovery_record # HEAD3_PROTECT
    0x79: old_style_authenticity_info_79 # HEAD3_SIGN
    0x7a: subblock # HEAD3_SERVICE
    0x7b: terminator # HEAD3_ENDARC
    
    # RAR 5.0 header types.
    0x00: marker_5 # HEAD_MARK
    0x01: archive_header_5 # HEAD_MAIN
    0x02: file_header_5 # HEAD_FILE
    0x03: subblock_5 # HEAD_SERVICE
    0x04: encryption_5 # HEAD_CRYPT
    0x05: terminator_5 # HEAD_ENDARC
    0xff: unknown_5 # HEAD_UNKNOWN


  shit:
    0x100: EA_HEAD
    0x101: UO_HEAD
    0x102: MAC_HEAD
    0x103: BEEA_HEAD,
    0x104: NTACL_HEAD
    0x105: STREAM_HEAD

  oses:
    0: ms_dos
    1: os_2
    2: windows
    3: unix
    4: mac_os
    5: beos
  
  oses_rar5: # HOST_SYSTEM_TYPE
    # rar 5.0
    0: windows
    1: unix
    2: unknown
  
  methods:
    0x30: store
    0x31: fastest
    0x32: fast
    0x33: normal
    0x34: good
    0x35: best

  file_system_redirect:
    0: none
    1: unix_symlink
    2: win_symlink
    3: junction
    4: hardlink
    5: filecopy

