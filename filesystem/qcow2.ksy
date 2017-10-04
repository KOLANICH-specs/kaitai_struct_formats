meta:
  id: qcow2
  title: QEMU Copy-on-Write 2
  application:
    - QEMU
    - VirtualBox
    - VMWare Workstation
    - libqcow
  file-extension: qcow
  xref:
    forensicswiki: QCOW_Image_Format
    wikidata: Q1052000
  endian: be
  encoding: utf-8
  license: GPL3.0+
doc: |
  A native QEMU image file format.
  A qcow2 image file is organized in units of constant size, which are called (host) clusters. A cluster is the unit in which all allocations are done, both for actual guest data and for image metadata.
  Likewise, the virtual disk as seen by the guest is divided into (guest) clusters of the same size.
  If the image has a backing file then the backing file name should be stored in the remaining space between the end of the header extension area and the end of the first cluster. It is not allowed to store other data here, so that an implementation can safely modify the header and add extensions without harming data of compatible features that it doesn't support. Compatible features that need space for additional data can use a header extension.
doc-ref:
  - https://github.com/qemu/qemu/blob/master/docs/interop/qcow2.txt
  - https://github.com/qemu/qemu/blob/master/block/qcow2.h
  - https://github.com/qemu/qemu/blob/master/block/qcow2.c
  - https://www.virtualbox.org/svn/vbox/trunk/src/VBox/Storage/QCOW.cpp
seq:
  - id: header
    type: header
  - id: header_extensions
    type: header_extension
    repeat: until
    repeat-until: _.type == header_extension_type::end
instances:
  refcount_table:
    doc: |
      qcow2 manages the allocation of host clusters by maintaining a reference count for each host cluster. A refcount of 0 means that the cluster is free, 1 means that it is used, and >= 2 means that it is used and any write access must perform a COW (copy on write) operation.
      The refcounts are managed in a two-level table. The first level is called refcount table and has a variable size (which is stored in the header). The refcount table can cover multiple clusters, however it needs to be contiguous in the image file.
      It contains pointers to the second level structures which are called refcount blocks and are exactly one cluster in size.
    pos: header.refcount_table_offset
    type: refcount_table_entry
    repeat: expr
    repeat-expr: header.refcount_table_clusters * header.cluster_size_bytes / 8
  l1_table:
    doc: |
      Just as for refcounts, qcow2 uses a two-level structure for the mapping of guest clusters to host clusters. They are called L1 and L2 table.
      The L1 table has a variable size (stored in the header) and may use multiple clusters, however it must be contiguous in the image file.
    pos: header.l1_table_offset
    type: header.l1_table_entry
    repeat: expr
    repeat-expr: header.l1_size
  clusters:
    pos: 0
    type: cluster
    repeat: eos
#  disk:
#    type: virtual_cluster(_index)
#    repeat: expr
#    repeat-expr: ?
types:
  bit_count_u4:
    doc: computes size by bits shifts
    seq:
      - id: bits
        type: u4
    instances:
      value:
        value: 1 << bits
  bit_count_u1:
    doc: computes size by bits shifts
    seq:
      - id: bits
        type: u1
    instances:
      value:
        value: 1 << bits

  header:
    seq:
      - id: magic
        contents: QFIû
      - id: version
        type: u4
        doc: Version number (valid values are 2 and 3)
      - id: backing_file_offset
        type: u8
        doc: "Offset into the image file at which the backing file name is stored (NB: The string is not null terminated). 0 if the image doesn't have a backing file."
      - id: backing_file_size
        type: u4
        doc: Length of the backing file name in bytes. Must not be longer than 1023 bytes. Undefined if the image doesn't have a backing file.
      - id: cluster_size_bits
        type: bit_count
        doc: |
          Number of bits that are used for addressing an offset within a cluster. Must not be less than 9 (i.e. 512 byte clusters).
          Note: qemu as of today has an implementation limit of 2 MB as the maximum cluster size and won't be able to open images with larger cluster sizes.
      - id: size
        type: u8
        doc: Virtual disk size in bytes
      - id: crypt_method
        type: u4
        enum: crypt_method
      - id: l1_size
        type: u4
        doc: Number of entries in the active L1 table
      - id: l1_table_offset
        type: u8
        doc: Offset into the image file at which the active L1 table starts. Must be aligned to a cluster boundary.
      - id: refcount_table_offset
        type: u8
        doc: Offset into the image file at which the refcount table starts. Must be aligned to a cluster boundary.
      - id: refcount_table_clusters
        type: u4
        doc: Number of clusters that the refcount table occupies
      - id: nb_snapshots
        type: u4
        doc: Number of snapshots contained in the image
      - id: snapshots_offset
        type: u8
        doc: Offset into the image file at which the snapshot table starts. Must be aligned to a cluster boundary.

      - id: incompatible_features
        type: incompatible_features
        doc: Bitmask of incompatible features. An implementation must fail to open an image if an unknown bit is set.
        if: version >= 3
      - id: compatible_features
        type: compatible_features
        doc: Bitmask of compatible features. An implementation can safely ignore any unknown bits that are set.
        if: version >= 3
      - id: autoclear_features
        type: autoclear_features
        doc: Bitmask of auto-clear features. An implementation may only write to an image with unknown auto-clear features if it clears the respective bits from this field first.
        if: version >= 3

      - id: refcount_bit_size_bits
        type: bit_count
        doc: For version 2 images, the order is always assumed to be 4 (i.e. _root.header.refcount_bit_size_bits.value = 16). This value may not exceed 6 (i.e. _root.header.refcount_bit_size_bits.value = 64).
        if: version >= 3

      - id: header_length
        type: u4
        doc: Length of the header structure in bytes. For version 2 images, the length is always assumed to be 72 bytes.
        if: version >= 3
    instances:
      cluster_size_bytes:
        value: cluster_size_bits.value / 8
      refcount_block_entries_count:
        -orig-id: refcount_block_entries
        value: cluster_size_bits.value * 8 / refcount_bit_size_bits.value
      l2_entries_count:
        -orig-id: l2_entries
        value: cluster_size_bits.value / sizeof(uint64_t)
      snapshot_table:
        doc: |
          qcow2 supports internal snapshots. Their basic principle of operation is to switch the active L1 table, so that a different set of host clusters are exposed to the guest.
          When creating a snapshot, the L1 table should be copied and the refcount of all L2 tables and clusters reachable from this L1 table must be increased, so that a write causes a COW and isn't visible in other snapshots.
          When loading a snapshot, bit 63 of all entries in the new active L1 table and all L2 tables referenced by it must be reconstructed from the refcount table as it doesn't need to be accurate in inactive L1 tables.
        pos: snapshots_offset
        type: snapshot_table
        repeat: expr
        repeat-expr: nb_snapshots
    types:
      incompatible_features:
        seq:
          - id: dirty
            type: b1
            doc: If this bit is set then refcounts may be inconsistent, make sure to scan L1/L2 tables to repair refcounts before accessing the image.
          - id: corrupt
            type: b1
            doc: If this bit is set then any data structure may be corrupt and the image must not be written to (unless for regaining consistency).
          - id: reserved
            type: b62
      compatible_features:
        seq:
          - id: lazy_refcounts
            type: b1
            doc: If this bit is set then lazy refcount updates can be used.  This means marking the image file dirty and postponing refcount metadata updates.
          - id: reserved
            type: b63
      autoclear_features:
        seq:
          - id: bitmaps_extension
            type: b1
            doc: |
              This bit indicates consistency for the bitmaps extension data.
              It is an error if this bit is set without the bitmaps extension present.
              If the bitmaps extension is present but this bit is unset, the bitmaps extension data must be  considered inconsistent.
          - id: reserved
            type: b63
    enums:
      crypt_method:
        0: none

        1: aes_256_cbc # Initialization vectors generated using plain64 method, with the virtual disk sector as the input tweak. This format is no longer supported in QEMU system emulators, due to a number of design flaws affecting its security. It is only supported in the command line tools for the sake of back compatibility and data liberation.

        2: luks #The algorithms are specified in the LUKS header. Initialization vectors generated using the method specified in the LUKS header, with the physical disk sector as the input tweak.
  header_extension:
    doc: |
      Unless stated otherwise, each header extension type shall appear at most once in the same image.
      If the image has a backing file then the backing file name should be stored in the remaining space between the end of the header extension area and the end of the first cluster. It is not allowed to store other data here, so that an implementation can safely modify the header and add extensions without harming data of compatible features that it doesn't support. Compatible features that need space for additional data can use a header extension.
    seq:
      - id: type
        type: u4
        enum: type
      - id: length
        type: u4
      - id: data
        size: length
        type:
          switch-on: type
          cases:
            header_extension_type::feature_name_table: feature_name_table
            header_extension_type::bitmaps: bitmaps
            header_extension_type::full_disk_encryption_header: fde_header_ptr
    types:
      feature_name_table:
        doc: The feature name table is an optional header extension that contains the name for features used by the image. It can be used by applications that don't know the respective feature (e.g. because the feature was introduced only later) to display a useful error message.
        seq:
          - id: entries
            type: feature
            repeat: eos
        types:
          feature:
            seq:
              - id: type
                type: u1
                enum: type
                doc: Type of feature (select feature bitmap)
              - id: bit_number
                type: u1
                doc: 'Bit number within the selected feature bitmap (valid values: 0-63)'
              - id: name
                type: 46
                doc: Feature name (padded with zeros, but not necessarily null terminated if it has full length)

            enums:
              type:
                0: incompatible
                1: compatible
                2: autoclear
      bitmaps:
        doc: |
          The bitmaps extension is an optional header extension. It provides the ability to store bitmaps related to a virtual disk. For now, there is only one bitmap type: the dirty tracking bitmap, which tracks virtual disk changes from some point in time.
          The data of the extension should be considered consistent only if the corresponding auto-clear feature bit is set, see autoclear_features above.
          All stored bitmaps are related to the virtual disk stored in the same image, so each bitmap size is equal to the virtual disk size.
          Each bit of the bitmap is responsible for strictly defined range of the virtual disk. For bit number bit_nr the corresponding range (in bytes) will be:
            [bit_nr * bitmap_granularity .. (bit_nr + 1) * bitmap_granularity - 1]
          Granularity is a property of the concrete bitmap, see below.
        seq:
          - id: nb_bitmaps
            type: u4
            doc: |
              The number of bitmaps contained in the image. Must be greater than or equal to 1.
              Note: Qemu currently only supports up to 65535 bitmaps per image.
          - id: reserved
            type: u4
          - id: bitmap_directory_len
            type: u4
            doc: Size of the bitmap directory in bytes. It is the cumulative size of all (nb_bitmaps) bitmap directory entries.
          - id: bitmap_directory_offset
            type: u4
            doc: Offset into the image file at which the bitmap directory starts. Must be aligned to a cluster boundary.
        instances:
          bitmap_directory:
            doc: Each bitmap saved in the image is described in a bitmap directory entry. The bitmap directory is a contiguous area in the image file, whose starting offset and length are given by the header extension fields bitmap_directory_offset and . The entries of the bitmap directory have variable length, depending on the lengths of the bitmap name and extra data.
            pos: bitmap_directory_offset
            type: bitmap_directory_entry
            repeat: expr
            repeat-expr: bitmap_directory_len
        types:
          bitmap_directory_entry:
            seq:
              - id: bitmap_table_offset
                type: u8
                doc: Offset into the image file at which the bitmap table (described below) for the bitmap starts. Must be aligned to a cluster boundary.
              - id: bitmap_table_len
                -orig-id: bitmap_table_size
                type: u4
                doc: Number of entries in the bitmap table of the bitmap.
              - id: flags
                type: flags
              - id: type
                type: u1
                enum: type
              - id: granularity_bits
                type: bit_count_u1
                doc: |
                  A bitmap's granularity is how many bytes of the image accounts for one bit of the bitmap.
                  Valid values: 0 - 63.
                  Note: Qemu currently supports only values 9 - 31.
              - id: name_size
                type: u2
                docs: |
                  Size of the bitmap name. Must be non-zero.
                  Note: Qemu currently doesn't support values greater than 1023.
              - id: extra_data_size
                type: u4
                docs: |
                  Size of type-specific extra data.
                  For now, as no extra data is defined, extra_data_size is reserved and should be zero. If it is non-zero the behavior is defined by extra_data_compatible flag.
              - id: extra_data
                size: extra_data_size
                doc: Extra data for the bitmap. Must never contain references to clusters or in some other way allocate additional clusters.
              - id: name
                type: str
                size: extra_data_size
                doc: The name of the bitmap (not null terminated). Must be unique among all bitmap names within the bitmaps extension.
              #Padding to round up the bitmap directory entry size to the next multiple of 8. All bytes of the padding must be zero.
            instances:
              bitmap_table:
                doc: |
                  Each bitmap is stored using a one-level structure (as opposed to two-level structures like for refcounts and guest clusters mapping) for the mapping of bitmap data to host clusters. This structure is called the bitmap table.
                  Each bitmap table has a variable size (stored in the bitmap directory entry) and may use multiple clusters, however, it must be contiguous in the image file.
                pos: bitmap_table_offset
                type: bitmap_table_entry
                repeat: expr
                repeat-expr: bitmap_table_len
            types:
              flags:
                seq:
                  - id: in_use
                    type: b1
                    doc: The bitmap was not saved correctly and may be inconsistent.
                  - id: auto
                    type: b1
                    doc: |
                      In the image file the 'enabled' state is reflected by the 'auto' flag. 
                      If this flag is set, the software must consider the bitmap as 'enabled' and start tracking virtual disk changes to this bitmap from the first write to the virtual disk. If this flag is not set then the bitmap is disabled.
                      The bitmap must reflect all changes of the virtual disk by any application that would write to this qcow2 file (including writes, snapshot switching, etc.). The type of this bitmap must be 'dirty tracking bitmap'.
                  - id: extra_data_compatible
                    type: b1
                    doc: |
                      This flags is meaningful when the extra data is unknown to the software (currently any extra data is unknown to Qemu).
                      If it is set, the bitmap may be used as expected, extra data must be left as is.
                      If it is not set, the bitmap must not be used, but both it and its extra data be left as is.
                  - id: reserved
                    type: b29

              bitmap_table_entry:
                seq:
                  - id: reserved0_or_flag
                    type: b1
                    doc: |
                      Reserved and must be zero if bits 9 - 55 are non-zero.
                      If bits 9 - 55 are zero:
                        0: Cluster should be read as all zeros.
                        1: Cluster should be read as all ones.
                  - id: reserved1
                    type: u1
                  - id: host_cluster_offset
                    type: b47
                    doc: Must be aligned to a cluster boundary. If the offset is 0, the cluster is unallocated; in that case, bit 0 determines how this cluster should be treated during reads.
                  - id: reserved2
                    type: u1
            enums:
              type:
                1: dirty_tracking
                # Bitmaps with 'type' field equal to one are dirty tracking bitmaps.
                # When the virtual disk is in use dirty tracking bitmap may be 'enabled' or 'disabled'. While the bitmap is 'enabled', all writes to the virtual disk should be reflected in the bitmap. A set bit in the bitmap means that the corresponding range of the virtual disk (see above) was written to while the bitmap was 'enabled'. An unset bit means that this range was not written to.
                # The software doesn't have to sync the bitmap in the image file with its representation in RAM after each write. Flag 'in_use' should be set while the bitmap is not synced.
          image_offset:
            params:
              - id: bitmap_data_offset
                type: u8
            instances:
              table_index:
                value: bitmap_data_offset / _root.header.cluster_size_bits.value
              offset_rel_to_entry:
                value: (bitmap_data_offset % _root.header.cluster_size_bits.value)
              image_offset:
                value: bitmap_table[table_index] + offset_rel_to_entry

          bit_offset:
            params:
              - id: byte_nr
                type: u8
            instances:
              relative_offset:
                value: (byte_nr / granularity) % 8
              bit_offset:
                doc: |
                  Given an offset (in bytes) byte_nr into the bitmap data and the bitmap's granularity, the bit offset into the image file to the corresponding bit of the bitmap
                  This offset is not defined if bits 9 - 55 of bitmap table entry are zero.
                  If the size of the bitmap data is not a multiple of the cluster size then the last cluster of the bitmap data contains some unused tail bits. These bits must be zero.
                value: image_offset(byte_nr / granularity / 8) * 8 + relative_offset
      fde_header_ptr:
        doc: |
          The full disk encryption header must be present if, and only if, the 'crypt_method' header requires metadata. Currently this is only true of the 'LUKS' crypt method. The header extension must be absent for other methods.
          This header provides the offset at which the crypt method can store its additional data, as well as the length of such data.
        seq:
          - id: offset
            type: u8
            doc: Offset into the image file at which the encryption header starts in bytes. Must be aligned to a cluster boundary.
          - id: size
            type: u8
            doc: Length of the written encryption header in bytes. Note actual space allocated in the qcow2 file may be larger than this value, since it will be rounded to the nearest multiple of the cluster size. Any unused bytes in the allocated space will be initialized to 0.
        instances:
          fde_header:
            pos: offset
            size: size
            type:
              switch-on: _root.header.crypt_method
              cases:
                _root::header::crypt_method::luks: luks
                _root::header::crypt_method::aes_256_cbc: aes_256_cbc
        types:
          luks:
            seq:
              - id: partition_header
                size: 592
                type: LUKS partition header (find import)
              - id: key material data areas
                doc: |
                  The size of the key material data areas is determined by the number of stripes in the key slot and key size. Refer to the LUKS format specification ('docs/on-disk-format.pdf' in the cryptsetup source package) for details of the LUKS partition header format.
                  In the LUKS partition header, the "payload-offset" field will be calculated as normal for the LUKS spec. ie the size of the LUKS header, plus key material regions, plus padding, relative to the start of the LUKS header. This offset value is not required to be qcow2 cluster aligned. Its value is currently never used in the context of qcow2, since the qcow2 file format itself defines where the real payload offset is, but none the less a valid payload offset should always be present.
                  In the LUKS key slots header, the "key-material-offset" is relative to the start of the LUKS header clusters in the qcow2 container, not the start of the qcow2 file.
                  Logically the layout looks like
                    +-----------------------------+
                    | QCow2 header        |
                    | QCow2 header extension X  |
                    | QCow2 header extension FDE  |
                    | QCow2 header extension ...  |
                    | QCow2 header extension Z  |
                    +-----------------------------+
                    | ....other QCow2 tables....  |
                    .               .
                    .               .
                    +-----------------------------+
                    | +-------------------------+ |
                    | | LUKS partition header   | |
                    | +-------------------------+ |
                    | | LUKS key material 1   | |
                    | +-------------------------+ |
                    | | LUKS key material 2   | |
                    | +-------------------------+ |
                    | | LUKS key material ...   | |
                    | +-------------------------+ |
                    | | LUKS key material 8   | |
                    | +-------------------------+ |
                    +-----------------------------+
                    | QCow2 cluster payload     |
                    .               .
                    .               .
                    .               .
                    |               |
                    +-----------------------------+
  snapshot_table_entry:
    seq:
      - id: offset
        type: u8
        doc: Offset into the image file at which the L1 table for the snapshot starts. Must be aligned to a cluster boundary.
      - id: count
        type: u4
        doc: Number of entries in the L1 table of the snapshots
      - id: id_str_len
        type: u2
        doc: Length of the unique ID string describing the snapshot
      - id: name_len
        type: u2
        doc: Length of the name of the snapshot
      - id: timestamp_seconds_part
        type: u4
        doc: Time at which the snapshot was taken in seconds since the Epoch
      - id: timestamp_nanoseconds_part
        type: u4
        doc: Subsecond part of the time at which the snapshot was taken in nanoseconds
      - id: total_runned_nanoseconds
        type: u8
        doc: Time that the guest was running until the snapshot was taken in nanoseconds
      - id: state_size
        type: u4
        doc: Size of the VM state in bytes. 0 if no VM state is saved. If there is VM state, it starts at the first cluster described by first L1 table entry that doesn't describe a regular guest cluster (i.e. VM state is stored like guest disk content, except that it is stored at offsets that are larger than the virtual disk presented to the guest)
      - id: extra_data_size
        type: u4
        doc: Size of extra data in the table entry (used for future extensions of the format)
      - id: extra_data
        size: extra_data_size
        type: extra_data
      - id: id_str
        type: str
        size: id_str_len
      - id: name
        type: str
        size: name_len
      #Padding to round up the snapshot table entry size to the next multiple of 8.
    types:
      extra_data:
        doc: Extra data for future extensions. Unknown fields must be ignored.
        seq:
          - id: state_size_bytes
            type: u8
            doc: Size of the VM state in bytes. 0 if no VM state is saved. If this field is present, the 32-bit value in bytes 32-35 is ignored.
          - id: disk_size
            type: u8
            doc: Virtual disk size of the snapshot in bytes

  refcount_table_entry:
    seq:
      - id: reserved
        type: u1
      - id: offset_7_bytes
        type: u7
        doc: |
          Bits 9-63 of the offset into the image file at which the refcount block starts. Must be aligned to a cluster boundary.
          If this is 0, the corresponding refcount block has not yet been allocated. All refcounts managed by this refcount block are 0.
    instances:
      is_allocated:
        value: offset_7_bytes != 0
      block_entry:
        type: refcount_block_entry
        pos: offset_7_bytes
        if: is_allocated
    types:
      refcount_block_entry:
        seq:
          - id: entries
            size: bits(_root.header.refcount_bit_size_bits.value - 1)
            doc: Reference count of the cluster. If _root.header.refcount_bit_size_bits.value implies a sub-byte width, note that bit 0 means the least significant bit in this context.
            repeat: expr
            repeat-expr: _root.header.refcount_block_entries_count

  l1_table_entry:
    seq:
      - id: reserved0 #0
        type: b9
      - id: l2_offset #9
        type: b47
        doc: Must be aligned to a cluster boundary. If the offset is 0, the L2 table and all clusters described by this L2 table are unallocated.
      - id: reserved1 #56
        type: b7
      - id: flag #63
        type: b1
        doc: 0 for an L2 table that is unused or requires COW, 1 if its refcount is exactly one. This information is only accurate in the active L1 table.
    instances:
      is_allocated:
        value: l2_offset != 0
      l2_table:
        doc: |
          Just as for refcounts, qcow2 uses a two-level structure for the mapping of guest clusters to host clusters. They are called L1 and L2 table.
          L2 tables are exactly one cluster in size.
        pos: l2_offset
        #pos: 0
        #io: _root.clusters[]
        type: l2_table_entry
        repeat: expr
        repeat-expr: _root.header.cluster_size_bytes/8
        if: is_allocated
  l2_table_entry:
    seq:
      - id: descriptor_spacer
        -orig-id: cluster_descriptor
        type: b62
        doc: If a cluster is unallocated, read requests shall read the data from the backing file (except if bit 0 in the Standard Cluster Descriptor is set). If there is no backing file or the backing file is smaller than the image, they shall read zeros for all parts that are not covered by the backing file.
      - id: is_compressed
        type: b1
      - id: flag
        type: b1
        doc: 0 for a cluster that is unused or requires COW, 1 if its refcount is exactly one. This information is only accurate in L2 tables that are reachable from the active L1 table.
    instances:
      descriptor:
        -orig-id: cluster_descriptor
        type:
          switch-on: is_compressed
          cases:
            true: compressed
            false: standard
        io: descriptor_spacer._io
        pos: 0
    types:
      standard:
        seq:
          - id: all_zeros
            type: b1
            doc: |
              If set to 1, the cluster reads as all zeros. The host cluster offset can be used to describe a preallocation, but it won't be used for reading data from this cluster, nor is data read from the backing file if the cluster is unallocated.
              With version 2, this is always 0.
          - id: reserved0
            type: u1
          - id: host_cluster_offset
            type: b47
            doc: Bits 9-55 of host cluster offset. Must be aligned to a cluster boundary. If the offset is 0, the cluster is unallocated.
          - id: reserved1
            type: b6
      compressed:
        seq:
          - id: host_cluster_offset
            type: b(63 - (cluster_size_bits - 8))
            doc: Bits 9-55 of host cluster offset. Must be aligned to a cluster boundary. If the offset is 0, the cluster is unallocated.
          - id: compressed_size
            type: b(cluster_size_bits - 8)
            doc: Compressed size of the images in sectors of 512 bytes
  virtual_cluster:
    doc: If a cluster is unallocated, read requests shall read the data from the backing file (except if bit 0 in the Standard Cluster Descriptor is set). If there is no backing file or the backing file is smaller than the image, they shall read zeros for all parts that are not covered by the backing file.
    params:
      - id: index
        type: u4
    instances:
      l1_index:
        value: index / _root.header.l2_entries_count
      l2_index:
        value: index % _root.header.l2_entries_count
      l1_entry:
        value: _root.l1_table[l1_index]
      l2_entry:
        value: l1_entry.l2_table[l2_index]
      host_cluster_index_offset:
        -orig-id: cluster_offset
        value: l2_entry.descriptor.host_cluster_offset
      host_cluster_index:
        value: host_cluster_index_offset + index
      cluster:
        value: _root.clusters[host_cluster_index]


      refcount_table_index:
        value: index / _root.header.refcount_block_entries_count
      refcount_block_index:
        value: index % _root.header.refcount_block_entries_count
      refcount_block:
        value: refcount_table[refcount_table_index].block_entry
      refcount:
        value: refcount_block.entries[refcount_block_index];
enums:
  header_extension_type:
    0x00000000: end
    0xe2792aca: backing_file_format_name
    0x6803f857: feature_name_table
    0x23852875: bitmaps
    0x0537be77: full_disk_encryption_header
