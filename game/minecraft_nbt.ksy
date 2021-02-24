meta:
  id: minecraft_nbt
  title: Minecraft NBT (Named Binary Tag)
  application: Minecraft
  file-extension:
    - nbt
    - dat
    - schematic # https://minecraft.fandom.com/wiki/Schematic_file_format
    - schem
  xref:
    justsolve: Minecraft_NBT_format
  tags:
    - serialization
  license: CC0-1.0
  encoding: utf-8
  endian: be
  ks-version: '0.9'
doc: |
  A structured binary format native to Minecraft for saving game data and transferring
  it over the network (in multiplayer), such as player data
  ([`<player>.dat`](https://minecraft.fandom.com/wiki/Player.dat_format); contains
  e.g. player's inventory and location), saved worlds
  ([`level.dat`](
    https://minecraft.fandom.com/wiki/Java_Edition_level_format#level.dat_format
  ) and [Chunk format](https://minecraft.fandom.com/wiki/Chunk_format#NBT_structure)),
  list of saved multiplayer servers
  ([`servers.dat`](https://minecraft.fandom.com/wiki/Servers.dat_format)) and so on -
  see <https://minecraft.fandom.com/wiki/NBT_format#Uses>.

  The entire file should be _gzip_-compressed (in accordance with the original
  specification [NBT.txt](
    https://web.archive.org/web/20110723210920/https://www.minecraft.net/docs/NBT.txt
  ) by Notch), but can also be compressed with _zlib_ or uncompressed.

  This spec can only handle uncompressed NBT data, so be sure to first detect
  what type of data you are dealing with. You can use the Unix `file` command
  to do this (`file-5.20` or later is required; older versions do not recognize
  _zlib_-compressed data and return `application/octet-stream` instead):

  ```shell
  file --brief --mime-type input-unknown.nbt
  ```

  If it says:

    * `application/x-gzip` or `application/gzip` (since `file-5.37`), you can decompress it by
      * `gunzip -c input-gzip.nbt > output.nbt` or
      * `python3 -c "import sys, gzip; sys.stdout.buffer.write(
        gzip.decompress(sys.stdin.buffer.read()) )" < input-gzip.nbt > output.nbt`
    * `application/zlib`, you can use
      * `openssl zlib -d -in input-zlib.nbt -out output.nbt` (does not work on most systems)
      * `python3 -c "import sys, zlib; sys.stdout.buffer.write(
        zlib.decompress(sys.stdin.buffer.read()) )" < input-zlib.nbt > output.nbt`
    * something else (especially `image/x-pcx` and `application/octet-stream`),
      it is most likely already uncompressed.

  The file `output.nbt` generated by one of the above commands can already be
  processed with this Kaitai Struct specification.

  This spec **only** implements the Java edition format. There is also
  a [Bedrock edition](https://wiki.vg/NBT#Bedrock_edition) NBT format,
  which uses little-endian encoding and has a few other differences, but it isn't
  as popular as the Java edition format.

  **Implementation note:** strings in `TAG_String` are incorrectly decoded with
  standard UTF-8, while they are encoded in [**Modified UTF-8**](
    https://docs.oracle.com/javase/8/docs/api/java/io/DataInput.html#modified-utf-8
  ) (MUTF-8). That's because MUTF-8 is not supported natively by most target
  languages, and thus one must use external libraries to achieve a fully-compliant
  decoder. But decoding in standard UTF-8 is still better than nothing, and
  it usually works fine.

  All Unicode code points with incompatible representations in MUTF-8 and UTF-8 are
  U+0000 (_NUL_), U+D800-U+DFFF (_High_ and _Low Surrogates_) and U+10000-U+10FFFF
  (all _Supplementary_ Planes; includes e.g. emoticons, pictograms).
  A _MUTF-8_-encoded string containing these code points cannot be successfully
  decoded as UTF-8. The behavior in this case depends on the target language -
  usually an exception is thrown, or the bytes that are not valid UTF-8
  are replaced or ignored.

  **Sample files:**

    * <https://wiki.vg/NBT#Download>
    * <https://github.com/twoolie/NBT/blob/f9e892e/tests/world_test/data/scoreboard.dat>
    * <https://github.com/chmod222/cNBT/tree/3f74b69/testdata>
    * <https://github.com/PistonDevelopers/hematite_nbt/tree/0b85f89/tests>
doc-ref:
  - https://wiki.vg/NBT
  - https://web.archive.org/web/20110723210920/https://www.minecraft.net/docs/NBT.txt
  - https://minecraft.fandom.com/wiki/NBT_format
seq:
  - id: root_check
    size: 0
    if: root_type == tag::end and false # force evaluation of root_type's `valid` check
    # valid:
    #   expr: root_type == tag::compound # as of KS 0.9 does not compile for Go and Lua
  - id: root
    type: named_tag
instances:
  root_type:
    pos: 0
    type: u1
    enum: tag
    valid: tag::compound
types:
  named_tag:
    -webide-representation: 'TAG_{type}("{name.data}"): {payload:dec}'
    seq:
      - id: type
        type: u1
        enum: tag
      - id: name
        type: tag_string
        if: not is_tag_end
      - id: payload
        type:
          switch-on: type
          cases:
            tag::byte: s1
            tag::short: s2
            tag::int: s4
            tag::long: s8
            tag::float: f4
            tag::double: f8
            tag::byte_array: tag_byte_array
            tag::string: tag_string
            tag::list: tag_list
            tag::compound: tag_compound
            tag::int_array: tag_int_array
            tag::long_array: tag_long_array
        if: not is_tag_end
    instances:
      is_tag_end:
        value: type == tag::end
  tag_byte_array:
    -webide-representation: '{len_data:dec} bytes'
    seq:
      - id: len_data
        type: s4
      - id: data
        size: len_data
  tag_string:
    -webide-representation: '{data}'
    seq:
      - id: len_data
        type: u2
        doc: unsigned according to <https://wiki.vg/NBT#Specification>
      - id: data
        size: len_data
        type: str
  tag_list:
    -webide-representation: '{num_tags:dec} entries of type TAG_{tags_type}'
    seq:
      - id: tags_type
        type: u1
        enum: tag
      - id: num_tags
        type: s4
      - id: tags
        type:
          switch-on: tags_type
          cases:
            tag::byte: s1
            tag::short: s2
            tag::int: s4
            tag::long: s8
            tag::float: f4
            tag::double: f8
            tag::byte_array: tag_byte_array
            tag::string: tag_string
            tag::list: tag_list
            tag::compound: tag_compound
            tag::int_array: tag_int_array
            tag::long_array: tag_long_array
        repeat:
          expr: num_tags
  tag_compound:
    -webide-representation: '{dump_num_tags:dec} entries'
    seq:
      - id: tags
        type: named_tag
        repeat:
          until: _.is_tag_end
    instances:
      dump_num_tags:
        value: 'tags.size - ((tags.size >= 1 and tags.last.is_tag_end) ? 1 : 0)'
  tag_int_array:
    -webide-representation: '{num_tags:dec} entries of type TAG_{tags_type}'
    seq:
      - id: num_tags
        type: s4
      - id: tags
        type: s4
        repeat:
          expr: num_tags
    instances:
      tags_type:
        value: tag::int
  tag_long_array:
    -webide-representation: '{num_tags:dec} entries of type TAG_{tags_type}'
    seq:
      - id: num_tags
        type: s4
      - id: tags
        type: s8
        repeat:
          expr: num_tags
    instances:
      tags_type:
        value: tag::long
enums:
  tag:
    0:
      id: end
      -affected-by: 90
      doc: |
        As of KSC 0.9, this enum key causes a syntax error in Lua. See
        <https://github.com/kaitai-io/kaitai_struct/issues/90#issuecomment-766440975>
        for more info.
    1: byte
    2: short
    3: int
    4: long
    5: float
    6: double
    7: byte_array
    8: string
    9: list
    10: compound
    11: int_array
    12: long_array
