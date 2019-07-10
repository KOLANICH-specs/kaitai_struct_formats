meta:
  id: ftdi232
  title: FTDI232 protocol
  endian: le
  license: MIT
  xref:
    wikidata: Q2561478
doc: |
  Protocol for FTDI232 chips.
  Most of the stuff is set via control transactions, data is usually passed as control transaction arguments: value and index. Obviously, Kaitai Struct cannot describe protocols where the data is transfered in fields of other protocols, we need a separate Verilog-based DSL for that.
  But sometimes the stuff is set up as control commands payload.

doc-ref:
  - https://github.com/felHR85/UsbSerial

seq:
instances:
  bit_clock_freq:
    value: 3000000
types:
  command:
    seq:
      - id: opcode
        type: u1
        enum: opcode
      - id: arguments
        type:
          switch-on: opcode
          cases:
            'opcode::set_bits_low': set_bits_low_args
            'opcode::drive_zero': drive_zero_args
            #'opcode::loopback_end': #no args
  set_bits_low_args:
    seq:
      - id: bits
        type: u1
      - id: direction
        type: u1
  drive_zero_args:
    seq:
      - id: lines
        type: u2
  mpsse_do_read_args:
    seq:
      - id: count_minus_1
        type: u2
    instances:
      count:
        value: count_minus_1 + 1
  mpsse_do_write_args:
    seq:
      - id: count_minus_1
        type: u2
      - id: bytes
        size: count
    instances:
      count:
        value: count_minus_1 + 1
  baud_rate_to_old_freq_divisor:
    params:
      - id: baud_rate
        type: u4
    instances:
      freq_divisor:
        value: "_root.bit_clock_freq//baud_rate"
      ftdi_freq_divisor:
        value: "freq_divisor | (baud_rate >= 0x80000?(baud_rate >= 0x100000 ? (baud_rate >= 0x200000?0x20000:0x10000):0x8000):(baud_rate >= 0x40000?0x4000:0))"
  old_freq_divisor_to_baud_rate:
    params:
      - id: ftdi_freq_divisor
        type: u4
    instances:
      baud_rate:
        value: "_root.bit_clock_freq//(freq_divisor & 0x2FFF)"
enums:
  opcode:
    0x80:
      id: set_bits_low
      -orig-id: SET_BITS_LOW

    0x82:
      id: set_bits_high
      -orig-id: SET_BITS_HIGH

    0x81:
      id: get_bits_low
      -orig-id: GET_BITS_LOW

    0x83:
      id: get_bits_high
      -orig-id: GET_BITS_HIGH

    0x84:
      id: loopback_start
      -orig-id: LOOPBACK_START

    0x85:
      id: loopback_end
      -orig-id: LOOPBACK_END

    0x86:
      id: set_tck_divisor
      -orig-id: SET_TCK_DIVISOR

    0x8C:
      id: enable_clk_3phase
      -orig-id: ENABLE_CLK_3PHASE

    0x8D:
      id: disable_clk_3phase
      -orig-id: DISABLE_CLK_3PHASE

    0x8E:
      id: clk_bits_no_data
      -orig-id: CLK_BITS_NO_DATA

    0x8F:
      id: clk_bytes_no_data
      -orig-id: CLK_BYTES_NO_DATA

    0x94:
      id: clk_wait_on_high
      -orig-id: CLK_WAIT_ON_HIGH

    0x95:
      id: clk_wait_on_low
      -orig-id: CLK_WAIT_ON_LOW

    0x96:
      id: enable_clk_adaptive
      -orig-id: ENABLE_CLK_ADAPTIVE

    0x97:
      id: disable_clk_adaptive
      -orig-id: DISABLE_CLK_ADAPTIVE

    0x9C:
      id: clk_count_wait_on_high
      -orig-id: CLK_COUNT_WAIT_ON_HIGH

    0x9D:
      id: clk_count_wait_on_low
      -orig-id: CLK_COUNT_WAIT_ON_LOW

    0x9E:
      id: drive_zero
      -orig-id: DRIVE_ZERO

  sio_bitmode:
    0x00:
      id: bitmode_reset
      -orig-id: BITMODE_RESET

    0x01:
      id: bitmode_bitbang
      -orig-id: BITMODE_BITBANG

    0x02:
      id: bitmode_mpsse
      -orig-id: BITMODE_MPSSE

    0x04:
      id: bitmode_syncbb
      -orig-id: BITMODE_SYNCBB

    0x08:
      id: bitmode_mcu
      -orig-id: BITMODE_MCU

    0x10:
      id: bitmode_opto
      -orig-id: BITMODE_OPTO

    0x20:
      id: bitmode_cbus
      -orig-id: BITMODE_CBUS

    0x40:
      id: bitmode_syncff
      -orig-id: BITMODE_SYNCFF

    0x7F:
      id: bitmode_mask
      -orig-id: BITMODE_MASK
  
  sio:
    0:
      id: reset
      -orig-id: SIO_RESET

    1:
      id: set_modem_ctrl
      -orig-id: SIO_SET_MODEM_CTRL

    2:
      id: set_flow_ctrl
      -orig-id: SIO_SET_FLOW_CTRL

    3:
      id: set_baudrate
      -orig-id: SIO_SET_BAUDRATE

    4:
      id: set_data
      -orig-id: SIO_SET_DATA

    5:
      id: poll_modem_status
      -orig-id: SIO_POLL_MODEM_STATUS

    6:
      id: set_event_char
      -orig-id: SIO_SET_EVENT_CHAR

    7:
      id: set_error_char
      -orig-id: SIO_SET_ERROR_CHAR

    9:
      id: set_latency_timer
      -orig-id: SIO_SET_LATENCY_TIMER

    10:
      id: get_latency_timer
      -orig-id: SIO_GET_LATENCY_TIMER

    11:
      id: set_bitmode
      -orig-id: SIO_SET_BITMODE

    12:
      id: read_pins
      -orig-id: SIO_READ_PINS

    0x90:
      id: read_eeprom
      -orig-id: SIO_READ_EEPROM

    0x91:
      id: write_eeprom
      -orig-id: SIO_WRITE_EEPROM

    0x92:
      id: erase_eeprom
      -orig-id: SIO_ERASE_EEPROM


  sio_reset:
    0:
      id: reset_sio
      -orig-id: SIO_RESET_SIO

    1:
      id: reset_purge_rx
      -orig-id: SIO_RESET_PURGE_RX

    2:
      id: reset_purge_tx
      -orig-id: SIO_RESET_PURGE_TX


  sio_flow_control:
    0x0:
      id: disable_flow_ctrl
      -orig-id: SIO_DISABLE_FLOW_CTRL

    0x100:
      id: rts_cts_hs
      -orig-id: SIO_RTS_CTS_HS

    0x200:
      id: dtr_dsr_hs
      -orig-id: SIO_DTR_DSR_HS

    0x400:
      id: xon_xoff_hs
      -orig-id: SIO_XON_XOFF_HS

    0x1:
      id: set_dtr_mask
      -orig-id: SIO_SET_DTR_MASK

    0x101:
      id: set_dtr_high
      -orig-id: SIO_SET_DTR_HIGH

    0x100:
      id: set_dtr_low
      -orig-id: SIO_SET_DTR_LOW

    0x2:
      id: set_rts_mask
      -orig-id: SIO_SET_RTS_MASK

    0x202:
      id: set_rts_high
      -orig-id: SIO_SET_RTS_HIGH

    0x200:
      id: set_rts_low
      -orig-id: SIO_SET_RTS_LOW
