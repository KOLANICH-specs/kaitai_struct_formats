meta:
  id: cbfs
  title: Coreboot File System
  endian: le
  application:
    - Coreboot
    - cbfstool
    - grub2
    - flashrom
  imports:
    - /executable/BIOS/option_rom
  license: Unlicense
doc: |
  Based on CBFS Specification by Jordan Crouse and Coreboot wiki.
  CBFS is a scheme for managing independent chunks of data in a system ROM. Though not a true filesystem, the style and concepts are similar.
  As far as Coreboot is concerned, this is a read-only file system. A special tool (cbfstool) can add extra components to a ROM image file. File deletion is not supported at all. In theory it is possible to write additional files to an actual flash chip, but this is not supported by the flash utility. Instead, the ROM image is composed (as a file on disk) by cbfstool and then the whole image is flashed into the actual flash chip.
  The CBFS architecture consists of a binary associated with a physical ROM disk referred hereafter as the ROM. A number of independent of components, each with a header prepended on to data are located within the ROM.  The components are nominally arranged sequentially, though they are aligned along a pre-defined boundary.
  The bootblock occupies the last 20k of the ROM.  Within the bootblock is a master header containing information about the ROM including the size, alignment of the components, and the offset of the start of the first CBFS component within the ROM.
doc-ref:
  - https://www.coreboot.org/CBFS
  - https://github.com/coreboot/coreboot/blob/master/Documentation/cbfs.txt
  - https://lennartb.home.xs4all.nl/coreboot/col5.html
seq:
  - id: components
    type: component
    repeat: expr
    repeat-expr: "?"
  - id: boot_block
    doc: The ROM contains a boot block with the low level startup code. Everything in the ROM outside the boot block is occupied by CBFS files.  
    type: boot_block
    size: 20*
types:
  component:
    doc: |
      Each CBFS component is to be aligned according to the 'align' value in the header. Thus, if a component of size 1052 is located at offset 0 with an 'align' value of 1024, the next component will be located at offset 2048. Each CBFS component will be indexed with a unique ASCII string name of unlimited size.
      Coreboot can store two sets of stages (plus payload): the normal set and the fallback set. The romstage, coreboot_ram and payload files of the normal set are stored in the "subdirectory" named "normal", the files of the fallback set are stored in the "subdirectory" named "fallback". The startup code contains some logic to execute the "fallback" code instead of the "normal" code when the "normal" code has failed to start properly. This way experimental code can be tried out while we can still get back to the old code. This fallback mechanism is not fool-proof but it will help you out in most cases.
    seq:
      - id: header
        type: header
      - id: name
        type: strz
        doc: null terminated and 16 byte aligned. The file name can contain slashes (giving the illusion of subdirectories) but there is no directory structure. 
    types:
      header:
        orig-id: cbfs_file
        seq:
          - id: signature
            orig-id: magic
            content: 'LARCHIVE'
            doc: "a magic value used to identify the header.  During runtime, coreboot will scan the ROM looking for this value."
          - id: len
            type: u4
            doc: "the length of the data, not including the size of the header and the size of the name."
          - id: type
            type: u4
            enum: type
            doc: "Used to identify the type of content of the component data, and is used by coreboot and other run-time entities to make decisions about how to handle the data."
          - id: checksum
            type: u4
            doc: "a 32bit checksum of the entire component, including the header and name."
          - id: offset
            type: u4
            doc: "the start of the component data, based off the start of the header. The difference between the size of the header and offset is the size of the component name."
        instances:
          data:
            pos: offset
            size: len
            type:
              switch-on: type
              cases:
                "type::stage": stage
                "type::payload": payload
                "type::optionrom": option_rom
        enums:
          type:
            0xffffffff: null #"don't care" component type.  This can be used when the component type is not necessary (such as when the name of the component is unique. i.e. option_table).  It is recommended that all components be assigned a unique type, but NULL can be used when the type does not matter.
            0x10: stage
            0x20: payload
            0x30: optionrom #Option ROMS have no CBFS-specific header, the uncompressed (in the current version of Coreboot) binary data will be located in the data portion of the component.
  boot_block:
    doc: The bootblock is a mandatory component in the ROM. It is located in the last 20k of the ROM space. The bootblock does not have a component header attached to it. 
    seq:
      - id: header
        type: master_header
    types:
      master_header:
        doc: |
          In addition to the coreboot information, the header reports the size of the ROM, the alignment of the blocks, and the offset of the first component in the CBFS.   The master header provides all the information LAR needs plus the magic number information flashrom needs.
        orig-id: cbfs_header
        seq:
          - id: signature
            orig-id: magic
            content: 'ORBC'
          - id: version
            type: u4
            doc: "is a version number for CBFS header. cbfs_header structure may be different if version is not matched."
          - id: rom_size
            orig-id: romsize
            type: u4
            doc: "The total size of the ROM in bytes. Coreboot will subtract 'size' from 0xFFFFFFFF to locate the beginning of the ROM in memory."
          - id: boot_block_size
            orig-id: bootblocksize
            type: u4
            doc: "the size of bootblock reserved in firmware image."
          - id: align
            type: u4
            doc: "is the number of bytes that each component is aligned to within the ROM. This is used to make sure that each component is aligned correctly with regards to the erase block sizes on the ROM - allowing one to replace a component at runtime without disturbing the others. "
          - id: offset
            type: u4
            doc: "the offset of the the first CBFS component (from the start of the ROM).  This is to allow for arbitrary space to be left at the beginning of the ROM for things like embedded controller firmware."
          - id: architecture
            type: u4
            doc: "describes which architecture (x86, arm, ...) this CBFS is created for."
          - id: reserved
            orig-id: pad
            size: 4
  stage:
    doc: |
      Stages are code loaded by coreboot during the boot process.  They are essential to a successful boot.   Stages are comprised of a single blob of binary data that is to be loaded into a particular location in memory and executed.
      When coreboot sees this component type, it knows that it should pass the data to a sub-function that will process the stage.
      When coreboot loads a stage, it will first zero the memory from 'load' to 'memlen'. It will then decompress the component data according to the specified scheme and place it in memory starting at 'load'.  Following that, it will jump execution to the address specified by 'entry'. Some components are designed to execute directly from the ROM - coreboot knows which components must do that and will act accordingly.
    seq:
      - id: header
        type: header
      - id: data
        type: header.len
    types:
      header:
        orig-id: cbfs_stage
        seq:
          - id: compression
            type: u4
            enum: compression
          - id: entry
            type: u8
            doc: "a value indicating the location where  the program counter should jump following the loading of the stage.  This should be an absolute physical memory address."
          - id: load
            type: u8
            doc: "a value indicating where the subsequent data should be loaded.  This should be an absolute physical memory address."
          - id: len
            type: u4
            doc: "the length of the compressed data in the component."
          - id: memlen
            type: u4
            doc: "the amount of memory that will be used by the component when it is loaded."
  payload:
    doc: |
      Payloads are loaded by coreboot following the boot process.
      Stages are assigned a component value of 0x20.  When coreboot sees this component type, it knows that it should pass the data to a sub-function that will process the payload.  Furthermore, other run time applications such as 'bayou' may easily index all available payloads on the system by searching for the payload type.
      This is essentially SELF in different clothing - same idea as SELF, with the sub-header as above.
    seq:
      - id: count
        type: "?"
      - id: segments
        type: segment
        repeat: expr
        repeat-expr: 
      - type: data
        size: eos
    types:
      segment:
        orig-id: cbfs_payload_segment
        seq:
          - id: type
            type: u4
            enum: type
          - id: compression
            type: u4
            enum: compression
          - id: offset
            type: u4
          - id: load_addr
            type: u8
          - id: len
            type: u4
          - id: mem_len
            type: u4
        enums:
          type:
            0x45444f43: code #the segment contains executable code
            0x41544144: data #contains data
            0x20535342: bss #the memory speicfied by the segment should be zeroed
            0x41524150: params #contains information for the payload
            0x52544e45: entry #contains entry point for the payload
enums:
  compression:
    #additional types may be added assuming that coreboot understands how to handle the scheme.
    0: none
    1: lzma
    2: nrv2b #deprecated
