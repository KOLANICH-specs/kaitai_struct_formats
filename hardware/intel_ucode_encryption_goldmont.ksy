meta:
  id: intel_ucode_encryption_goldmont
  license: Unlicense
  title: Intel microcode cryptocontainer for Apollo/Gemini Lake and Goldmont, Goldmont Plus and Denverton generations of Atom GPUs
  endian: le
  imports:
    - /common/big_int_le
doc-ref:
  - https://github.com/chip-red-pill/MicrocodeDecryptor
  - https://www.youtube.com/watch?v=V1nJeV0Uq0M
doc: the format of cryptocontainer used in Intel microcode for Apollo Lake and  generation of Atoms.
params:
  - id: is_plus
    type: bool
seq:
  - id: top_header
    -orig-id: hdr30
    size: 0x30
  - id: fmt
    type: fmt
  - id: encrypted
    type:
      switch-on: is_plus
      cases:
        true: encrypted_goldmont_plus
        false: encrypted_goldmont

instances:
  family_specific_secret:
    value: |
      (is_plus?goldmont_plus:goldmont)
  goldmont:
    value: '[0x0e, 0x77, 0xb2, 0x9d, 0x9e, 0x91, 0x76, 0x5d, 0xa2, 0x66, 0x48, 0x99, 0x8b, 0x68, 0x13, 0xab]'
  goldmont_plus:
    value: '[0x83, 0x24, 0x06, 0xff, 0x6b, 0x0b, 0x7f, 0x9c, 0xa4, 0x83, 0x5c, 0x2c, 0x74, 0x62, 0x26, 0x1e]'

types:
  encrypted_goldmont:
    seq:
      - id: encrypted
        doc: |
          Encrypted with RC4 using `rc4.decrypt` (use `encrypt` to decrypt) and offsetting the key stream by 0x200 bytes (encrypt anything, RC4 is a stream cypher)
          key = keyDerive(abX + fmt.nonce + abX) # (`+` for concatenation)
          where `def keyDerive(initialMaterial: bytes) -> bytes` is concatenation of some strange variation of SHA256 of the key material (see `dec_uUpd_Atom_apl.py`)
        size-eos: true

  encrypted_goldmont_plus:
    seq:
      - id: unkn
        size: 28
      - id: patch_size_raw
        -orig-id: patch_size_dw
        type: u4
      - id: encrypted
        type: encrypted_goldmont
        size: enc_size
        doc: |
          end of decrypted data is contains some structure that contains a field for xucode (see `dec_uUpd_xu_Atom_glp.py` for the code scanning for that structure)
      - id: patch_other
        size-eos: true
    instances:
      patch_size:
        value: patch_size_raw * 4
      enc_size:
        value: patch_size - 0x284
        doc: Encrypted data of size calculated from total patch size (0x1c offset)
  fmt:
    -orig-id: fmt
    seq:
      - id: hdr
        -orig-id: hdr
        size: 96
      - id: nonce
        -orig-id: nonce
        size: 32
      - id: signature
        type: signature
    types:
      signature:
        doc: |
          A RSA2048-SHA256 signature (`toLittleEndialInt2048(sha256(data) + b"\x00" + (b"\xFF" * 221) + b"\x01\x00")**privateExponent mod N`) of `hdr + nonce + <decrypted data>[0:i * 64]`
        seq:
          - id: modulus
            -orig-id:
              - modulus
              - n
            size: 256
            type: big_int_le
            doc: |
              SHA256 of it must be
              a1b4b7417f0fdcdb0feaa26eb5b78fb2cb86153f0ce98803f5cb84ae3a45901d for goldmont
              c2e63058bef5bef84cac5319aabbac4095dd11d5f46a51cb0cfbe4641dd87a21 for goldmont plus
          - id: exponent
            -orig-id:
              - exponent
              - e
            type: u4
          - id: signature
            -orig-id:
              - signature
              - ct
            size: 256
            type: big_int_le

  xucode_header:
    seq:
      - id: dec_cmd_id
        -orig-id: xu_dec_cmd_id
        type: u1
        valid: 0x14
      - id: offset
        -orig-id: xu_offset
        type: u4
        valid:
          min: patch_size
      - id: size
        -orig-id: xu_size
        type: u4
        valid:
          min: 0x20
      - id: hacky_check
        size: 0
        valid:
          expr: _.size == 0 and offset + size <= patch_size + patch_other.size()
      - id: hash
        -orig-id: xu_hash
        size: 32
        doc: SHA256(xu_nonce + <decrypted xucode data>)
    instances:
      offset_other:
        -orig-id: xu_offset_other
        value: offset - patch_size
      xu_struct:
        pos: xu_dec_cmd_offset
        type: xu_struct
    types:
      xu_struct:
        doc: Key for decryption is derived using the same algo from the nonce
        seq:
          - id: unkn # patch_other[0:xu_offset_other]
            size: offset_other
          - id: nonce # patch_other[xu_offset_other:0x20]
            size: 0x20 - offset_other
          - id: unkn2 # patch_other[0x20:xu_offset_other + 0x20]
            size: offset_other
          - id: data # patch_other[xu_offset_other + 0x20 : xu_offset_other + xu_size]
            size: size - 0x20
