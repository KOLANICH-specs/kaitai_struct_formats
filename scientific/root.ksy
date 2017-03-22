meta:
  id: root
  title: CERN ROOT
  application: CERN ROOT
  file-extension: root
  xref:
    justsolve: ROOT
    wikidata: Q947171
  endian: be
  imports:
    - /common/uuid
doc: | 
  File format used by scientific software CERN ROOT.

doc-ref:
  - "https://root.cern.ch/doc/master/classTFile.html"
  - "https://github.com/root-mirror/root/blob/master/documentation/users-guide/InputOutput.md"
  - "https://root.cern.ch/root/htmldoc/guides/users-guide/ROOTUsersGuide.html#inputoutput"
seq:
  - id: signature
    contents: "root"
    doc: "Root file identifier"
  - id: f_version
    doc: "File format version"
    type: u4
  - id: f_begin
    doc: "Pointer to first data record"
    type: u4
  - id: f_end
    doc: "Pointer to first free word at the EOF"
    type: offset_ver
  - id: f_seek_free
    doc: "Pointer to FREE data record"
    type: offset_ver
  - id: f_n_bytes_free
    doc: "Number of bytes in FREE data record"
    type: u4
  - id: n_free
    doc: "Number of free data records"
    type: u4
  - id: f_n_bytes_name
    doc: "Number of bytes in **`TNamed`** at creation time"
    type: u4
  - id: f_units
    doc: "Number of bytes for file pointers"
    type: u1
  - id: f_compress
    doc: "Zip compression level"
    type: u4
  - id: f_seek_info
    doc: "Pointer to **`TStreamerInfo`** record"
    type: offset_ver
  - id: f_n_byte_info
    doc: "Number of bytes in TStreamerInfo record"
    type: u4
  - id: f_uuid
    doc: "Universal Unique ID"
    type: offset_ver # ?????
instances:
  t_key_stream:
    pos: f_begin
    size: (f_end.offset - f_begin)
    type: t_key_stream
types:
  t_key_stream:
    seq:
      - id: stream
        type: t_key
        repeat: eos
      
  # offset_ver:
    # doc: "When f_version is greater than 1000000, the file is a large file (> 2 GB) and the offsets will be 8 bytes long."
    # seq:
      # - id: offset8
        # type: u8
        # if:  '_root.f_version > 1000000'
      # - id: offset4
        # type: u4
        # if:  '_root.f_version <= 1000000'
    # instances:
      # offset:
        # value: '_root.f_version <= 1000000 ? offset4 : offset8'
  offset_ver:
    seq:
      - id: offset
        type:
          switch-on: offset_type
          cases:
            4: u4
            8: u8
    instances:
      offset_type:
        value: '_root.f_version <= 1000000 ? 4 : 8'
  t_key:
    seq:
      - id: n_bytes
        type: u4
        doc: "Length of compressed object (in bytes)"
      - id: version
        type: u2
        doc: "TKey version identifier"
      - id: obj_len
        type: u4
        doc: "Length of uncompressed object"
      - id: datime
        type: u4
        doc: "Date and time when object was written to file"
      - id: key_len
        type: u2
        doc: "Length of the key structure (in bytes)"
      - id: cycle
        type: u2
        doc: "Cycle of key"
      - id: seek_key
        type: offset_ptr
        doc: "Pointer to record itself (consistency check)"
      - id: seek_pdir
        type: offset_ptr
        doc: "Pointer to directory header"
      - id: class_name
        type: t_str
      - id: name
        type: t_str
      - id: title
        type: t_str
      - id: data
        size: n_bytes - 4-2-4-4-2-2-4*2-(1+class_name.len)-(1+name.len)-(1+title.len)
    types:
        offset_ptr:
          doc: " If the key is located past the 32 bit file limit (> 2 GB) then some fields will be 8 bytes instead of 4 bytes"
          seq:
            - id: offset
              #type: u8
              #if:  'lea(t_key) > 0xFFFFFFFF'
            #- id: offset
              type: u4
              #if:  'lea(t_key) <= 0xFFFFFFFF'
  t_str:
    seq:
      - id: len
        type: u1
        doc: "Number of bytes in string"
      - id: str
        type: str
        encoding: UTF-8
        size: len
