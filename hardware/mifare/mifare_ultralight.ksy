meta:
  id: mifare_ultralight
  endian: le
  file-extension: mfd
  title: "Mifare Ultralight RFID tag dump"
  license: BSD-2-Clause
doc-ref: |
  https://github.com/nfc-tools/libnfc
seq:
  - id: sectors
    type: sector
    repeat: eos
types:
  key:
    seq:
      - id: key
        size: 6
  sector:
    params:
      - id: idx
        type: u1
    seq:
      - id: manufacturer
        type: manufacturer
        if: has_manufacturer
      
      - id: data
        -orig-id: abtData
        size: _io.size - _io.pos - 16 # sizeof(trailer)
    instances:
      has_manufacturer:
        value: idx == 0
    
  manufacturer:
    seq:
      - id: sn0
        type: u3
      - id: bcc0
        -orig-id: btBCC0
        type: u1
      - id: sn1
        type: u4
      - id: bcc1
        -orig-id: btBCC1
        type: u1
      - id: internal
        type: u1
      - id: lock
        type: u2
      - id: otp
        type: u4
