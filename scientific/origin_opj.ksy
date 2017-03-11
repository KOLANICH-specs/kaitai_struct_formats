meta:
  id: origin_opj
  title: Origin project
  application:
    - Origin
    - OriginPro
    - Origin Viewer
  file-extension: opj
  xref:
    wikidata: Q1307239
  endian: le
  encoding: utf-8

doc: |
  Origin is a scientific spreadsheet editor. It uses an own proprietary format.
  
  Test files:
    https://github.com/aperbook/APER/tree/master/Origin
    https://github.com/choderalab/bayesian-itc/tree/master/data/Mg2-EDTA/Mg2EDTA
    https://github.com/aitap/Ropj/blob/master/inst/test.opj
    https://github.com/p4db/p4db-data/raw/master/icnp.opj
    https://rdmc-test.nottingham.ac.uk/bitstream/handle/internal/76/Photocurrent%20spectra%20of%20InSe-Indium%20oxide%20p-n%20junction.opj
    https://rdmc-test.nottingham.ac.uk/bitstream/handle/internal/76/Effect%20of%20thermal%20annealing%20with%20increasing%20temperature.opj
    https://rdmc-test.nottingham.ac.uk/bitstream/handle/internal/69/Grafting%20from%20%28thermal%29%20v%20time.opj
    https://rdmc-test.nottingham.ac.uk/bitstream/handle/internal/69/Grafting%20to%20IR%20PDMSvThiol.opj
    https://rdmc-test.nottingham.ac.uk/bitstream/handle/internal/69/Grafting%20to%20IR%20results%20bar.opj
    https://rdmc-test.nottingham.ac.uk/bitstream/handle/internal/69/Polymer%20kinetics%20solution.opj
doc-ref:
  - https://github.com/jgonera/openopj/blob/master/docs/opj_format.markdown
  - https://github.com/Saluev/python-liborigin2
  - https://github.com/swharden/PyOriginTools
  - https://sourceforge.net/p/liborigin/git/ci/master/tree/
  - https://github.com/vpaeder/terapy/blob/master/terapy/files/origin.py
  - https://sourceforge.net/p/scidavis/svn/HEAD/tree/trunk/qtfrontend/origin/OpjImporter.cpp

seq:
  - id: signature
    type: signature
  - contents: ["\n"]
  - id: blocks
    type: block
    repeat: eos
types:
  fragment_placeholder:
    seq:
      - id: tag_or_size
        terminator: 10 # \n
        if: begin_pos==0 or true
      - id: end_trigger
        size: 0
        if: end_pos==0 and false
    instances:
      begin_pos:
        value: _io.pos
      end_pos:
        value: _io.pos
      len:
        value: end_pos - begin_pos - 1
  block_with_size:
    params:
      - id: size
        type: u4
    seq:
      - id: type
        type: u2
        enum: type
      - id: payload
        type:
          switch-on: type
          cases:
            "type::header": header
            "type::column": column
        size: size - sizeof<u2>
      - contents: ["\n"]
  block:
    seq:
      - id: tag_placeholder
        type: fragment_placeholder
      - id: value_tag
        type:
          switch-on: tag
          cases:
            '"IFILE"': fragment_placeholder
            '"ERR"': fragment_placeholder
        if: tag_known
      - id: value_size
        type:
          switch-on: size > 4
          cases:
            true: block_with_size(size)
            false: fragment_placeholder
        if: is_size_block and present
    instances:
      tag:
        pos: tag_placeholder.begin_pos
        io: tag_placeholder._io
        type: str
        size: tag_placeholder.len
      tag_known:
        value: 'tag == "IFILE" or tag == "ERR"'
      is_size_block:
        value: not tag_known and tag_placeholder.len == 4
      size:
        pos: tag_placeholder.begin_pos
        io: tag_placeholder._io
        type: u4
        if: is_size_block
      present:
        value: tag_known or size != 0
  list:
    seq:
      - id: blocks
        type: block
        repeat: until
        repeat-until: _.present
  
  signature:
    seq:
      - id: sig_seq
        contents: ["CPYA "]
      - id: cpya_ver
        type: cpya_ver
      - id: build_number_str
        type: str
        terminator: 35 # "#"
    types:
      cpya_ver:
        seq:
          - id: major_str
            type: str
            terminator: 44 # ","
          - id: minor_str
            type: strz
            terminator: 32 # " "
        instances:
          major:
            value: major_str.to_i
          minor:
            value: minor_str.to_i
  header:
    seq:
      - id: unknown
        size: 27
      - id: version
        type: f8
      - id: unknown1
        size: 4

  column:
    seq:
      - id: type
        type: u1
      - id: content
        type:
          switch-on: type
          cases:
            1: column_header
            #0: column_content
  column_header:
    seq:
      - id: unknown0
        size: 19
      - id: flags
        type: flags
      - id: data_type
        type: u1
      - id: total_rows
        type: u4
        doc: The number of rows
      - id: first_row
        type: u4
        doc: indicates the first non-empty row (0 is the first row)
      - id: last_row
        type: u4
        doc:  indicates the last non-empty row.
      - id: unknown1
        size: 24
      - id: value_size
        type: u1
      - id: unknown2
        type: u1
      - id: data_type_u
        type: u1
      - id: unknown3
        size: 24
      - id: data_name
        type: strz
        size: 25
        doc: "Data name, for worksheets it's \"WORKSHEET_COLUMN\". Column is at most 18 chars long, remaining characters are used for \"_\", terminating null byte and worksheet name which may be truncated if too long."
      - id: data_type3
        type: u2
        doc: "According to [importOPJ][] the bytes starting at 0x0071 (start of this field) didn't exist before Origin 5.0."
      - id: unknown4
        type: u8
        doc: "Always zeros?"
    types:
      flags:
        seq:
          - id: unkn0
            type: u1
          - id: text_and_numeric
            type: b1
            doc: indicates that values are Text & Numeric
          - id: unkn1
            type: b2
          - id: long_or_integer
            type: b1
            doc: indicates that values are integers (i.e. Long or Integer)
          - id: unkn2
            type: b4
  column_content:
    params:
      - id: header
        type: column_header
    seq:
      - id: rows
        type:
          switch-on: header.value_size
          cases:
            1: u1
            2: u2
            4: u4 #or f4
            8: f8
            _: special_row
        size: header.value_size
        repeat: expr
        repeat-expr: header.total_rows
    types:
      special_row:
        seq:
          - id: value
            type:
              switch-on: value_type
              cases:
                1: text
                3: text_or_numeric
        instances:
          is_text:
            value: _parent.as<column_content>.header.value_size > 8
          value_type:
            value: (_parent.as<column_content>.header.flags.text_and_numeric.to_i << 1) | is_text.to_i
        types:
          text:
            seq:
              - id: value
                type: strz
              - id: garbage
                size-eos: true
          text_or_numeric:
            doc: "In case of Text values, the value is a null-terminated string. The bytes after the null are garbage or earlier contents of the value and can be disregarded."
            seq:
              - id: unkn0
                type: u1
                doc: "If the first byte is equal 0, the value is a double, if it's 1, the value is a string."
              - id: unkn1
                contents: [0]
                doc: "The second prefix byte seems to be always 0."
              - id: value
                type: 
                  switch-on: unkn0
                  cases:
                    0: f8
                    1: text

  window:
    seq:
      - id: header
        type: block
      - id: layers
        type: list
  window_header:
    doc: |
      As of now, the description of window list and its subsections is incomplete and merely serves as an indication of how to skip to the parameters section.
      window_section contains a header block and a layer list.
    seq:
      - id: unknown0
        size: 2
        doc: "Unknown, always zero?"
      - id: name
        type: strz
        size: 25
      - id: unknown2
        size-eos: true
        doc: "See importOPJ for details"
  window_layer:
    seq:
      - id: sublayers
        type: list
      - id: curves
        type: list
      - id: axis_break
        type: list
      - id: axis_parameter
        type: block
        repeat: expr
        repeat-expr: 3
  parameters:
    seq:
      - id: parameters
        type: parameter
        repeat: until
        repeat-until: _.name != ""
    types:
      parameter:
        seq:
          - id: name
            type: strz
            terminator: 10 # "\n"
          - id: value
            type: f8
          - id: lf1
            contents: [10] # "\n"
  folder:
    seq:
      - id: files
        type: list
      - id: folders
        type: list
  attachment:
    seq:
      - id: content
        type: list
enums:
  type:
    0x0002: header
    0x0000: column
    0xb808: embedded_b808
    0xb803: excel_b803
    0x2440: embedded_2440
    #1: u4
    #2: signature
    #3: column
    #4: column_content
    #5: window
    #6: note
    #7: attachment
    #10: window_header
    #11: window_layer
    #12: window_sublayer
    #13: window_curves
    #14: window_axis_parameter
    #15: window_axis_break
    #16: folder
    #17: file
    #18: attachment_content
