meta:
  id: metakit4
  file-extension: metakit4
  encoding: UTF-8
  title: Metakit 4
  application:
    - mk4

doc: |
  an embeddable database
params:
  - id: signature_offset
    type: u8
instances:
  header:
    pos: signature_offset
    type: header
  structural_information_offset:
    pos: signature_offset + header.data_size - sizeof<u4>
    type: u4be
  structural_information:
    pos: signature_offset + structural_information_offset
    type: structural_information
types:
  vlq_base128_be:
    meta:
      title: Metakit 4 variable length integer
    #-orig-id:
    seq:
      - id: reduction
        type: red(_index)
        repeat: until
        repeat-until: _.term
    instances:
      pos_value:
        value: reduction[reduction.size-1].value
      value:
        value: (reduction[0].term or reduction[0].chunk != 0)?pos_value:~pos_value
    types:
      red:
        params:
          - id: idx
            type: u1
        seq:
          - id: term
            type: b1
          - id: chunk
            type: b7
        instances:
          value:
            value: "(idx != 0 ? (_parent.as<vlq_base128_be>.reduction[idx-1].value.as<u8> << 7) : 0) | chunk"

  structural_information:
    seq:
      - id: unkn
        type: vlq_base128_be
      - id: definition_string_size
        type: vlq_base128_be
      - id: definition_string
        size: definition_string_size.value
        type: str
        -orig-id: c4_Field::c4_Field(const char * &description_,
        doc: |
          parse it with the grammar
  header:
    seq:
      - id: endian_identifier
        type: u2le
        enum: endian_identifier
      - id: unkn0
        type: u1
        doc: is it flags?
      - id: unkn1
        type: u1
        -orig-id: _data[3]
      - id: data_size
        -orig-id: _dataSize
        type: u4be
    instances:
      extend:
        value: unkn0 == 0x0A
      not_extend:
        value: unkn0 == 0x1A
      valid:
        value: not_extend and (endian_identifier == endian_identifier::le or endian_identifier == endian_identifier::be)
      is_old:
        value: unkn1 == 0x80
    enums:
      endian_identifier:
        0x4C4A:
          id: le
          -orig-id: kStorageFormat
          doc: JL
        0x4A4C:
          id: be
          -orig-id: kReverseFormat
          doc: LJ
