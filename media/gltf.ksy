meta:
  id: gltf
  application: Khronos GLTF binary format
  license: Unlicense
  endian: le
  encoding: utf-8
  xref:
    mime: "model/gltf-binary"
doc: |
  Implements Khronos GLTF format
seq:
  - id: signature
    -orig-id: magic
    contents: ["glTF"]
  - id: version
    type: u4
    doc: "2"
  - id: total_size
    -orig-id: length
    type: u4
  - id: chunks
    type: chunks
    size: chunks_size
instances:
  chunks_size:
    value: total_size - 8
types:
  chunks:
    seq:
      - id: chunks
        type: chunk
        repeat: eos
  chunk:
    seq:
      - id: size
        -orig-id: chunkLength
        type: u4
      - id: type
        -orig-id: chunkType
        type: strz
        size: 4
      - id: data
        -orig-id: chunkData
        size: size
        type:
          switch-on: type
          cases:
            "'JSON'": str
            #"'BIN'": bin
enums:
  component_type:
    0x1400:
      id: s1
      -orig-id: GL_BYTE
    0x1401:
      id: u1
      -orig-id: GL_UNSIGNED_BYTE
    0x1402:
      id: s2
      -orig-id: GL_SHORT
    0x1403:
      id: u2
      -orig-id: GL_UNSIGNED_SHORT
    0x1404:
      id: s4
      -orig-id: GL_INT
    0x1405:
      id: u4
      -orig-id: GL_UNSIGNED_INT
    0x1406:
      id: f4
      -orig-id: GL_FLOAT
    0x140A:
      id: f8
      -orig-id: GL_DOUBLE
