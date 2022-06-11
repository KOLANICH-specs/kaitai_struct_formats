meta:
  id: as10k_instr_or_macro
  title: Either a pseudoinstruction enum used in as10k, or a real EMU10k instruction
  license: GPL-2.0-or-later
  endian: le
  encoding: ascii
  application:
    - as10k1
  imports:
    - /hardware/emu10k/emu10k_instr

doc: |
  AS10k1 incodes macros using these enum values.
  Offsetted by 16, since below 16 there are emu10k opcodes.

doc-ref: https://github.com/alsa-project/alsa-tools/tree/master/as10k1

params:
  - id: bitness
    type: u1

enums:
  macro:
    0x0:
      id: equ
      doc: |
        Yes Value_Equated
        Creates an assembly time Equate
        Equates a symbol to a be constant which is substituted at assembly time
        <symbol> EQU <Value equated>
        The value is a 16-bit integer value
    0x1:
      id: ds
    0x2:
      id: dynamic
      doc: |
        Yes number_of_gprs
        defines 1 or more temporary gprs (may be reused by other patches)
        Declares an automatic GPR from the emu10k1. This should be used for temporary storage only. It the GPR may be reused by other patches. No initial value is loaded to it.
        Syntax
        <symbol> DYN <numberOfStorageSpaces>
        or
        <symbol> DYNAMIC <numberOfStorageSpaces>
        The argument can be an equated symbol, if no value is given 1 GPR is allocated.
    0x3:
      id: dyn
    0x4:
      id: macro
      doc: |
        Yes arg1,arg2,arg3,...
        Defines a macro with given arguments
        Used for defining a macro
        Defining Macro:
        <symbol> macro arg1,arg2,arg3....
        ....
        <opcode> arg4,arg1,arg2... ;;for example
        ....
        ....
        endm
        were the <symbol> used is the mnemonic representing the macro.
        arg1,arg2,arg3... can be any symbols (auto-defining and local to a macro) as long as the symbol is not already in use outside the macro (i.e. as a DC, DS, etc.).
        There's no limit to how many arguments can be used.
    0x5:
      id: dc
    0x6:
      id: static
      doc: |
        Yes init_value1,init_value2,...
        Defines one or more Static gprs with initial values
        Declares a static GPR. The GPR is loaded with the specified initial value. The GPR is not shared with any other patch.
        Syntax:
        <symbol> STA <numberOfStorageSpaces>
        or
        <symbol> STATIC <numberOfStorageSpaces>
        The argument is a 32-bit integer value
    0x7:
      id: sta
    0x8:
      id: din
    0x9:
      id: dout
    0xa:
      id: delay
      doc: |
        Yes Delay_length
        Declares a delay line of given length
        Define Delay, used for allocating an amount of TRAM for a delay line.
        <symbol> DELAY <Size>
        The symbol is used to identify this delay line. The Size is the amount of TRAM allocated. The argument is a 32-bit
        integer value. A '&' indicates that the value represents an amount of time, the assembler will calculate the amount of samples required for the delay.
    0xb:
      id: table
      doc: |
        Yes Table_length
        Declares a lookup table of given length
        same as DELAY but for lookup tables.
    0xc:
      id: twrite
      doc: |
        Yes tram_id,offset
        creates a tram write associated with tram element "tram_id", with a given offset
        Same as TREAD but used for writing data to a delay line.
        <symbol1> TWRITE <symbol2>,<value>
    0xd:
      id: tread
      doc: |
        Yes tram_id,offset
        creates a tram read associated with tram element "tram_id", with a given offset
        Define read: used for defining a TRAM read point
        <symbol> TREAD <lineName>,<Offset>
        The tram read is associated with the delay or lookup line given by "lineName". This must be the same symbol used in defining the delay/lookup line. The Offset indicates an offset from the beginning of the delay/lookup line for which the read will occur.
        "Symbol" will be given the address of the TRAM data register associated with this TRAM read operation. The assembler will create <symbol1>.a which has the address of the TRAM address register.
    0xe:
      id: control
      doc: |
        Yes value,min,max
        Defines a patch manager controllable register with initial value
        Declares a static GPR. The value in the control GPR is modifiable via the new mixer interface. The mixer is informed of the min and max values and will create a slider with value within that range. Upon loading the patch, the GPR is also loaded with the specified initial value.
        Syntax:
        <symbol> CONTROL <initialValue>,<MAX>,<MIN>
        The arguments are 32-bit integer values.
    0xf:
      id: endm
      doc: |
        No
        Ends a Macro
    16:
      id: end
      doc: |
        No
        end of asm file
        The END directive should be placed at the end of the assembly source file. If the END directive is not found, a warning
        will be generated. All text located after the END directive is ignored.
        Syntax:
        [symbol] END      include "foobar.asm"
    17:
      id: include
      doc: |
        No "file_name"
        Include a file
        The include directive is used to include external asm files into the current asm file.
        Syntax:
        INCLUDE <"file name">
        The file name Must be enclosed in ""
    18:
      id: name
      doc: |
        No "string"
        Gives A name to the dsp patch
        Specifies the name of the patch for identification purposes.
    19:
      id: for_loop
      -orig-id: for
      doc: |
        No symbol=start:finish
        Assembly Time 'for' statement
    20:
      id: endfor
      doc: |
        No
        Ends a for loop
    21:
      id: io
    22:
      id: constant
      doc: |
        yes value1,value2,...
        Defines one or more constants
        Declares a constant GPR. Usage of Constant GPR allows for a greater efficient use of GPRs as patch which need access to the same constant will all share this GPR. The sharing is done by the patch loader at load time.
        The patch loader will also use a hardware constant (see the register map) instead if the GPR constant happens to be one of them. (i.e. if you were to declare a constant with value 1, the patch loader would make your dsp program use the hw constant at address 0x41 instead).
        Syntax:
        <symbol> CONSTANT <value>
        or
        <symbol> CON <value>
    23:
      id: con
    24:
      id: nop

seq:
  - id: instr
    type: emu10k_instr(bitness)

instances:
  is_macro:
    value: not instr.opcode_valid
  macro:
    value: instr.opcode.to_i - 16
    if: is_macro
    enum: macro
