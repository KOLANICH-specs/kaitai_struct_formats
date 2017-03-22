meta:
  id: smile
  title: Smile
  file-extension: sml
  xref:
    mime: application/x-jackson-smile
    wikidata: Q17081599
  endian: le
  encoding: UTF-8
  -version: "1.0.4 (12-May-2013)"
  license: BSD-2-Clause

doc: |
  Efficient JSON-compatible binary format: "Smile"
  "Smile" is codename for an efficient JSON-compatible binary data format, initially developed by Jackson JSON processor project team.
  Its logical data model is same as that of JSON, so it can be considered a "Binary JSON" format.
doc-ref: https://github.com/FasterXML/smile-format-specification
seq:
  - id: f_version
    type: u4
  - id: my_offset
    type: offset_obj
types:
  header:
    doc: "A 4-byte header (described below) that can be used to identify content that uses the format, as well as its version and any per-section configuration settings there may be."
    seq:
      - id: signature
        content: [":)", 0x0a]
      - id: version
        type: 4b
        doc: 0x00 for current version (note: it is possible that some bits may be reused if necessary)
      - id: reserved
        type: 1b
      - id: raw_binary_allowed
        type: 4b
        doc: Whether "raw binary" (unescaped 8-bit) values may be present in content
      - id: string_sharing_required
        type: 1b
        doc: Whether "shared String value" checking was enabled during encoding -- if header missing, default value of "false" must be assumed for decoding (meaning parser need not store decoded String values for back referencing)
      - id: property_name_sharing_required
        type: 1b
        doc: Whether '''shared property name''' checking was enabled during encoding -- if header missing, default value of "true" must be assumed for decoding (meaning parser MUST store seen property names for possible back references)
  section:
    seq:
      - id: header
        type: header
      - id: tokens
        type: header
      - id: terminator
        content: 0xFF
  token:
    seq:
      - id: class
        type: b3
        enum: class
      - id: content
        type: ???
    enum:
      class:
        0: ref # 0x00 - 0x1F: Short Shared Value String reference (single byte)
        1: literal # Simple literals, numbers
        2: Tiny ASCII # (1 - 32 bytes == chars)
        3: Short ASCII # (33 - 64 bytes == chars)
        4: Tiny Unicode # (2 - 33 bytes; <= 33 characters)
        5: Short Unicode #(34 - 64 bytes; <= 64 characters)
        6: Small integers #(single byte)
        7: misc #Binary / Long text / structure markers (0xF0 - 0xF7 is unused, reserved for future use -- but note, used in key mode)
  
  ref:
    seq:
      - id: ref_value
        type: b5
  literal:
    seq:
      - id: is_key
        type: b1
      - id: subtype
        type: b4
      - id: content
        type: ???
    enums:
      subtype:
        # Prefix: 0x20; covers byte values 0x20 - 0x3F, although not all values are used
        #Literals (simple, non-structured)
        0x0: "" (empty String)
        0x1: null
        0x2: false
        0x3: true
        #Numbers:
        #0x24 - 0x27 Integral numbers; 2 {{{LSB}}} (0x03) contain subtype
        0x4: 32-bit integer; zigzag encoded, 1 - 5 data bytes
        0x5: 64-bit integer; zigzag encoded, 5 - 10 data bytes
        0x6: BigInteger # Encoded as token indicator followed by 7-bit escaped binary (with Unsigned VInt (no-zigzag encoding) as length indicator) that represent magnitude value (byte array)
        0x7: reserved for future use
        #0x28 - 0x2B floating point numbers
        0x8: 32-bit float
        0x9: 64-bit double
        0xA: BigDecimal #Encoded as token indicator followed by zigzag encoded scale (32-bit), followed by 7-bit escaped binary (with Unsigned VInt (no-zigzag encoding) as length indicator) that represent magnitude value (byte array) of integral part.
        0xB: reserved for future use
        #0xC - 0x2F reserved for future use (non-overlapping with keys)

    #Prefixes: 0x40  / 0x60; covers all byte values between 0x40 and 0x7F.
    #0x40 - 0x5F: Tiny ASCII
    #String with specified length; all bytes in ASCII range.
    #5 LSB used to indicate lengths from 1 to 32 (bytes == chars)

    #0x60 - 0x7F: Small ASCII
    #String with specified length; all bytes in ASCII range
    #5 LSB used to indicate lengths from 33 to 64 (bytes == chars)
  tiny_ascii:
    seq:
      - id: length
        type: b5
      - id: content
        type: str
        size: length

  small_ascii:
    seq:
      - id: length
        type: b5
      - id: content
        type: str
        size: 33+length
  tiny_unicode:
    seq:
      - id: length
        type: 2+b5
      - id: content
        type: str
        size: length
        encoding: unicode
  small_unicode:
    seq:
      - id: length
        type: b5
      - id: content
        type: str
        size: 34+length
        encoding: unicode
  small_integers:
    seq:
      - id: value
        type: b5 # signed
  misc:
    seq:
      - id: section
        type: b3
      - id: content
        type: ???
    enums:
       sections:
         0b000: Long (variable length) ASCII text
         0b001: Long (variable length) Unicode text
         0b010: Binary, 7-bit encoded
         0b011: Shared String reference, long
         0b100: not used, reserved for future use (NOTE: used in key mode)
         0b101: not used, reserved for future use (NOTE: used in key mode)
         0b110: Structural markers
         0b111: other
    types:
      structural_markers:
        seq:
          - id: type:
            type: b2
            enum: markers_types
        enums:
          markers_types:
            0b00: start_array
            0b01: end_array
            0b10: start_object
            0b11: reserved in token mode (but is END_OBJECT in key mode) -- this just because object end marker comes as alternative to property name.
      other:
        seq:
          - id: type:
            type: b2
            enum: markers_types
        enums:
          markers_types:
            0b00: Used as end-of-String marker
            0b01: Binary (raw)
            0b10: reserved for future use followed by VInt length indicator, then raw data
            0b11: end-of-content marker (not used in content itself)

==== Tokens: key mode ====

Key mode tokens are only used within JSON Object values; if so, they alternate between value tokens (first a key token; followed by either single-value value token or multi-token JSON Object/Array value). A single token denotes end of JSON Object value; all the other tokens are used for expressing JSON Object property name.

Most tokens are single byte: exceptions are 2-byte "long shared String" token, and variable-length "long Unicode String" tokens.

Byte ranges are divides in 4 main sections (64 byte values each):

 * 0x00 - 0x3F: miscellaneous
  * 0x00 - 0x1F: not used, reserved for future versions
  * 0x20: Special constant name "" (empty String)
  * 0x21 - 0x2F: reserved for future use (unused for now to reduce overlap between values)
  * 0x30 - 0x33: "Long" shared key name reference (2 byte token); 2 LSBs of the first byte are used as 2 MSB of 10-bit reference (up to 1024) values to a shared name: second byte used for 8 LSB.
   * Note: combined values of 0 through 64 are reserved, since there is more optimal representation -- encoder is not to produce such "short long" values; decoder should check that these are not encountered. Future format versions may choose to use these for specific use.
  * 0x34: Long (not-yet-shared) Unicode name. Variable-length String; token byte is followed by 64 or more bytes, followed by end-of-String marker byte.
   * Note: encoding of Strings shorter than 56 bytes should NOT be done using this type: if such sequence is detected it MAY be considered an error. Further, for ASCII names, Strings with length of 56-64 should also use short String notation
  * 0x35 - 0x39: not used, reserved for future versions
  * 0x3A: Not used; would be part of header sequence (which is NOT allowed in key mode!)
  * 0x3B - 0x3F: not used, reserved for future versions
 * 0x40 - 0x7F: "Short" shared key name reference; names 0 through 63.
 * 0x80 - 0xBF: Short ASCII names
  * 0x80 - 0xBF: names consisting of 1 - 64 bytes, all of which represent UTF-8 Ascii characters (MSB not set) -- special case to potentially allow faster decoding
 * 0xC0 - 0xF7: Short Unicode names
  * 0xC0 - 0xF7: names consisting of 2 - 57 bytes that can potentially contain UTF-8 multi-byte sequences: encoders are NOT required to guarantee there is one, but for decoding efficiency reasons are recommended to check (that is: decoders on many platforms will be able to handle ASCII-sequences more efficiently than general UTF-8 names)
 * 0xF8 - 0xFA: reserved (avoid overlap with START/END_ARRAY, START_OBJECT)
 * 0xFB: END_OBJECT marker
 * 0xFC - 0xFF: reserved for framing, not used in key mode (used in value mode)

=== Resolved Shared String references ===

Shared Strings refer to already encoded/decoded key names or value strings. The method used for indicating which of "already seen" String values to use is designed to allow for:

 * Efficient encoding AND decoding (without necessarily favoring either)
 * To allow keeping only limited amount of buffering (of already handled names) by both encoder and decoder; this is especially beneficial to avoid unnecessary overhead for cases where there are few back references (mostly or completely unique values)

Mechanism for resolving value string references differs from that used for key name references, so two are explained separately below.

==== Shared value Strings ====

Support for shared value Strings is optional, in that generator can choose to either check for shareable value Strings or omit the checks.
Format header will indicate which option generator chose: if header is missing, default value of "false" (no checks done for shared value Strings; no back-references exist in encoded content) must be assumed.

One basic limitation is the encoded byte length of a String value that can be referenced is 64 bytes or less. Longer Strings can not be referenced. This is done as a performance optimization, as longer Strings are less likely to be shareable; and also because equality checks for longer Strings are most costly.
As a result, parser only should keep references for eligible Strings during parsing.

Reference length allowed by format is 10 bits, which means that encoder can replace references to most recent 1024 potentially shareable (referenceable) value Strings.

For both encoding (writing) and decoding (parsing), same basic sliding-window algorithm is used: when a potentially eligible String value is to be written, generator can check whether it has already written such a String, and has retained reference. If so, reference value (between 0 and 1023) can be written instead of String value.
If no such String has been written (as per generator's knowledge -- it is not required to even check this), value is to be written. If its encoded length indicates that it is indeeed shareable (which can not be known before writing, as check is based on byte length, not character length!), decoder is to add value into its shareable String buffer -- as long as buffer size does not exceed that of 1024 values. If it already has 1024 values, it MUST clear out buffer and start from first entry. This means that reference values are NOT relative back references, but rather offsets from beginning of reference buffer.

Similarly, parser has to keep track of decoded short (byte length <= 64 bytes) Strings seen so far, and have buffer of up to 1024 such values; clearing out buffer when it fills is done same way as during content generation.
Any shared string value references are resolved against this buffer.

Note: when a shared String is written or parsed, no entry is added to the shared value buffer (since one must already be in it)

==== Shared key name Strings ====

Support for shared property names is optional, in that generator can choose to either check for shareable property names or omit the checks.
Format header will indicate which option generator chose: if header is missing, default value of "trues" (checking done for shared property names is made, and encoded content MAY contain back-references to share names) must be assumed.

Shared key resolution is done same way as shared String value resolution, but buffers used are separate. Buffer sizes are same, 1024.

-----

=== Future improvement ideas ===

'''NOTE''': version 1.0 will '''NOT''' support any of features presented in this section; they are documented as ideas for future work.

==== In-frame compression? ====

Although there were initial plans to allow in-frame (in-content) compression for individual values, it was decided that support would not be added for initial version, mostly since it was felt that compression of the whole document typically yields better results. For some use cases this may not be true, however; especially when semi-random access is desired.

Since enough type bits were left reserved for binary and long-text types, support may be added for future versions.

==== Longer length-prefixed data? ====

Given that encoders may be able to determine byte-length for value strings longer than 64 bytes (current limit for "short" strings), it might make sense to add value types with 2-byte prefix (or maybe just 1-byte prefix and additional length information after first fixed 64 bytes, since that allows output at constant location. Performance measurements should be made to ensure that such an option would improve performance as that would be main expected benefit.

==== Pre-defined shared values (back-refs) ====

For messages with little redundancy, but small set of always used names (from schema), it would be possible to do something similar to what deflate/gzip allows: defining "pre-amble", to allow back-references to pre-defined set of names and text values.
For example, it would be possible to specify 64 names and/or shared string values for both serializer and deserializer to allow back-references to this pre-defined set of names and/or string values. This would both improve performance and reduce size of content.

==== Filler value(s) ====

It might make sense to allocate a "no-op" value or values to allow for padding of messages.
This would be useful for things like:

 * Allow rounding up message size, for example to align entries in memory
 * Leave slack for possible in-place additions or modifications (like always allocating fixed space for String values)

This would be a simple addition.

==== Chunked values ====

(note: inspiration for this came from [[https://tools.ietf.org/html/rfc7049 | CBOR]] format)

As an alternative for either requiring full content length (binary data), or end marker (long Strings, Objects, arrays),
and to specifically allow better buffering during encoding, it might make sense to allow "chunked" variants wherein
long content is encoded in chunks, size of which is individual indicated with length prefix, but whose total size
need not be calculated. This would work well for including large data incrementally, and it could also allow for
more efficient and flexible decoding.

-----

=== Appendix A: External definitions ===

==== ZigZag encoding for VInts ====

Smile uses {{{ZigZag}}} encoding (defined for [[http://code.google.com/apis/protocolbuffers/docs/encoding.html | protobuf format]], see [[http://stackoverflow.com/questions/2210923/zig-zag-decoding | this example]]),
which is a variant of generic [[http://en.wikipedia.org/wiki/Variable-length_quantity | VInts]] (Variable-length INTegers).

Encoding is done logically as a two-step process:

 1. Use {{{ZigZag}}} encoding to convert signed values to unsigned values: essentially this will "move the sign bit" as the LSB.
 2. Encode remaining bits of unsigned integral number, starting with the most significant bits: the last byte is indicated by setting the sign bit; all the other bytes have sign bit clear.
   * Last byte has only 6 data bits; second-highest bit MUST be clear (to ensure that value 0xFF is never used for encoding; values 0xC0 - 0xFF are not used for the last byte).
   * Other bytes have 7 data bits.

=== Appendix B: encoder/decoder implementations ===

Following implementations are known for Smile format:

 * [[https://github.com/FasterXML/jackson-dataformat-smile | Jackson]] (JSON)
 * [[https://github.com/dakrone/cheshire | Cheshire]] (Clojure)
 * [[https://github.com/pierre/libsmile | libsmile]] (C, wrappers for Ruby, Perl)
 * [[https://github.com/jhosmer/PySmile | PySmile]] (Python)

----
CategorySmile
