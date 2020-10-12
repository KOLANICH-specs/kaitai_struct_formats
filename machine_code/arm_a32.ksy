meta:
  id: arm_a32
  title: Advanced/Acorn RISC Machine opcode
  endian: le
  encoding: utf-8
  license: Unlicense
  xref:
    wikidata:
      - Q16980
      - Q628336
      - Q6560350

-affected-by:
  - 155 # the implemented schema of endianness mapping is shit. We have to do all bit arithmetics ourselves.
  - 576 # some stuff can be implemented much more straightforwardly with this
  - 642 # have to cut self._io.align_to_byte() manually
  - 112 # prereq of 576

doc: |
  32-bit ARM v7 opcode. Thumb instructions are not covered by this spec.

  examples:
    D5 91 27 C5    1101_010_1100100010010011111000101    strgt sb, [r7, -0x1d5]!
    00 B0 14 00    0000_000_010110000000101000000_0000    andseq fp, r4, r0
    00 00 A0 E1    0000_000_0000_0_0000_1010_00001_11_0_0001    mov r0, r0
    00 00 A0 E1    0000_000_0000_0_0000_1010_00001_11_0_0001    mov r0, r0
    00 00 A0 E1    0000_000_0000_0_0000_1010_00001_11_0_0001    mov r0, r0
    00 00 A0 E1    0000_000_0000_0_0000_1010_00001_11_0_0001    mov r0, r0
    00 00 A0 E1    0000_000_0000_0_0000_1010_00001_11_0_0001    mov r0, r0
    00 00 A0 E1    0000_000_0000_0_0000_1010_00001_11_0_0001    mov r0, r0
    02 00 00 EA    0000_001_0000000000000000011101010    b 0x30

doc-ref:
  - https://ssd.sscc.ru/sites/default/files/content/attach/310/armv7.pdf
  - https://web.eecs.umich.edu/~prabal/teaching/eecs373-f10/readings/ARMv7-M_ARM.pdf
  - https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/third-party/archives/ddi0100e_arm_arm.pdf
  - https://developer.arm.com/architectures/instruction-sets/base-isas/a32
  - https://re-eject.gbadev.org/files/armref.pdf
  - https://web.archive.org/web/20180820121144/http://infocenter.arm.com/help/topic/com.arm.doc.qrc0001m/QRC0001_UAL.pdf
  - https://users.ece.utexas.edu/~valvano/EE345M/Arm_EE382N_4.pdf#%5B%7B%22num%22%3A57%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22Fit%22%7D%5D

seq:
  - id: opcodes
    type: opcode
    repeat: eos

types:
  opcode:
    seq:
      - id: num
        type: u4
    instances:
      condition:
        value: num >> 28
        enum: condition_code
      instr_class:
        value: (num >> 26) & 2
        enum: instructions_class
      bit_25:
        value: (num >> 25) & 1 == 1
      chunk_24_21:
        value: (num >> 21) & 15
      bit_20:
        value: (num >> 20) & 1 == 1
      chunk_19_8:
        value: (num >> 8) & 4095
      chunk_19_16:
        value: (num >> 16) & 15
      chunk_15_12:
        value: (num >> 12) & 15
      chunk_11_7:
        value: (num >> 7) & 0b11111
      chunk_11_8:
        value: (num >> 8) & 0b1111
      chunk_7_4:
        value: (num >> 4) & 15
      chunk_7_0:
        value: num & 0x8F
      chunk_6_5:
        value: (num >> 5) & 3
      bit_4:
        value: (num >> 4) & 1 == 1
      chunk_3_0:
        value: num & 15
      chunk_24_0:
        value: num & (1<<24 - 1)
      instr:
        pos: 0
        type:
          switch-on: instr_class
          cases:
            instructions_class::processing_or_misc: processing_or_misc(num, bit_25, chunk_24_21, bit_20, chunk_19_16, chunk_15_12, chunk_11_7, chunk_6_5, bit_4, chunk_3_0, chunk_7_0)
            instructions_class::branch_or_block_transfer: branch_or_block_transfer(bit_25, chunk_24_0)
            instructions_class::coprocessor_or_supervisor: coprocessor_or_supervisor(bit_25, bit_20, chunk_24_0, chunk_19_16, chunk_15_12, chunk_11_8, chunk_7_0)
            instructions_class::transfer_word_or_byte: transfer_word_or_byte(bit_25, chunk_24_20, chunk_19_16, chunk_15_12, chunk_11_0, chunk_11_7, chunk_6_5, bit_4, chunk_3_0)

    enums:
      condition_code:
        0b0000: eq
        0b0001: ne
        0b0010: cs
        0b0011: cc
        0b0100: mi
        0b0101: pl
        0b0110: vs
        0b0111: vc
        0b1000: hi
        0b1001: ls
        0b1010: ge
        0b1011: lt
        0b1100: gt
        0b1101: le
        0b1110: al
        0b1111: nv
    types:
      reg_act:
        seq:
          - id: rn
            type: b4
          - id: rd
            type: b4


      rotate_immediate:
        seq:
          - id: rotate
            type: b4
          - id: immediate
            type: u1

      pu:
        seq:
          - id: p
            type: b1
            enum: post_indexed
          - id: u
            type: b1
            enum: add_or_subtract
        enums:
          post_indexed:
            0: post_indexed
            1: offset_or_preindexed
          add_or_subtract:
            0: sub
            1: add
      wl:
        seq:
          - id: w
            type: b1
            enum: preindexed_or_offset
            doc: W is for writeback
          - id: l
            type: b1
            enum: load_or_store
        enums:
          preindexed_or_offset:
            0: offset
            1: pre_indexed
          load_or_store:
            0: store
            1: load

      s_rn_rd:
        seq:
          - id: s
            type: b1
            enum: signed_or_unsigned_halfword
          - id: reg_act
            type: reg_act

      opcode_s_rn_rd:
        seq:
          - id: opcode
            type: b4
          - id: s_rn_rd
            type: s_rn_rd

      generic_rotate_shift_stuff:
        params:
          - id: opcode_hi
            type: u1
        seq:
          - id: opcode_lo
            type: b2
          - id: s_rn_rd
            type: s_rn_rd
        instances:
          opcode:
            value: opcode_hi << 2 | opcode_lo
            enum: data_proc_instr_opcode

      processing_or_misc:
        params:
          - id: num
            type: u4
          - id: op # 25
            type: bool
          - id: opcode # 24-21
            type: u1
          - id: s # 20
            type: bool
          - id: rn # 19-16
            type: u1
          - id: rd # 15-12
            type: u1
          - id: shift_amount # 11-7
            type: u1
          - id: shift # 6-5
            type: u1
          - id: bit_4
            type: bool
          - id: rm # 3-0
            type: u1
          - id: chunk_7_0
            type: u4
        instances:
          opcode_hi:
            value: opcode >> 2
          is_misc:
            value: opcode_hi == 0b10
          i:
            value: ((num >> 23) & 1) == 1
          rest:
            value: num & ((1 << 23) - 1)
          instr:
            pos: 0
            type:
              switch-on: i
              cases:
                true: data_proc_immed(opcode_hi, rest)
                false: immed_shift_or_multiplies_or_misc(rest)
        types:
          immed_shift_or_multiplies_or_misc:
            params:
              - id: num
                type: u4
            instances:
              opcode_lo:
                value: num >> 21

              rest:
                value: num & ((1 << 21) - 1)
              payload:
                pos: 0
                type:
                  switch-on: opcode_lo
                  cases:
                    0b10: misc(rest)
                    _: shift(opcode_lo, rest)
            types:
              misc:
                params:
                  - id: num
                    type: u4
                instances:
                  bit_23:
                    value: ((num >> 23) & 1) == 1
                  opcode:
                    value: num >> 18
                    #valid: 0b010
                    #-affected-by: # ToDo: create
                  op:
                    value: num >> 15 & 3
                  reserved:
                    value: num >> 14 & 1 == 1
                    #valid: false
                    #-affected-by: # ToDo: create
                  arg0:
                    value: num >> 10 & 15
                    #type: b4
                  #arg1:
                  #  value: num >> 6 & 15
                  #  type: b4
                  #arg1:
                  #  value: num >> 2 & 15
                  #  type: b4
                  #  repeat: expr
                  #  repeat-expr: 3
                  op2:
                    value: (num >> 3) & 7
                  rm_or_sbz_or_immed:
                    value: num & 15

              shift:
                params:
                  - id: opcode_hi
                    type: u1
                seq:
                  - id: generic_rotate_shift_stuff
                    type: generic_rotate_shift_stuff(opcode_hi)
                  - id: shift_amount_hi_or_rs
                    type: b5
                  - id: shift_amount_lo_or_multiplies_flag
                    type: b1
                  - id: shift
                    type: b2
                  - id: is_data_processing_or_multiplies_flag
                    type: b1
                  - id: rm
                    type: b4
                instances:
                  is_multiplies:
                    value: shift_amount_lo_or_multiplies_flag and is_data_processing_or_multiplies_flag
                  is_data_processing:
                    value: not shift_amount_lo_or_multiplies_flag and is_data_processing_or_multiplies_flag
                  is_immediate_shift:
                    value: not is_data_processing_or_multiplies_flag

          data_proc_immed:
            params:
              - id: opcode_hi
                type: u1
              - id: num
                type: u4
            seq:
              - id: payload
                type:
                  switch-on: opcode_hi
                  cases:
                    0b10: status_reg_or_undef
                    _: generic_rotate_shift_stuff(opcode_hi)
              - id: rotate_immediate
                type: rotate_immediate
            types:
              status_reg_or_undef:
                seq:
                  - id: r
                    type: b1
                  - id: some_marker
                    type: b2
                  - id: payload
                    type:
                      switch-on: some_marker
                      cases:
                        0b10: status_reg
                types:
                  status_reg:
                    seq:
                      - id: mask
                        type: b4
                      - id: sbo
                        type: b4


      branch_or_block_transfer:
        params:
          - id: i
            type: b1
          - id: num
            type: u4
        instances:
          instr:
            pos: 0
            type:
              switch-on: i
              cases:
                true: branch(num)
                false: load_store_multiple(num)
        types:
          branch:
            params:
              - id: num
                type: u4
            instances:
              link:
                value: (num >> 24) == 1
                doc: if true, store return address to link register (R14)
              addr:
                value: num & ((1 << 24) -1)

          load_store_multiple:
            params:
              - id: num
                type: u4
            instances:
              pu:
                value: (num >> 23) & 3
                doc: if true, store return address to link register (R14)
              s:
                value: ((num >> 22) & 1)
                enum: signed_or_unsigned_halfword
              wl:
                value: (num >> 20) & 3
              rn:
                value: (num >> 16) & 15
              register_list:
                value: num & 0xFFFF

      coprocessor_or_supervisor:
        params:
          - id: bit_25
            type: b1
          - id: bit_20
            type: b1
          - id: chunk_24_0
            type: u4
          - id: rn
            type: u1
          - id: chunk_15_12
            type: u1
          - id: chunk_11_8
            type: u1
          - id: chunk_7_0
            type: u1
        seq:
          - id: i
            type: b1
          - id: instr
            type:
              switch-on: i
              cases:
                true: coproc_or_interrupt
                false: coproc_load_store_double
        types:
          coproc_or_interrupt:
            seq:
              - id: is_interrupt
                type: b1
              - id: payload
                type:
                  switch-on: is_interrupt
                  cases:
                    true: b24
                    #false: coproc # Coprocessor load/store and double register transfers, Coprocessor register transfers, Coprocessor data processing, Undefined instruction
            types:
              coproc:
                seq:
                  - id: opcode_or_opcode_and_l
                    type: b4
                  - id: crn_crd_or_rd_cp_num
                    type: coproc_rn_rd_cp_num
                  - id: opcode2
                    type: b3
                  - id: is_reg_transfer
                    type: b1
                  - id: crm
                    type: b4

          coproc_load_store_double:
            seq:
              - id: pu
                type: pu
              - id: n
                type: b1
              - id: wl
                type: wl
              - id: rn_crd_cp_num
                type: coproc_rn_rd_cp_num
              - id: offset
                type: u1

      transfer_word_or_byte:
        doc-ref: A5.3 Load/store word and unsigned byte
        seq:
          - id: a
            type: b1
          - id: op1
            type: op1
          - id: reg_act
            type: reg_act
          - id: instr
            type:
              switch-on: a
              cases:
                false: load_store_immediate_offset
                true: load_store_register_offset
        types:
          op1:
            seq:
              - id: pu
                type: pu
              - id: b
                type: b1
              - id: wl
                type: wl
          load_store_immediate_offset:
            seq:
              - id: immediate
                type: b12

          load_store_register_offset:
            seq:
              - id: shift_amount
                type: b5
              - id: shift
                type: b2
              - id: b
                type: b1
              - id: rm
                type: b4


      coproc_rn_rd_cp_num:
        seq:
          - id: rn
            type: b4
          - id: rd
            type: b4
          - id: cp_num
            type: b4


enums:
  instructions_class:
    0b00: processing_or_misc
    0b01: transfer_word_or_byte
    0b10: branch_or_block_transfer
    0b11: coprocessor_or_supervisor
  data_proc_instr_opcode:
    0b0000: logic_and
    0b0001: eor
    0b0010: sub
    0b0011: rsb
    0b0100: add
    0b0101: adc
    0b0110: sbc
    0b0111: rsc
    0b1000: tst
    0b1001: teq
    0b1010: cmp
    0b1011: cmn
    0b1100: orr
    0b1101: mov
    0b1110: bic
    0b1111: mvn

  signed_or_unsigned_halfword:
    1: signed
    0: unsigned_halfword
