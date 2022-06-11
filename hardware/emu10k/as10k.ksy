meta:
  id: as10k
  title: so called patch programs for emu10k{1,2} DSPs compiled using as10k1
  file-extension: emu10k1
  license: GPL-3.0-or-later
  endian: le
  encoding: ascii
  application:
    - as10k1
    - emufxtool
  imports:
    - /hardware/emu10k/as10k_instr_or_macro

doc: |
  EMU10k1 and EMU10k2 are DSPs used in Creative Technology sound cards.
  ToDo: kx-audio-driver/kxapi/dane.cpp disassemble_microcode

  Precompiled samples alongside with debug logs of their compilation can be found here: https://github.com/KOLANICH/kaitai_struct_samples/tree/emu10k/hardware/emu10k/as10k

doc-ref:
  - https://github.com/alsa-project/alsa-tools/tree/master/as10k1
  - https://github.com/itadinanta/emufxtool
  - https://github.com/kxproject/kx-audio-driver
  - https://github.com/kxproject/kX-Audio-driver-Documentation

seq:
  - id: header
    type: header

  - id: instrs_count
    -orig-id: ip
    type: u2

  - id: code
    -orig-id: dsp_code
    type: as10k_instr_or_macro(header.instr_bitness)
    repeat: expr
    repeat-expr: instrs_count

types:
  header:
    instances:
      format_version:
        value: format_version_str.to_i

      patch_name_size:
        -orig-id: PATCH_NAME_SIZE
        value: 32

      chip_version:
        value: |
          (
            chip_name=='EMU10K2'
            ?
            2
            :
            (
              chip_name=='EMU10K1'
              ?
              1
              :
              0
            )
          )

      instr_bitness:
        value: 16 + chip_version * 4

      microcode_base:
        -orig-id: MICROCODE_BASE
        value: 0x200 + 0x200 * chip_version

      max_instructions:
        -orig-id: MAX_INSTRUCTIONS
        value: 512 * chip_version

    seq:
      - id: chip_name
        type: str
        terminator: 0x20
        valid:
          any-of:
            - "'EMU10K1'"
            - "'EMU10K2'"
      - id: instruction_set_architecture
        type: str
        terminator: 0x20
        valid:
          eq: "'FX8010'"
      - id: format_version_str
        type: str
        size: 1
        valid:
          eq: "'1'"
      - id: patch_name
        -orig-id: patch_name
        type: strz
        size: patch_name_size

      - id: gprs
        type: gprs

      - id: trams
        type: trams

    types:
      gprs:
        instances:
          gpr_base:
            -orig-id: GPR_BASE
            value: 0x100
        seq:
          - id: input_count
            -orig-id: gpr_input_count
            type: u1
          - id: inputs
            type: input
            repeat: expr
            repeat-expr: input_count

          - id: dynamic_count
            -orig-id: gpr_dynamic_count
            type: u1
          - id: dynamic
            type: dyn
            repeat: expr
            repeat-expr: dynamic_count

          - id: static_count
            -orig-id: gpr_static_count
            type: u1
          - id: static
            type: static
            repeat: expr
            repeat-expr: static_count

          - id: control_count
            -orig-id: gpr_control_count
            type: u1
          - id: control
            type: control
            repeat: expr
            repeat-expr: control_count

          - id: constant_count
            -orig-id: gpr_control_count
            type: u1
          - id: constant
            type: constant
            repeat: expr
            repeat-expr: constant_count
        types:
          input:
            seq:
              - id: input
                -orig-id: address
                type: u1
              - id: output
                -orig-id: address
                type: u1

          dyn:
            seq:
              - id: start
                -orig-id: address
                type: u1

          static:
            seq:
              - id: start
                -orig-id: address
                type: u1
              - id: value
                -orig-id: value
                type: u4

          control:
            instances:
              max_sym_len:
                -orig-id: MAX_SYM_LEN
                value: 32
            seq:
              - id: start
                -orig-id: address
                type: u1
              - id: value
                -orig-id: value
                type: u4
              - id: min
                -orig-id: min
                type: u4
              - id: max
                -orig-id: max
                type: u4
              - id: name
                -orig-id: name
                type: strz
                size: max_sym_len

          constant:
            seq:
              - id: start
                -orig-id: address
                type: u1
              - id: value
                -orig-id: value
                type: u1
      trams:
        seq:
          - id: tables
            -orig-id: tram_lookup
            type: tram_piece

          - id: delay_lines
            -orig-id: tram_lookup
            type: tram_piece
        types:
          tram_piece:
            seq:
              - id: count
                -orig-id: tram_delay_count
                type: u1
              - id: data
                -orig-id: tram_lookup
                type: tram
                repeat: expr
                repeat-expr: count
            types:
              tram:
                seq:
                  - id: size
                    -orig-id: size
                    type: u4
                  - id: read
                    type: line
                  - id: write
                    type: line
                types:
                  line:
                    seq:
                      - id: count
                        -orig-id:
                          - read
                          - write
                        type: u1
                      - id: symbols
                        #-orig-id: ?
                        type: sym
                        repeat: expr
                        repeat-expr: count
                    types:
                      sym:
                        seq:
                          - id: address
                            -orig-id: address
                            type: u1
                          - id: value
                            type: u4
