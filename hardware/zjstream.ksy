meta:
  id: zjstream
  endian: le
  file-extension: zjs
  license: "?"
doc: |
   The SuperPrint Zj driver constructs a stream of bytes which represent a single print job, where a job consists of one or more pages.  Usually, the driver renders a single job into a single "Zj-stream," and copies (collated and uncollated) are cooperatively manufactured by the language monitor and the printer.  The Zj-stream sent to the Zj printer is formatted in a very structured and relatively simple way.
   This document provides a description of the Zj-stream which in effect is the Page Description Language for a Zj-printer.  Using this document, the definitions listed in the INC\ZJRCA.H header file included in the DDK distribution, and an understanding of the JBIG image compression format, it is possible to create print jobs through means other than SuperPrint (from a MacOS system or an external Digital Front-End, for example).
   It is desirable for the driver to optimize the Zj-stream for the target printer.   So, byte swapping may be performed on 16 and 32 bit values within the stream so that the controller always receives these values in its native format.  If the first 4 bytes of the stream are "ZJZJ," then the integer values are little-endian (Intel style).  If the first 4 bytes of the stream are "JZJZ," then the integer values are big-endian (Motorola style).  If the first 4 bytes are anything else, the Zj-stream is invalid.
doc-ref: https://web.archive.org/web/20020830075425/http://ddk.zeno.com/zj_stream.htm
seq:
  - id: signature
    contents: "ZJZJ" # little endian
    #contents: "JZJZ" # big endian
  - id: chunks
    type: chunk
    repeat: eos
types:
  chunk:
    seq:
      - id: header
        type: header
      - id: data
        size: header.chunk_size - 16 # sizeof(header)
    types:
      header:
        seq:
          - id: chunk_size
            type: u4
          - id: chunk_type
            type: u4
            # enum: chunk_type
          - id: dw_param
            type: u4
          - id: zero
            type: u2
          - id: zz
            type: u2
#enums:
#  chunk_type: {}
