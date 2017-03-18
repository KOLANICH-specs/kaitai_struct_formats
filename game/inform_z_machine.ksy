meta:
  id: inform_z_machine
  title: Inform/Infocom z-machine
  file-extension: ["z1", "z2", "z3", "z3", "z5", "z6", "z7", "z8", "z9"]
  application: Inform/Infocom z-machine
  endian: le
  encoding: "raw"
  xrefs:
    wikidata: Q135811
  license: ?

doc: |
  A virtual machine for text quests.
  Some sample files:
    - https://ifdb.tads.org/search?searchfor=author%3AAdam+Cadre
    - https://github.com/historicalsource/hitchhikersguide
doc-ref: https://inform-fiction.org/zmachine/

seq:
  - id: header
    type: header
instances:
  dictionary_table:
    type: dictionary_table
    pos: header.dictionary_table
  objects_table:
    type: object_table
    pos: header.objects_table
  global_variables_table:
    type: global_variables_table
    pos: header.global_variables_table

  abbreviations_table:
    type: abbreviations_table
    pos: header.abbreviations_table
  terminating_characters_table:
    type: terminating_characters_table
    pos: header.terminating_characters_table
  alphabet_table:
    type: alphabet_table
    pos: header.alphabet_table
  counter_init_value:
    pos: header.counter_init_value_or_main
    if: v < 6
  main_routine:
    pos: header.counter_init_value_or_main
    if: v >= 6
  
types:
  object_number:
    seq:
      - id: number
        type:
        switch-on: _root.version
        cases:
          1: u1
          2: u1
          3: u1
          default: u2
  flags_1:
    seq:
      - id: colored # 0
        type: b1
        doc: "Colours available? set_by_interpreter restorable >=5"
      - id: time_in_status_line # 1
        type: b1
        doc: "Status line type: 0=score/turns, 1=hours:mins (<4) | Picture displaying available? set_by_interpreter restorable (>=4)"
      - id: two_discs # 2
        type: b1
        doc: "Story file split across two discs? <4 Boldface available? set_by_interpreter restorable >=4"
      - id: italic_available # 3
        type: b1
        doc: "Italic available? set_by_interpreter restorable >=4"
      - id: stat_line_avail # 4
        type: b1
        doc: "Status line not available? set_by_interpreter restorable < 4 Fixed-space style available? set_by_interpreter restorable >=4"
      - id: screen_split_avail # 5
        type: b1
        doc: "Screen-splitting available? set_by_interpreter restorable < 6 Sound effects available? set_by_interpreter restorable >=6"
      - id: var_pitch # 6
        type: b1
        doc: "Is a variable-pitch font the default? set_by_interpreter restorable"
      - id: timed_kb_inp_restorable # 7
        type: b1
        doc: |
          Timed keyboard input available?
          ***[1.0] The use of bit 7 in 'Flags 1' to signal whether timed input is available was new in the 1.0 document: see the preface. 
          set_by_interpreter restorable >=4
  flags_2:
    seq:
      - id: transcripting_enabled # 0
        type: b1
        doc: |
          Set when transcripting is on.
          The state of the transcription bit (bit 0 of Flags 2) can be changed directly by the game to turn transcribing on or off (see S 7.3, S 7.4). The interpreter must also alter it if stream 2 is turned on or off, to ensure that the bit always reflects the true state of transcribing. Note that the interpreter ensures that its value survives a restart or restore.
          dynamic set_by_interpreter restorable"
      - id: force_printing_font # 1
        type: b1
        doc: "Game sets to force printing in fixed-pitch font dynamic restorable"
      - id: request_redraw # 2
        type: b1
        doc: "Int sets to request screen redraw: game clears when it complies with this. dynamic set_by_interpreter"
      - id: use_pictures # 3
        type: b1
        doc: "If set, game wants to use pictures set_by_interpreter restorable"
      - id: use_undo # 4
        type: b1
        doc: "If set, game wants to use the UNDO opcodes set_by_interpreter restorable"
      - id: use_mouse # 5
        type: b1
        doc: "If set, game wants to use a mouse set_by_interpreter restorable"
      - id: use_colours # 6
        type: b1
        doc: "If set, game wants to use colours"
      - id: use_sound_effects # 7
        type: b1
        doc: "If set, game wants to use sound effects set_by_interpreter restorable"
      - id: use_menus # 8
        type: b1
        doc: "If set, game wants to use menus set_by_interpreter restorable"

  header:
    seq:
      - id: version
        type: u1
        doc: "Version number (1 to 6)"
      - id: flags1
        size: 3
        type: flags_1
        doc: "Flags"
      - id: high_mem_base
        type: u2
        doc: "Base of high memory (byte address)"
      - id: counter_init_value_or_main
        type: u2
        doc: "Initial value of program counter (byte address) <6 Packed address of initial \"main\" routine >=6"
      
      - id: dictionary_table
        type: u2
        doc: "Location of dictionary (byte address)"
      - id: objects_table
        type: u2
        doc: "Location of object table (byte address)"
      - id: global_variables_table
        type: u2
        doc: "Location of global variables table (byte address)"
      
      - id: static_mem_base
        type: u2
        doc: "Base of static memory (byte address)"
      - id: flags2
        size: 8
        type: flags_2
        doc: "Flags. (For bits 3,4,5,7 and 8, Int clears again if it cannot provide the requested effect.)"
      - id: abbreviations_table
        type: u2
        doc: "Location of abbreviations table (byte address)"
      
      - id: file_len
        type: u2
        doc: |
         Length of file
         The file length stored at $1a is actually divided by a constant, depending on the Version, to make it fit into a header word. This constant is 2 for Versions 1 to 3, 4 for Versions 4 to 5 or 8 for Versions 6 and later.
      
      - id: checksum
        type: u2
        doc: "Checksum of file"
      
      - id: interpreter_number
        type: u1
        enum: interpreter_number
        doc: |
          Interpreter number
          An interpreter should choose the interpreter number most suitable for the machine it will run on. In Versions up to 5, the main consideration is that the behaviour of 'Beyond Zork' depends on the interpreter number (in terms of its usage of the character graphics font). In Version 6, the decision is more serious, as existing Infocom story files depend on interpreter number in many ways: moreover, some story files expect to be run only on the interpreters for a particular machine. (There are, for instance, specifically Amiga versions.)
          set_by_interpreter restorable
      - id: interpreter_version
        type: u1
        doc: |
          Interpreter versions are conventionally ASCII codes for upper-case letters in Versions 4 and 5 (note that Infocom's Version 6 interpreters just store numbers here).
          Modern games are strongly discouraged from testing the interpreter number or interpreter version header information for any game-changing behaviour. It is rarely meaningful, and a Standard interpreter provides many better ways to query the interpreter for information. 
          set_by_interpreter restorable
      
      - id: screen_height
        type: u1
        doc: "Screen height (lines): 255 means \"infinite\" set_by_interpreter restorable"
      - id: screen_width
        type: u1
        doc: "Screen width (characters) set_by_interpreter restorable"
      - id: screen_width_in_units
        type: u2
        doc: "Screen width in units set_by_interpreter restorable"
      - id: screen_height_in_units
        type: u2
        doc: "Screen height in units set_by_interpreter restorable"
      
      - id: font_width_in_units
        type: u1
        doc: "Font width in units (defined as width of a '0') set_by_interpreter restorable"
        if: version<=5
      - id: font_height_in_units
        type: u1
        doc: "Font height in units set_by_interpreter restorable"
        if: version<=5
      - id: font_height_in_units
        type: u1
        doc: "Font height in units set_by_interpreter restorable"
        if: version>=6
      - id: font_width_in_units
        type: u1
        doc: "Font width in units (defined as width of a '0') set_by_interpreter restorable"
        if: version>=6
      
      - id: routines_offset_red
        type: u2
        doc: "Routines offset (divided by 8)"
      - id: static_strings_offset_red
        type: u2
        doc: "Static strings offset (divided by 8)"
      
      - id: bg_color
        type: u1
        doc: "Default background colour set_by_interpreter restorable"
      - id: fg_color
        type: u1
        doc: "Default foreground colour set_by_interpreter restorable"
      
      - id: terminating_characters_table
        type: u2
        doc: "Address of terminating characters table (bytes)"
      
      - id: str_3_total_width
        type: u2
        doc: "Total width in pixels of text sent to output stream 3. set_by_interpreter"
      - id: standard_revision_number
        type: u2
        doc: |
          ***[1.0] If an interpreter obeys Revision n.m of this document perfectly, as far as anyone knows, then byte $32 should be written with n and byte $33 with m. If it is an earlier (non-standard) interpreter, it should leave these bytes as 0. 
          set_by_interpreter restorable
      
      - id: alphabet_table
        type: u2
        doc: "Alphabet table address (bytes), or 0 for default"
      - id: header_extension_table
        type: u2
        doc: |
          Header extension table address (bytes) (>=5)
          The header extension table provides potentially unlimited room for further header information. It is a table of word entries, in which the initial word contains the number of words of data to follow.
          If the interpreter needs to read a word which is beyond the length of the extension table, or the extension table doesn't exist at all, then the result is 0. 
          If the interpreter needs to write a word which is beyond the length of the extension table, or the extension table doesn't exist at all, then the result is that nothing happens.
    instances:
      header_extension_table:
        pos: header_extension_table
      routines_offset:
        pos: routines_offset_red*8
      static_strings_offset:
        pos: static_strings_offset_red*8
      
    enums:
      interpreter_number:
        0x1: dec_system_20
        0x2: apple_iie 
        0x3: apple_macintosh
        0x4: amiga
        0x5: atari_st
        0x6: ibm_pc
        0x7: commodore_128
        0x8: commodore_64
        0x9: apple_iic
        0xA: apple_iigs
        0xB: tandy_color
    types:
      header_extension_table:
        seq:
          - id: size_in_words
            type: u2
            doc: "Number of further words in table"
          - id: last_click_x
            type: u2
            doc: "X-coordinate of mouse after a click"
          - id: last_click_y
            type: u2
            doc: "Y-coordinate of mouse after a click"
          - id: unicode_translation_table
            type: u2
            doc: "Unicode translation table address (optional)"
          - id: flags_3
            type: flags3
          - id: true_fg
            type: u2
            doc: "True default foreground colour"
          - id: true_bg
            type: u2
            doc: "True default background colour"
        types:
          flags3:
            seq:
              - id: uses_transparency
                type: b1
                doc: "If set, game wants to use transparency"
              - id: reserved
                type: b15
  object_table:
    seq:
      - id: property_defaults_table
        type: property_defaults_table
        doc: "This contains 31 words in Versions 1 to 3 and 63 in Versions 4 and later. When the game attempts to read the value of property n for an object which does not provide property n, the n-th entry in this table is the resulting value."
      - id: object_tree
        type: object_tree
        doc: "Objects are numbered consecutively from 1 upward, with object number 0 being used to mean \"nothing\" (though there is formally no such object). The table consists of a list of entries, one for each object. "
    types:
      object:
        seq:
          - id: attribute_flags
            type:
              switch-on: _root.version
              cases:
                1: u4
                2: u4
                3: u4
                default: u6
            doc: "attribute 0 is stored in bit 7 of the first byte, attribute 31 is stored in bit 0 of the fourth."
          - id: parent
            type: object_number
            doc: "must hold valid object numbers"
          - id: sibling
            type: object_number
            doc: "must hold valid object numbers"
          - id: child
            type: object_number
            doc: "must hold valid object numbers"
          - id: properties
            type: u2
            doc: "The properties pointer is the byte address of the list of properties attached to the object."
      object_prop_table:
        seq:
          - id: len
            type: u1
            doc: "is the number of 2-byte words making up the text, which is stored in the usual format. (This means that an object's short name is limited to 765 Z-characters.)"
          - id: short_name
            type: str
            size: len*2
            doc: "attribute 0 is stored in bit 7 of the first byte, attribute 31 is stored in bit 0 of the fourth."
          - id: properties
            type:
              switch-on: _root.version
              cases:
                1: object_prop_v1
                2: object_prop_v1
                3: object_prop_v1
                default: object_prop_v4
            doc: "After the header, the properties are listed in descending numerical order. (This order is essential and is not a matter of convention.)"
            repeat: until
            repeat-until: _.size_field!=0 or _.number!=0
        types:
          object_prop_v1:
            seq:
              - id: size_field
                type: b3
                doc: "size byte (here it is size_field with property_number) is arranged as 32 times the number of data bytes minus one, plus the property number."
              - id: number
                type: b5
              - id: data
                size: size
                doc: ""
            instances:
              size:
                value: size_field + 1
          object_prop_v4:
            seq:
              - id: size_field_is_two_bytes
                type: b1
              - id: size_field
                type:
                  switch-on: size_field_is_two_bytes
                  cases:
                    'true':  object_prop_v4_size_field_2_byte
                    'false': object_prop_v4_size_field_1_byte
              - id: data
                size: size
                doc: ""
            instances:
              size:
                value: size_field.size
              number:
                value: size_field.number
            types:
              object_prop_v4_size_field_1_byte:
                seq:
                  - id: prop_size_2_or_1
                    type: b1
                  - id: number
                    type: b6
                instances:
                  size:
                    switch-on: prop_size_2_or_1
                    cases:
                      true: 2
                      false: 1
              object_prop_v4_size_field_2_byte:
                seq:
                  - id: reserved0
                    type: b1
                  - id: number
                    type: b6

                  - id: reserved1
                    type: b1
                    contents: 0b1
                  - id: reserved2
                    type: b1
                  - id: size_field
                    type: b6
                instances:
                  size:
                    value:
                      switch-on: size_field
                      cases:
                        0: 64
                        default: size_field

  dictionary_table:
    seq:
      - id: n
        type: u1
        doc: ""
      - id: keyboard_input_codes_list
        size: n
        doc: |
          The keyboard input codes are word-separators: typically (and under Inform mandatorily) these are the ZSCII codes for full stop, comma and double-quote. Note that a space character (32) should never be a word-separator. Note that the word-separators table can only contain codes which are defined in ZSCII for both input and output.
          Linards Ticmanis reports that some of Infocom's interpreters convert question marks to spaces before lexical analysis. This is not Standard behaviour. (Thus, typing "What is a grue?" into 'Zork I' no longer works: the player must type "What is a grue" instead.) 
      - id: entry_length
        type: u1
        doc: "length of each word's entry in the dictionary table. (It must be at least 4 in Versions 1 to 3, and at least 6 in later Versions.)"
      - id: number_of_entries
        type: u2
        doc: ""
      - id: words
        type: word
        repeat: expr
        repeat-expr: number_of_entries
        doc: |
          The word entries follow immediately after the dictionary header and must be given in numerical order of the encoded text (when the encoded text is regarded as a 32 or 48-bit binary number with most-significant byte first). It must not contain two entries with the same encoded text.
          It is essential that dictionary entries are in numerical order of the bytes of encrypted text so that interpreters can search the dictionary efficiently (e.g. by a binary-chop algorithm). Because the letters in A0 are in alphabetical order, because the bits are ordered in the right way and because the pad character 5 is less than the values for the letters, the numerical ordering corresponds to normal English alphabetical order for ordinary words. (For instance "an" comes before "anaconda".)
    types:
      word:
        seq:
          - id: text_of_word_enc
            size: 
              switch-on: version
              cases:
                1: 4
                2: 4
                3: 4
                default: 6
            doc: |
              The encoded text contains 6 Z-characters (it is always padded out with Z-character 5's to make up 4 bytes: see S 3).
              The text may include spaces or other word-separators (though, if so, the interpreter will never match any text to the dictionary word in question: surprisingly, this can be useful and is a trick used in the Inform library).
              In Versions 4 and later, the encoded text has 6 bytes and always contains 9 Z-characters.
              Both Infocom and Inform-compiled games contain words whose initial character is not a letter (for instance, "#record").
          - id: data
            size: entry_length-4
            doc: |
              The interpreter ignores the bytes of data (presumably the game's parser will use them).
              Usually (under Inform, mandatorily) there are three bytes of data in the word entries, so that dictionary entry lengths are 7 and 9 in the early and late Z-machine, respectively.
