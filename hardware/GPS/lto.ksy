meta:
  id: lto
  file-extension: dat
  title: Broadcom Long Term Orbits (for now v1)
  endian: le
  license: Unlicense
doc: |
  Broadcom Long Term Orbits is a file downloaded from [Broadcom servers](https://gllto{,1,2}.glpals.com/{2,4,7,30}day/{,glo/}v{2,3,4,5,6}/latest/lto2.dat) ([in fact it is Amazon S3 cloud](https://gllto.glpals.com/)) and passed into GPS receiver to allow it work with Assisted GPS. The format is totally undocumented and I have found no references of it in the Net.
  
  2017-10-02/v1.2 lto.dat:
  DECIMAL       HEXADECIMAL     DESCRIPTION
  --------------------------------------------------------------------------------
  56            0x38            Raw deflate compression stream
  85            0x55            Raw deflate compression stream
  93            0x5D            Raw deflate compression stream
  101           0x65            Raw deflate compression stream
  120           0x78            Raw deflate compression stream
  184           0xB8            Raw deflate compression stream
  325           0x145           Raw deflate compression stream
  333           0x14D           Raw deflate compression stream
  341           0x155           Raw deflate compression stream
  349           0x15D           Raw deflate compression stream
  376           0x178           Raw deflate compression stream
  440           0x1B8           Raw deflate compression stream
  504           0x1F8           Raw deflate compression stream
  741           0x2E5           Raw deflate compression stream
  788           0x314           Raw deflate compression stream
  859           0x35B           Raw deflate compression stream
  879           0x36F           Raw deflate compression stream
  924           0x39C           Raw deflate compression stream
  1050          0x41A           Raw deflate compression stream
  1052          0x41C           Raw deflate compression stream
  1057          0x421           Raw deflate compression stream
  1063          0x427           Raw deflate compression stream
  1333          0x535           Raw deflate compression stream
  1376          0x560           Raw deflate compression stream
  1723          0x6BB           Raw deflate compression stream
  1732          0x6C4           Raw deflate compression stream
  1738          0x6CA           Raw deflate compression stream
  1808          0x710           Raw deflate compression stream
  1874          0x752           Raw deflate compression stream
  1879          0x757           Raw deflate compression stream
  
seq:
  - id: signature
    type: u4
  - id: unkn0
    type: u4
  - id: unkn1
    type: u4
  - id: unkn2
    size: 16
  - id: unkn3
    type: u4
  - id: unkn4
    type: u4
    
  - id: unkn_two_u4_recs_0_len
    type: u4
  - id: unkn_two_u4_recs_0
    type: two_u4_rec_first
    repeat: expr
    repeat-expr: unkn_two_u4_recs_0_len
  - id: unkn_payload_with_size_1
    type: payload_with_size
    repeat: expr
    repeat-expr: unkn_two_u4_recs_0_len
    
  - id: unkn5
    type: u4
  - id: unkn6
    type: u4
  - id: unkn7
    type: u4
  - id: unkn8
    type: u4
    
  - id: unkn_two_u4_recs_1_len
    type: u4
  - id: unkn_two_u4_recs_1
    type: two_u4_rec_second
    repeat: expr
    repeat-expr: unkn_two_u4_recs_1_len
    
  - id: unkn_two_u4_recs_2_len
    type: u4
  - id: unkn_two_u4_recs_2
    type: two_u4_rec_third
    repeat: expr
    repeat-expr: unkn_two_u4_recs_2_len

  - id: unkn9
    type: payload_with_size
    repeat: expr
    # 65      +4.679842862451558 *days
    # 65      +4.6303571428571431*days
    # 64.60779+4.7211724345238109*days
    repeat-expr: 74 # {1-5}.2.lto.dat
    #repeat-expr: 84 # {1-5}.4.lto.dat
    #repeat-expr: 97 # {1-5}.7.lto.dat
    #repeat-expr: 206 # 2.30.lto.dat
  
  - id: unkn10
    type: u4
  - id: unkn11
    type: u4
  - id: unkn12
    type: u4
  
  - id: unkn_13
    size: 4
  - id: unkn_14
    size: 4
  - id: unkn_15
    size: 22
  
  - id: unkn_16
    type: payload_144
    repeat: expr
    repeat-expr: 8
  
types:
  two_u4_rec:
    #just 2 int record, may be different types
    seq:
      - id: unkn0
        type: u4
        repeat: expr
        repeat-expr: 2

  two_u4_rec_first:
    seq:
      - id: unkn0
        type: first
      - id: unkn1
        type: second
    types:
      first:
        seq:
          - id: unkn0
            type: u1
            doc: likely a number. 2 MSBs are not present in files.
          - id: unkn2
            type: b24
            doc: maybe flags (mostly empty)
      second:
        seq:
          - id: ctr0
            type: b2
            doc: 0, 1, 2, 3 counter
          - id: ctr1
            type: b4
            doc: some counter
          - id: unkn2
            type: b6
            doc: empty, likely flags or unused counter bits
          - id: ctr2
            type: b4
            doc: yet another counter
          - id: unkn4
            type: b16
            doc: empty

  two_u4_rec_second:
    seq:
      - id: unkn0
        type: first
      - id: unkn1
        type: second
    types:
      first:
        seq:
          - id: unkn0
            type: b2
            doc: empty
          - id: ctr0
            type: b6
            doc: maybe some int
          - id: unkn2
            type: b24
            doc: maybe flags (mostly empty)
      second:
        seq:
          - id: ctr0
            type: b2
            doc: increasing counter
          - id: ctr1
            type: b4
            doc: increasing counter
          - id: unkn2
            type: b2
            doc: maybe flags (empty)
          - id: unkn3
            type: b3
            doc: maybe flags or leading bits of next counter
          - id: ctr2
            type: b5
            doc: increasing counter
          - id: unkn4
            type: b16
            doc: zeros

  two_u4_rec_third:
    seq:
      - id: unkn0
        type: first
      - id: unkn1
        type: second
    types:
      first:
        seq:
          - id: ctr0
            type: b2
            doc: maybe some int
          - id: flags0
            type: b2
            doc: maybe flags?
          - id: flags1
            type: b4
            doc: maybe flags too? They are usually empty
          - id: ctr1
            type: b3
            doc: maybe some int
          - id: mess3
            type: b5
            doc: some mess
          - id: ctr2
            type: u1
          - id: flags
            type: u1
      second:
        seq:
          - id: ctr0
            type: b2
            doc: strange sequence, kinda counter but sometimes numbers are skipped
          - id: ctr1
            type: b2
            doc: incrementing counter
          - id: flags0
            type: b4
            doc: mostly empty, but in the first one MSB is set
          - id: ctr2
            type: b3
            doc: incr counter, increased not every tick
          - id: unkn2
            type: b5
            doc: nums
          - id: unkn3
            type: b6
            doc: usually empty, may be flags
          - id: unkn4
            type: b2
            doc: maybe flags
          - id: unkn5
            type: b8
            doc: usually empty

  payload_with_size:
    seq:
      - id: size
        type: u4
      - id: payload
        size: size
        #type: u4
        #repeat: expr
        #repeat-expr: size/4
    #types:
    #  payload:
    #    seq:
    #      - id: record
    #        #type: b6 # maybe?

  payload_144:
    seq:
      - id: payload
        type: u2
        repeat: expr
        repeat-expr: 72
