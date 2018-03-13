meta:
    id: squashfs
    endian: le
    license: unlicense
seq:
    - id: superblock
        type: superblock
    - id: compression_options
        type: compression_options
    - id: datablocks_and_fragments
        type: datablocks_and_fragments
    - id: inode_table
        type: inode_table
    - id: directory_table
        type: directory_table
    - id: fragment_table
        type: fragment_table
    - id: export_table
        type: fragment_table
    - id: uid_gid_lookup_table
        type: uid_gid_lookup_table
    - id: xattr_table
        type: xattr_table

types:
  super_block_struct:
    seq:
      - id: magic
        contents: [0x45, 0x3D, 0xCD, 0x28]
      