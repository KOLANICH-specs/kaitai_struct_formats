meta:
  id: widows_briefcase
  encoding: ascii
  title: Windows briefcase database
  application:
    - MS Windows XP
  license: Unlicense
  endian: le

doc: |
  Windows briefcase.
seq:
  - id: signature
    contents: DDSH
  - id: unkn0
    type: u1
  - id: unkn1
    type: u1

  - id: unkn2
    type: u1
  - id: unkn3
    type: u1

  - id: unkn4
    type: u4
    repeat: expr
    repeat-expr: unkn1 # ?

  - id: root_record
    type: root_record
  - id: dir_name
    type: dir_name(root_record.dir_name_with_stuff_size)
  - id: yet_another_dir_name
    type: yet_another_dir_name
    repeat: expr
    repeat-expr: root_record.count_of_dirs - 1 # ?
  - id: sync_mappings
    type: sync_mappings
  - id: some_sync_entry_id
    type: id_header
  - id: unkn5
    type: u4
    doc: 0A 00 00 00
  - id: files_names
    type: files_names
  - id: files_syncs
    type: files_syncs(root_record.count_of_dirs) #?

types:
  id_header:
    seq:
      - id: id
        type: u2
      - id: sig
        contents: [0x7B, 0x05]

  root_record:
    seq:
      - id: id
        type: id_header
      - id: unkn
        type: u4
        repeat: expr
        repeat-expr: 11
      - id: unkn1
        type: u1
      - id: disk_letter
        type: str
        size: 3
      - id: unkn2
        type: u2
        doc: 00 00
      - id: dir_name_with_stuff_size
        type: u4
        doc: dir name length with the stuff after it?
      - id: count_of_dirs
        type: u4
        doc: count of dirs?

  dir_name:
    params:
      - id: length_with_stuff
        type: u4
    seq:
      - id: id
        type: id_header
      - id: name
        size: name_size
      - id: stuff
        size: stuff_size
    instances:
      stuff_size:
        value: 9
      name_size:
        value: length_with_stuff - stuff_size

  yet_another_dir_name:
    seq:
      - id: id
        type: id_header
      - id: name
        type: strz

  sync_mappings:
    seq:
      - id: count
        type: u4
        doc: count_of_synced files?
      - id: mappings
        type: sync_mapping
        repeat: expr
        repeat-expr: count
    types:
      sync_mapping:
        seq:
          - id: entry_id
            type: id_header
          - id: root_id
            type: id_header
          - id: dir_id
            type: id_header
            doc: either an id of `yet_another_dir_name` or `dir_name`

  files_names:
    seq:
      - id: count
        type: u4
        doc: count_of_synced files?
      - id: names
        type: file_name
        repeat: expr
        repeat-expr: count
    types:
      file_name:
        seq:
          - id: file_id
            type: id_header
          - id: name
            type: strz
  files_syncs:
    params:
      - id: count_of_sync_info_entries_for_a_sync_entry
        type: u4
    seq:
      - id: count
        type: u4
      - id: unkn
        type: u4
      - id: syncs
        type: file_syncs(count_of_sync_info_entries_for_a_sync_entry)
        repeat: expr
        repeat-expr: count
    types:
      file_syncs:
        params:
          - id: count_of_sync_info_entries_for_a_sync_entry
            type: u4
        seq:
          - id: file_id
            type: id_header
          - id: count
            type: u4
            doc: count_of_synced files?
          - id: unkn
            type: u4
            doc: 00 00 00 00
          - id: entries
            type: sync_entry(count_of_sync_info_entries_for_a_sync_entry)
            repeat: expr
            repeat-expr: count
        types:
          sync_entry:
            params:
              - id: count_of_sync_info_entries_for_a_sync_entry
                type: u4
            seq:
              - id: entry_id
                type: id_header
              - id: syncs
                type: sync_info(_index)
                repeat: expr
                repeat-expr: count_of_sync_info_entries_for_a_sync_entry
            types:
              sync_info:
                params:
                  - id: idx
                    type: u4
                seq:
                  - id: unkn0
                    type: u4
                    doc: correlated to `idx` (not linear dependence, just co-occurence)
                  - id: xx
                    type: u1
                    doc: correlated to `file_id`
                  - id: yyyyyy
                    size: 3
                    doc: correlated to (`idx`, `file_id`)
                  - id: zz
                    type: u1
                    doc: correlated to `idx` (not linear dependence, just co-occurence)
                  - id: afd301
                    contents: [0xaf, 0xd3, 0x01]
                  - id: unkn1
                    type: u4
                    doc: WTF, on the test file for the first `sync_info` entry ths field is correlated to to (`idx`, `file_id`) and for the second one to just `idx`
