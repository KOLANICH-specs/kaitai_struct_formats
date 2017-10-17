meta:
  id: parchive_v1
  title: Parity Volume Set v1
  application:
    - par2cmdline
    - LibPar2
    - MultiPar
    - Par-N-Rar
    - PAR Buddy
  file-extension:
    - PXX
    - (P-Z)(00-99)
  license: Unlicense
  endian: le
  encoding: utf-8
  xref:
    justsolve: Parity Volume Set
    wikidata: Q497118
doc-ref: http://parchive.sourceforge.net/docs/specifications/parity-volume-spec-1.0/article-spec.html
doc: |
  The parity volumes contain a reed solomon checksum of the data of the data files. So if a file is missing or corrupt, it can be reconstructed out of the remaining data files and the parity volumes. Any file of this set can be reconstructed with any parity volume. You just need as much parity volumes, as files you are missing.
  For instance, in the example above, Foobar.d03 is lost. So it is possible to restore Foobar.d03 using the remaining data files and one parity volume. It doesn't matter, which parity volume (p01/p02/p03) - everyone will do...
  In case you miss 2 files, you need 2 parity volumes. What parity volumes and their combination (p01+p02/p01+p03/p02+p03) doesn't matter too - you just need two of them. (They have to be different: renaming a copy of foobar.p01 to foobar.p02 and using it with foobar.p01 to restore will not work...)
seq:
  - id: preheader
    type: preheader
  - id: rest_of_file
    type: rest_of_file
types:
  md5:
    seq:
      - id: hash
        size: 16
  preheader:
    seq:
      - id: signature
        -orig-id: Identification String
        contents: [PAR, 0, 0, 0, 0, 0]
      - id: program_version
        -orig-id: Version Number
        type: program_version
      - id: checksum
        -orig-id: Control Hash
        type: md5
        doc: a MD5 hash of the rest of the file starting from 0x0020 to the end
    types:
      program_version:
        seq:
          - id: version
            type: u4
          - id: program_id
            type: u4
            doc: The client can use it to see, which program generated the parity volume set. This may come in handy, if your program needs to know, if it was the generator itself. (Maybe to see, if it can use some proprietary bits in the status register or to notify, if new versions are out...)
        enums:
          program-id:
            00: undefined
            01: mirror
            02: par
        types:
          version:
            seq:
              - id: ‘subsubsubversion’
                type: u1
              - id: ‘subsubversion’
                type: u1
              - id: ‘subversion’
                type: u1
              - id: ‘version’
                type: u1
  rest_of_file:
    seq:
      - id: set_hash
        type: md5
        doc: |
          used as an identifier for the parity volume set
          Creation:
          Make a array of bytes (one dimendion, size=used files*16). Then put the MD5 hashes (not the MD516k hashes) there, starting with the first file. Use only the files, which are included in the parity data (status bit 0 = 1). Then calculate the MD5 hash of this array.
      - id: number_of_files
        type: u8
        doc: |
          the number of files stored in the parity volume set (only the input data files - the parity volumes are not counted)
          The files, which are not stored in the parity data, but in the file list for CRC checking, are counted too. So this is the number of files in the file list.
      - id: file_list_offset
        -orig-id: start offset of the file list
        type: u8
        doc: the start offset of the list of stored files
      - id: file_list_size
        type: u8
      - id: data_offset
        -orig-id: start offset of the data
        type: u8
      - id: data_size
        type: u8
    instances:
      files:
        pos: file_list_offset
        size: file_list_size
        type: files_list
      data:
        pos: data_offset
        size: data_size
    types:
      files_list:
        seq:
          - id: files
            type: file_entry
            repeat: eos
        types:
          file_entry:
            seq:
              - id: size
                type: u8
                doc: The size of the file list entry in bytes. Counting starts at 1, this record is counted too.
              - id: file
                type: file
            types:
              file:
                seq:
                  - id: status_field
                    type: status_field
                  - id: size
                    type: u8
                    doc: the size of the stored file in bytes
                  - id: checksum
                    type: md5
                    doc: |
                      a MD5 hash of the whole file
                      One demanded feature is, that the program will find its files even if the filenames are changed. So maybe, if the program won't find the files due to renaming, you click the "search" button and then it checks the MD5 hashes of all files in the directory to find his files. But with large numbers of large files this will take a long time. With the 16k hashes, the program only needs to check the first 16k of each file. This will be much faster. If it finds a file, it can make a full hash too, just to be sure...
                  - id: checksum_16k
                    type: md5
                    doc: if the file is smaller than 16k, only the exisdting bytes are used
                  - id: name
                    type: str
                    size-eos: true
                    doc: the full filename with extension in Unicode
                types:
                  status_field:
                    seq:
                      - id: is_file_saved
                        type: b1
                        doc: |
                          file is (not) saved in the parity volume set
                          Maybe the PAR file is only used to provide file comments and checksums. The files are not saved in a PXX volume then.
                      - id: is_checked_succesfully
                        type: b1
                        doc: |
                          file is not checked successfully yet
                          So you can build in a function, that your program skips already successfully checked files. Repeated checking of the same set will be faster this way. (Like with QuickSFV)
                      - id: reserved0
                        type: b6
                      - id: reserved1
                        type: u1
                      - id: reserved2
                        type: u2
                      - id: reserved3
                        type: u4
