meta:
  id: pcapng
  title: PCAP Next Generation Capture File Format
  license: IETF
  file-extension: pcapng
  application:
    - Wireshark
    - tcpdump
  endian: le
  encoding: utf-8
  xref:
    mime: application/x-pcapng
    # rfc: # TBD
-license-header:|
  IETF Trust hereby grants to each person who wishes to exercise such rights, to the greatest extent that it is permitted to do so, a non-exclusive, royalty-free, worldwide right and license under all copyrights and rights of authors:

    to copy, publish, display and distribute IETF Contributions and IETF Documents in full and without modification,

    to translate IETF Contributions and IETF Documents into languages other than English, and to copy, publish, display and distribute such translated IETF Contributions and IETF Documents in full and without modification,

    to copy, publish, display and distribute unmodified portions of IETF Contributions and IETF Documents and translations thereof, provided that:

        each such portion is clearly attributed to IETF and identifies the RFC or other IETF Document or IETF Contribution from which it is taken, all IETF legends, legal notices and indications of authorship contained in the original IETF RFC must also be included where any substantial portion of the text of an IETF RFC, and in any event where more than one-fifth of such text, is reproduced in a single document or series of related documents.
doc: |
  Copyright Notice
    Copyright (c) 2017 IETF Trust and the persons identified as the document authors.  All rights reserved.
    This document is subject to BCP 78 and the IETF Trust's Legal Provisions Relating to IETF Documents (https://trustee.ietf.org/license-info) in effect on the date of publication of this document.  Please review these documents carefully, as they describe your rights and restrictions with respect to this document.  Code Components extracted from this document must include Simplified BSD License text as described in Section 4.e of the Trust Legal Provisions and are provided without warranty as described in the Simplified BSD License.
  1.  Introduction
    The problem of exchanging packet traces becomes more and more critical every day; unfortunately, no standard solutions exist for this task right now.  One of the most accepted packet interchange formats is the one defined by libpcap, which is rather old and is lacking in functionality for more modern applications particularly from the extensibility point of view.
    This document proposes a new format for recording packet traces.  The
    following goals are being pursued:
    Extensibility:  It should be possible to add new standard capabilities to the file format over time, and third parties should be able to enrich the information embedded in the file with proprietary extensions, with tools unaware of newer extensions being able to ignore them.
    Portability:  A capture trace must contain all the information needed to read data independently from network, hardware and operating system of the machine that made the capture.
    Merge/Append data:  It should be possible to add data at the end of a given file, and the resulting file must still be readable.
  2.  Terminology
    The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC2119].
  2.1.  Acronyms
    SHB:  Section Header Block
    IDB:  Interface Description Block
    ISB:  Interface Statistics Block
    EPB:  Enhanced Packet Block
    SPB:  Simple Packet Block
    NRB:  Name Resolution Block
    CB:  Custom Block
  3.6.1.  Endianness
    Data contained in each section will always be saved according to the characteristics (little endian / big endian) of the capturing machine.  This refers to all the fields that are saved as numbers and that span over two or more octets.
    The approach of having each section saved in the native format of the generating host is more efficient because it avoids translation of data when reading / writing on the host itself, which is the most common case when generating/processing capture captures.
    Please note: The endianness is indicated by the Section Header Block (Section 4.1).  Since this block can appear several times in a pcapng file, a single file can contain both endianness variants.
  3.6.2.  Alignment
    All fields of this specification use proper alignment for 16- and 32-bit values.  This makes it easier and faster to read/write file contents if using techniques like memory mapped files.
    The alignment octets (marked in this document e.g. with "padded to 32 bits") MUST be filled with zeroes.
    Please note: 64-bit values are not aligned to 64-bit boundaries. This is because the file is naturally aligned to 32-bit boundaries only.  Special care MUST be taken when reading and writing such values.  (Note also that some 64-bit values are represented as a 64-bit integer in the endianness of the machine that wrote the file, and others are represented as 2 32-bit values, one containing the upper 32 bits of the value and one containing the lower 32 bits of the value, each written as 32-bit integers in the endianness of the machine that wrote the file.  Neither of these formats guarantee 64-bit alignment.)
  7.  Recommended File Name Extension: .pcapng
    The recommended file name extension for the "PCAP Next Generation Capture File Format" specified in this document is ".pcapng".
    On Windows and OS X, files are distinguished by an extension to their filename.  Such an extension is technically not actually required, as applications should be able to automatically detect the pcapng file format through the "magic bytes" at the beginning of the file, as some other UN*X desktop environments do.  However, using name extensions makes it easier to work with files (e.g. visually distinguish file formats) so it is recommended - though not required - to use .pcapng as the name extension for files following this specification.
   Please note: To avoid confusion (like the current usage of .cap for a plethora of different capture file formats) other file name extensions than .pcapng should be avoided.
  6.  Vendor-Specific Custom Extensions
    This section uses the term "vendor" to describe an organization which extends the pcapng file with custom, proprietary blocks or options. It should be noted, however, that the "vendor" is just an abstract entity that agrees on a custom extension format: for example it may be a manufacturer, industry association, an individual user, or collective group of users.
  6.1.  Supported Use-Cases
    There are two different supported use-cases for vendor-specific custom extensions: local and portable.  Local use means the custom data is only expected to be usable on the same machine, and the same application, which encoded it into the file.  This limitation is due to the lack of a common registry for the local use number codes (the block or option type code numbers with the Most Significant Bit set). Since two different vendors may choose the same number, one vendor's application reading the other vendor's file would result in decoding failure.  Therefore, vendors SHOULD instead use the portable method, as described next.
    The portable use-case supports vendor-specific custom extensions in pcapng files which can be shared across systems, organizations, etc. To avoid number space collisions, an IANA-registered Private Enterprise Number (PEN) is encoded into the Custom Block or Custom Option, using the PEN number that belongs to the vendor defining the extension.  Anyone can register a new PEN with IANA, for free, by filling out the online request form at http://pen.iana.org/pen/ PenApplication.page [4].
  6.2.  Controlling Copy Behavior
    Both Custom Blocks and Custom Options support two different codes to distinguish their "copy" behavior: a code for when the block or option can be safely copied into a new pcapng file by a pcapng manipulating application, and a code for when it should not be copied.  A common reason for not copying a Custom Block or Custom Option is because it depends on other blocks or options in some way that would invalidate the custom data if the other blocks/options were removed or re-ordered.  For example, if a Custom Block's data includes an Interface ID number in its Custom Data portion, then it cannot be safely copied by a pcapng application that merges pcapng files, because the merging application might re-order or remove one or more of the Interface Description Blocks, and thereby change the Interface IDs that the Custom Block depends upon.  The same issue arises if a Custom Block or Custom Option depends on the presence of, or specific ordering of, other standard-based or custom-defined blocks or options.
    Note that the copy semantics is not related to privacy - there is no guarantee that a pcapng anonymizer will remove a Custom Block or Custom Option, even if the appropriate code is used requesting it not be copied; and the original pcapng file can be shared anyway.  If the Custom Data portion of the Custom Block or Custom Option contains sensitive information, then it should be encrypted in some fashion.
  6.3.  Strings vs. Bytes
    For the Custom Options, there are two Custom Data formats supported: a UTF-8 string and a binary data payload.  The rationale for this separation is that a pcapng display application which does not understand the specific PEN's Custom Option can still display the data as a string if it's a string type code, rather than as hex-ascii of the octets.
  6.4.  Endianness Issues
    Implementers writing Custom Blocks or Custom Options should be aware that a pcapng file can be re-written by machines using a different endianness than the original file, which means all known fields of the pcapng file will change endianness in the new file.  Since the Custom Data payload of the Custom Block or Custom Option might be an arbitrary sequence of unknown octets to such machines, they cannot convert multi-byte values inside the Custom Data into the appropriate endianness.
    For example, a little-endian machine can create a new pcapng file and add some binary data Custom Options to some Block(s) in the file. This file can then be sent to a big-endian host, which will convert it to big-endian format if it re-writes the file.  It will, however, leave the Custom Data payload alone (as little-endian format).  If this file then gets sent back to the little-endian machine, then when that little-endian machine reads the file it will detect the format is big- endian, and swap the endianness while it parses the file - but that will cause the Custom Data payload to be incorrect since it was already in little-endian format.
    Therefore, the vendor should either encode all of their fields in a consistent manner, such as always in big-endian or always little-endian format, regardless of the host platform's endianness; or they should encode some flag in the Custom Data payload to indicate which endianness the rest of the payload is written in.
  8.  Conclusions
    The file format proposed in this document should be very versatile and satisfy a wide range of applications.  In the simplest case, it can contain a raw capture of the network data, made of a series of Simple Packet Blocks.  In the most complex case, it can be used as a repository for heterogeneous information.  In every case, the file remains easy to parse and an application can always skip the data it is not interested in; at the same time, different applications can share the file, and each of them can benefit of the information produced by the others.  Two or more files can be concatenated obtaining another valid file.
  9.  Implementations
    Some known implementations that read or write the pcapng file format are listed on the pcapng GitHub wiki [5].
  10.  Security Considerations
    TBD.
  11.  IANA Considerations
    TBD.
    [Open issue: decide whether the block types, option types, NRB Record types, etc. should be IANA registries.  And if so, what the IANA policy for each should be (see RFC 5226)]
  12.  Contributors
    Loris Degioanni and Gianluca Varenni were coauthoring this document before it was submitted to the IETF.
  13.  Acknowledgments
    The authors wish to thank Anders Broman, Ulf Lamping, Richard Sharpe and many others for their invaluable comments.
  14.  References
    14.1.  Normative References
      [RFC2119]  Bradner, S., "Key words for use in RFCs to Indicate Requirement Levels", BCP 14, RFC 2119, DOI 10.17487/RFC2119, March 1997, <https://www.rfc-editor.org/info/rfc2119>.
    14.2.  URIs
      [1] http://www.tcpdump.org/linktypes.html
      [2] http://www.tcpdump.org/linktypes.html
      [3] http://www.tcpdump.org/linktypes.html
      [4] http://pen.iana.org/pen/PenApplication.page
      [5] https://github.com/pcapng/pcapng/wiki/Implementations
      [6] https://www.winpcap.org/mailman/listinfo/pcap-ng-format
      [7] https://en.wikipedia.org/wiki/ARINC_429
      [8] http://www.tcpdump.org/linktypes.html
doc-ref:
  - https://xml2rfc.tools.ietf.org/cgi-bin/xml2rfc.cgi?url=https://raw.githubusercontent.com/pcapng/pcapng/master/draft-tuexen-opsawg-pcapng.xml&modeAsFormat=html/ascii&type=ascii
  - https://wiki.wireshark.org/Development/PcapNg
seq:
  - id: capture
    type: capture
types:
  capture:
    seq:
      - id: capture
        type: block
        repeat: eos
        doc: A capture file is organized in blocks, that are appended one to another to form the file.
  version:
    seq:
      - id: major
        -orig-id: Major Version
        type: u2
        doc: number of the current mayor version of the format. Current value is 1. This value should change if the format changes in such a way that code that reads the new format could not read the old format (i.e., code to read both formats would have to check the version number and use different code paths for the two formats) and code that reads the old format could not read the new format.
      - id: minor
        -orig-id: Minor Version
        type: u2
        doc: number of the current minor version of the format. Current value is 0. This value should change if the format changes in such a way that code that reads the new format could read the old format without checking the version number but code that reads the old format could not read all files in the new format.
  timestamp:
    doc: |
      In units specified by if_tsresol.
    seq:
      - id: high
        -orig-id: Timestamp (High)
        type: u4
        doc: upper 32 bits of a timestamp.
      - id: low
        -orig-id: Timestamp (Low)
        type: u4
        doc: lower 32 bits of a timestamp.
    instances:
      value:
        value: "high << 32 | low"
  options:
    doc: |
      Some options may be repeated several times; for example, a block can have multiple comments, and an Interface Description Block can give multiple IPv4 or IPv6 addresses for the interface if it has multiple IPv4 or IPv6 addresses assigned to it.  Other options may appear at most once in a given block.
      The option list is terminated by a option which uses the special 'End of Option' code (opt_endofopt).  Code that writes pcapng files MUST put an opt_endofopt option at the end of an option list.  Code that reads pcapng files MUST NOT assume an option list will have an opt_endofopt option at the end; it MUST also check for the end of the block, and SHOULD treat blocks where the option list has no opt_endofopt option as if the option list had an opt_endofopt option at the end.
    seq:
      - id: options
        type: option
        repeat: until
        repeat-until: _.type.type != type::opt_endofopt and _.length != 0
    types:
      option:
        doc: |
          Options are a list of Type - Length - Value fields, each one containing a single value:
        seq:
          - id: type
            -orig-id: Option Type
            type: type_descriptor
            doc: |
              it contains the code that specifies the type of the current TLV record. Option types whose Most Significant Bit is equal to one are reserved for local use; therefore, there is no guarantee that the code used is unique among all capture files (generated by other applications), and is most certainly not portable. For cross-platform globally unique vendor-specific extensions, the Custom Option MUST be used instead, as defined in Section 3.5.1).
          - id: length
            -orig-id: Option Length
            type: u2
            doc: it contains the actual length of the following 'Option Value' field without the padding octets.
          - id: value
            -orig-id: Option Value
            size: length
            type:
              switch-on: type.type
              cases:
                'type::comment': str
            doc: |
              it contains the value of the given option, padded to a 32-bit boundary. The actual length of this field (i.e. without the padding octets) is specified by the Option Length field.
              If an option's value is a string, the value is not necessarily zero-terminated.  Software that reads these files MUST NOT assume that strings are zero-terminated, and MUST treat a zero-value octet as a string terminator.
        types:
          type_descriptor:
            seq:
              - id: type
                type: u2
                enum: type
            instances:
              is_reserved_for_local_use:
                value: "type.to_i >> 15 == 1"
          custom:
            doc: |
              Customs Options are used for portable, vendor-specific data related to the block they're in.  A Custom Option can be in any block type that can have options, can be repeated any number of times in a block, and may come before or after other option types - except the opt_endofopt which is always the last option.  Different Custom Options, of different type codes and/or different Private Enterprise Numbers, may be used in the same pcapng file.  See Section 6 for additional details.
            seq:
              - id: private_enterprise_number
                -orig-id: Private Enterprise Number
                type: u4
                doc: |
                  An IANA-assigned Private Enterprise Number identifying the organization which defined the Custom Option.  See Section 6.1 for details.  The PEN number MUST be encoded using the same endianness as the Section Header Block it is within the scope of.
              - id: value
                -orig-id: Custom Data
                size-eos: true
                doc: the custom data, padded to a 32 bit boundary.
    enums:
      type:
        0:
          id: end_of_options
          -orig-id: opt_endofopt
          doc: The opt_endofopt option delimits the end of the optional fields.  This option MUST NOT be repeated within a given list of options.
        1:
          id: comment
          -orig-id: opt_comment
          doc: |
            The opt_comment option is a UTF-8 string containing human-readable comment text that is associated to the current block.  Line separators SHOULD be a carriage-return + linefeed ('\r\n') or just linefeed ('\n'); either form may appear and be considered a line separator.  The string is not null-terminated.
            Examples: "This packet is the beginning of all of our problems", "Packets 17-23 showing a bogus TCP retransmission!\r\n This is reported in bugzilla entry 1486.\nIt will be fixed in the future.".
        0xBAC:
          id: custom_bac
          doc: This option code identifies a Custom Option containing a UTF-8 string in the Custom Data portion, without NULL termination.  This Custom Option can be safely copied to a new file if the pcapng file is manipulated by an application; otherwise 19372 should be used instead.  See Section 6.2 for details.
        0xBAD:
          id: custom_bad
          doc: This option code identifies a Custom Option containing binary octets in the Custom Data portion.  This Custom Option can be safely copied to a new file if the pcapng file is manipulated by an application; otherwise 19372 should be used instead.  See Section 6.2 for details.
        0x4BAC:
          id: custom_4bac
          doc: This option code identifies a Custom Option containing a UTF-8 string in the Custom Data portion, without NULL termination. This Custom Option should not be copied to a new file if the pcapng file is manipulated by an application.  See Section 6.2 for details.
        0x4BAD:
          id: custom_4bad
          doc: This option code identifies a Custom Option containing binary octets in the Custom Data portion.  This Custom Option should not be copied to a new file if the pcapng file is manipulated by an application.  See Section 6.2 for details.
        0x8000: reserved_for_local_use
  packet_body:
    seq:
      - id: timestamp
        type: timestamp
      - id: captured_packet_size
        -orig-id: Captured Packet Length
        type: u4
        doc: |
          number of octets captured from the packet (i.e. the length of the Packet Data field).  It will be the minimum value among the Original Packet Length and the snapshot length for the interface (SnapLen, defined in Figure 10).  The value of this field does not include the padding octets added at the end of the Packet Data field to align the Packet Data field to a 32-bit boundary.
      - id: original_packet_size
        -orig-id: Original Packet Length
        type: u4
        doc: actual length of the packet when it was transmitted on the network.  It can be different from Captured Packet Length if the packet has been truncated by the capture process.
      - id: data
        -orig-id: Packet Data
        size: captured_packet_size
        #type:
        doc: |
          variable length, padded to 32 bits
          the data coming from the network, including link-layer headers. The actual length of this field is Captured Packet Length plus the padding to a 32-bit boundary.  The format of the link-layer headers depends on the LinkType field specified in the Interface Description Block (see Section 4.2) and it is specified in the entry for that format in the the tcpdump.org link-layer header types registry [2].
  block:
    doc: |
      This structure, shared among all blocks, makes it easy to process a file and to skip unneeded or unknown blocks.  Some blocks can contain other blocks inside (nested blocks).  Some of the blocks are mandatory, i.e. a capture file is not valid if they are not present, other are optional.
      The General Block Structure allows defining other blocks if needed. A parser that does not understand them can simply ignore their content.
      All the block bodies MAY embed optional fields.  Optional fields can be used to insert some information that may be useful when reading data, but that is not really needed for packet processing. Therefore, each tool can either read the content of the optional fields (if any), or skip some of them or even all at once.
      A block that may contain options must be structured so that the number of bytes of data in the Block Body that precede the options can be determined from that data; that allows the beginning of the options to be found. That is true for all standard blocks that support options; for Custom Blocks that support options, the Custom Data must be structured in such a fashion. This means that the Block Length field (present in the General Block Structure, see Section 3.1) can be used to determine how many bytes of optional fields, if any, are present in the block. That number can be used to determine whether the block has optional fields (if it is zero, there are no optional fields), to check, when processing optional fields, whether any optional fields remain, and to skip all the optional fields at once.
    seq:
      - id: type
        -orig-id: Block Type
        type: type_descriptor
        doc: |
          unique value that identifies the block.
          Values whose Most Significant Bit (MSB) is equal to 1 are reserved for local use.  They can be used to make extensions to the file format to save private data to the file.  The list of currently defined types can be found in Section 11.1.
      - id: total_length
        -orig-id: Block Total Length
        type: u4
        doc: "total size of this block, in octets.  For instance, the length of a block that does not have a body is 12 octets: 4 octets for the Block Type, 4 octets for the initial Block Total Length and 4 octets for the trailing Block Total Length.  This value MUST be a multiple of 4."
      - id: body
        -orig-id: Block Body
        size: total_length
        type:
          switch-on: type
          cases:
            'type::section_header': section_header
            'type::interface_description': interface_description
            'type::legacy_packet': legacy_packet
            'type::enhanced_packet': enhanced_packet
            'type::simple_packet': simple_packet
            'type::name_resolution': name_resolution
            'type::interface_statistics': interface_statistics
            'type::custom': custom
            #'type::compression': compression
            #'type::encryption': encryption
            #'type::fixed_length': fixed_length
            #'type::directory': directory
            #'type::traffic_statistics_and_monitoring': traffic_statistics_and_monitoring
            #'type::event_security': event_security
        doc: content of the block.
      - id: total_length_dup
        -orig-id: Block Total Length
        type: u4
        doc: This field is duplicated to permit backward file navigation.
    types:
      type_descriptor:
        seq:
          - id: type
            type: u4
            enum: type
        instances:
          is_reserved_for_local_use:
            value: "type.to_i >> 31 == 1"

      section_header:
        doc: |
          The Section Header Block (SHB) is mandatory.  It identifies the beginning of a section of the capture capture file.  The Section Header Block does not contain data but it rather identifies a list of blocks (interfaces, packets) that are logically correlated. Its format is shown in Figure 9.
        seq:
          - id: signature
            -orig-id: Byte-Order Magic
            type: u4
            doc: |
              magic number, whose value is the hexadecimal number 0x1A2B3C4D. This number can be used to distinguish sections that have been saved on little-endian machines from the ones saved on big-endian machines.
          - id: version
            -orig-id: Major Version
            type: version
          - id: size
            -orig-id: Section Length
            type: u8
            doc: |
              a signed 64-bit value specifying the length in octets of the following section, excluding the Section Header Block itself.  This field can be used to skip the section, for faster navigation inside large files.  Section Length equal -1 (0xFFFFFFFFFFFFFFFF) means that the size of the section is not specified, and the only way to skip the section is to parse the blocks that it contains.  Please note that if this field is valid (i.e. not negative), its value is always aligned to 32 bits, as all the blocks are aligned to and padded to 32-bit boundaries. Also, special care should be taken in accessing this field: since the alignment of all the blocks in the file is 32-bits, this field is not guaranteed to be aligned to a 64-bit boundary.  This could be a problem on 64-bit processors.
          - id: options
            -orig-id: Options
            type: options
            doc: optionally, a list of options (formatted according to the rules defined in Section 3.5) can be present.
        enums:
          options:
            #Adding new block types or options would not necessarily require that either Major or Minor numbers be changed, as code that does not know about the block type or option should just skip it; only if skipping a block or option does not work should the minor version number be changed.
            2:
              id: hardware
              -orig-id: shb_hardware
              doc: |
                The shb_hardware option is a UTF-8 string containing the description of the hardware used to create this section.
                Examples: "x86 Personal Computer", "Sun Sparc Workstation".
            3:
              id: os
              -orig-id: shb_os
              doc: |
                The shb_os option is a UTF-8 string containing the name of the operating system used to create this section.
                Examples: "Windows XP SP2", "openSUSE 10.2".
            4:
              id: application
              -orig-id: shb_userappl
              doc: |
                The shb_userappl option is a UTF-8 string containing the name of the application used to create this section.
                Examples: "dumpcap V0.99.7".
      interface_description:
        doc: |
          An Interface Description Block (IDB) is the container for information describing an interface on which packet data is captured.
          Tools that write / read the capture file associate an incrementing 32-bit number (starting from '0') to each Interface Definition Block, called the Interface ID for the interface in question.  This number is unique within each Section and identifies the interface to which the IDB refers; it is only unique inside the current section, so, two Sections can have different interfaces identified by the same Interface ID values.  This unique identifier is referenced by other blocks, such as Enhanced Packet Blocks and Interface Statistic Blocks, to indicate the interface to which the block refers (such the interface that was used to capture the packet that an Enhanced Packet Block contains or to which the statistics in an Interface Statistic  Block refer).
          There must be an Interface Description Block for each interface to which another block refers.  Blocks such as an Enhanced Packet Block or an Interface Statistics Block contain an Interface ID value referring to a particular interface, and a Simple Packet Block implicitly refers to an interface with an Interface ID of 0.  If the file does not contain any blocks that use an Interface ID, then the file does not need to have any IDBs.
          An Interface Description Block is valid only inside the section to which it belongs.  The structure of a Interface Description Block is shown in Figure 10.
        seq:
          - id: link_type
            -orig-id: LinkType
            type: u2
            doc: a value that defines the link layer type of this interface.  The list of Standardized Link Layer Type codes is available in the tcpdump.org link-layer header types registry [1].
          - id: reserved
            -orig-id: Reserved
            type: u2
            doc: not used - MUST be filled with 0, and ignored by pcapng file readers.
          - id: snap_length
            -orig-id: SnapLen
            type: u4
            doc: maximum number of octets captured from each packet.  The portion of each packet that exceeds this value will not be stored in the file.  A value of zero indicates no limit.
          - id: options
            -orig-id: Options (variable)
            type: options
        enums:
          options:
            2:
              id: name
              -orig-id: if_name
              doc: |
                The if_name option is a UTF-8 string containing the name of the device used to capture data.
                Examples: "eth0", "\Device\NPF_{AD1CE675-96D0-47C5-ADD0-2504B9126B68}".
            3:
              id: description
              -orig-id: if_description
              doc: |
                The if_description option is a UTF-8 string containing the description of the device used to capture data.
                Examples: "Broadcom NetXtreme", "First Ethernet Interface".
            4:
              id: ipv4_address
              -orig-id: if_IPv4addr
              doc: |
                The if_IPv4addr option is an IPv4 network address and corresponding netmask for the interface.  The first four octets are the IP address, and the next four octets are the netmask.  This option can be repeated multiple times within the same Interface Description Block when multiple IPv4 addresses are assigned to the interface.  Note that the IP address and netmask are both treated as four octets, one for each octet of the address or mask; they are not 32-bit numbers, and thus the endianness of the SHB does not affect this field's value.
                Examples: '192 168 1 1 255 255 255 0'.
            5:
              id: ipv6_address
              -orig-id: if_IPv6addr
              doc: |
                 The if_IPv6addr option is an IPv6 network address and corresponding prefix length for the interface.  The first 16 octets are the IP address and the next octet is the prefix length.  This option can be repeated multiple times within the same Interface Description Block when multiple IPv6 addresses are assigned to the interface.
                 Example: 2001:0db8:85a3:08d3:1319:8a2e:0370:7344/64 is written (in hex) as '20 01 0d b8 85 a3 08 d3 13 19 8a 2e 03 70 73 44 40'.
            6:
              id: mac_address
              -orig-id: if_MACaddr
              doc: |
                The if_MACaddr option is the Interface Hardware MAC address (48 bits), if available.
                Example: '00 01 02 03 04 05'.
            7:
              id: eui_address
              -orig-id: if_EUIaddr
              doc: |
                The if_EUIaddr option is the Interface Hardware EUI address (64 bits), if available.
                Example: '02 34 56 FF FE 78 9A BC'.
            8:
              id: speed
              -orig-id: if_speed
              doc: |
                The if_speed option is a 64-bit number for the Interface speed (in bits per second).
                Example: the 64-bit decimal number 100000000 for 100Mbps.
            9:
              id: timestamp_resolution
              -orig-id: if_tsresol
              doc: |
                The if_tsresol option identifies the resolution of timestamps. If the Most Significant Bit is equal to zero, the remaining bits indicates the resolution of the timestamp as a negative power of 10 (e.g. 6 means microsecond resolution, timestamps are the number of microseconds since 1970-01-01 00:00:00 UTC).  If the Most Significant Bit is equal to one, the remaining bits indicates the resolution as as negative power of 2 (e.g. 10 means 1/1024 of second).  If this option is not present, a resolution of 10^-6 is assumed (i.e. timestamps have the same resolution of the standard 'libpcap' timestamps).
                Example: '6'.
            10:
              id: time_zone
              -orig-id: if_tzone
              doc: |
                The if_tzone option identifies the time zone for GMT support (TODO: specify better).
                Example: TODO: give a good example.
            11:
              id: filter
              -orig-id: if_filter
              doc: |
                The if_filter option identifies the filter (e.g. "capture only TCP traffic") used to capture traffic.  The first octet of the Option Data keeps a code of the filter used (e.g. if this is a libpcap string, or BPF bytecode, and more).  More details about this format will be presented in Appendix XXX (TODO).  (TODO: better use different options for different fields? e.g. if_filter_pcap, if_filter_bpf, ...)
                Example: '00'"tcp port 23 and host 192.0.2.5".
            12:
              id: os_name
              -orig-id: if_os
              doc: |
                The if_os option is a UTF-8 string containing the name of the operating system of the machine in which this interface is installed.  This can be different from the same information that can be contained by the Section Header Block (Section 4.1) because the capture can have been done on a remote machine.
                Examples: "Windows XP SP2", "openSUSE 10.2".
            13:
              id: frame_check_sequence_bit_size
              -orig-id: if_fcslen
              doc: |
                The if_fcslen option is an 8-bit unsigned integer value that specifies the length of the Frame Check Sequence (in bits) for this interface. For link layers whose FCS length can change during time, the Enhanced Packet Block epb_flags Option can be used in each Enhanced Packet Block (see Section 4.3.1).
                Example: '4'.
            14:
              id: ts_offset
              -orig-id: if_tsoffset
              doc: |
                The if_tsoffset option is a 64-bit integer value that specifies an offset (in seconds) that must be added to the timestamp of each packet to obtain the absolute timestamp of a packet.  If the option is missing, the timestamps stored in the packet MUST be considered absolute timestamps.  The time zone of the offset can be specified with the option if_tzone. TODO: won't a if_tsoffset_low for fractional second offsets be useful for highly synchronized capture systems?
                Example: '1234'.
      legacy_packet:
        -orig-id: Packet
        doc: |
          The Packet Block is obsolete, and MUST NOT be used in new files.  Use the Enhanced Packet Block or Simple Packet Block instead.  This section is for historical reference only.
          A Packet Block was a container for storing packets coming from the network.
        seq:
          - id: interface_id
            -orig-id: Interface ID
            type: u2
            doc: specifies the interface this packet comes from; the correct interface will be the one whose Interface Description Block (within the current Section of the file) is identified by the same number (see Section 4.2) of this field.  The interface ID MUST be valid, which means that an matching interface description block MUST exist.
          - id: drops_count
            -orig-id: Drops Count
            type: u2
            doc: a local drop counter.  It specifies the number of packets lost (by the interface and the operating system) between this packet and the preceding one.  The value xFFFF (in hexadecimal) is reserved for those systems in which this information is not available.
          - id: packet_body
            type: packet_body
          - id: options
            -orig-id: Options (variable)
            type: options
        enums:
          options:
            2:
              id: pack_flags
              -orig-id: pack_flags
              doc: |
                The pack_flags option is the same as the epb_flags of the enhanced packet block.
                Example: '0'.
            3:
              id: pack_hash
              -orig-id: pack_hash
              doc: |
                The pack_hash option is the same as the epb_hash of the enhanced packet block.
                Examples: '02 EC 1D 87 97', '03 45 6E C2 17 7C 10 1E 3C 2E 99 6E C2 9A 3D 50 8E'.
      enhanced_packet:
        doc: |
          An Enhanced Packet Block (EPB) is the standard container for storing the packets coming from the network.  The Enhanced Packet Block is optional because packets can be stored either by means of this block or the Simple Packet Block, which can be used to speed up capture file generation; or a file may have no packets in it.  The format of an Enhanced Packet Block is shown in Figure 11.
              The Enhanced Packet Block is an improvement over the original, now obsolete, Packet Block (Appendix A):
              o  it stores the Interface Identifier as a 32-bit integer value. This is a requirement when a capture stores packets coming from a large number of interfaces
              o  unlike the Packet Block (Appendix A), the number of packets dropped by the capture system between this packet and the previous one is not stored in the header, but rather in an option of the block itself.
        seq:
          - id: interface_id
            -orig-id: Interface ID
            type: u4
            doc: |
              it specifies the interface this packet comes from; the correct interface will be the one whose Interface Description Block (within the current Section of the file) is identified by the same number (see Section 4.2) of this field.  The interface ID MUST be valid, which means that an matching interface description block MUST exist.
          - id: packet_body
            type: packet_body
          - id: options
            -orig-id: Options (variable)
            type: options
        enums:
          options:
            2:
              id: epb_flags
              -orig-id: epb_flags
              doc: |
                The epb_flags option is a 32-bit flags word containing link-layer information.  A complete specification of the allowed flags can be found in Section 4.3.1.
                Example: '0'.
            3:
              id: epb_hash
              -orig-id: epb_hash
              doc: |
                The epb_hash option contains a hash of the packet.  The first octet specifies the hashing algorithm, while the following octets contain the actual hash, whose size depends on the hashing algorithm, and hence from the value in the first octet.  The hashing algorithm can be: 2s complement (algorithm octet = 0, size=XXX), XOR (algorithm octet = 1, size=XXX), CRC32 (algorithm octet = 2, size = 4), MD-5 (algorithm octet = 3, size=XXX), SHA-1 (algorithm octet = 4, size=XXX).  The hash covers only the packet, not the header added by the capture driver: this gives the possibility to calculate it inside the network card.  The hash allows easier comparison/merging of different capture files, and reliable data transfer between the data acquisition system and the capture library.
                Examples: '02 EC 1D 87 97', '03 45 6E C2 17 7C 10 1E 3C 2E 99 6E C2 9A 3D 50 8E'.
            4:
              id: epb_dropcount
              -orig-id: epb_dropcount
              doc: |
                The epb_dropcount option is a 64-bit integer value specifying the number of packets lost (by the interface and the operating system) between this packet and the preceding one for the same interface or, for the first packet for an interface, between this packet and the start of the capture process.
                Example: '0'.
        types:
          flags:
            doc: |
              The Enhanced Packet Block Flags Word is a 32-bit value that contains link-layer information about the packet.
              The word is encoded as an unsigned 32-bit integer, using the endianness of the Section Header Block scope it is in.  In the following table, the bits are numbered with 0 being the most-significant bit and 31 being the least-significant bit of the 32-bit unsigned integer.  The meaning of the bits is the following:
            seq:
              #0706050403020100  1716151413121110  2726252423222120  3736353433323130
              #3031323334353637  2021222324252627  1011121314151617  0001020304050607
              #----------------  xxxxxxxxxxxxxxxx  --xxxxxxxxxxxxxx  ----------------
              - id: link_layer_dependent_errors
                type: link_layer_dependent_errors_le
              - id: second_word
                type: u2
            instances:
              in_out:
                value: ((second_word >> 14)&0b11)
                enum: in_out
              reception_type:
                value: ((second_word >> 11)&0b111)
                enum: reception_type
              fcs_length:
                value: ((second_word >> 7)&0b1111)
                doc: "FCS length, in octets (0000 if this information is not available). This value overrides the if_fcslen option of the Interface Description Block, and is used with those link layers (e.g. PPP) where the length of the FCS can change during time."
              reserved:
                value: (second_word &0b11111111)
                doc: "MUST be set to zero"
            types:
              link_layer_dependent_errors_le:
                seq:
                  - id: symbol
                    type: b1
                  - id: preamble
                    type: b1
                  - id: start_frame_delimiter
                    type: b1
                  - id: unaligned_frame
                    type: b1
                  - id: wrong_inter_frame_gap
                    type: b1
                  - id: packet_too_short
                    type: b1
                  - id: packet_too_long
                    type: b1
                  - id: crc_error
                    type: b1
                  - id: reserved
                    type: b9
                    doc: "other?? are 16 bit enough?"
            enums:
              in_out:
                0b00: not_available
                0b01: inbound
                0b10: outbound
              reception_type:
                0b000: not_specified
                0b001: unicast
                0b010: multicast
                0b011: broadcast
                0b100: promiscuous
      simple_packet:
        doc: |
          The Simple Packet Block (SPB) is a lightweight container for storing the packets coming from the network.  Its presence is optional.
          A Simple Packet Block is similar to an Enhanced Packet Block (see Section 4.3), but it is smaller, simpler to process and contains only a minimal set of information.  This block is preferred to the standard Enhanced Packet Block when performance or space occupation are critical factors, such as in sustained traffic capture applications.  A capture file can contain both Enhanced Packet Blocks and Simple Packet Blocks: for example, a capture tool could switch from Enhanced Packet Blocks to Simple Packet Blocks when the hardware resources become critical.
          The Simple Packet Block does not contain the Interface ID field. Therefore, it MUST be assumed that all the Simple Packet Blocks have been captured on the interface previously specified in the first Interface Description Block.
          The Simple Packet Block does not contain the timestamp because this is often one of the most costly operations on PCs.  Additionally, there are applications that do not require it; e.g. an Intrusion Detection System is interested in packets, not in their timestamp.
          A Simple Packet Block cannot be present in a Section that has more than one interface because of the impossibility to refer to the correct one (it does not contain any Interface ID field).
          The Simple Packet Block is very efficient in term of disk space: a snapshot whose length is 100 octets requires only 16 octets of overhead, which corresponds to an efficiency of more than 86%.
        seq:
          - id: packet_data
            -orig-id: Packet Data
            size-eos: true
            doc: |
              the data coming from the network, including link-layer headers.  The length of this field can be derived from the field Block Total Length, present in the Block Header, and it is the minimum value among the SnapLen (present in the Interface Description Block) and the Original Packet Length (present in this header).  The format of the data within this Packet Data field depends on the LinkType field specified in the Interface Description Block (see Section 4.2) and it is specified in the entry for that format in the tcpdump.org link-layer header types registry [3].
      name_resolution:
        doc: |
            The Name Resolution Block (NRB) is used to support the correlation of numeric addresses (present in the captured packets) and their corresponding canonical names and it is optional.  Having the literal names saved in the file prevents the need for performing name resolution at a later time, when the association between names and addresses may be different from the one in use at capture time. Moreover, the NRB avoids the need for issuing a lot of DNS requests every time the trace capture is opened, and also provides name resolution when reading the capture with a machine not connected to the network.
            A Name Resolution Block is often placed at the beginning of the file, but no assumptions can be taken about its position.  Multiple NRBs can exist in a pcapng file, either due to memory constraints or because additional name resolutions were performed by file processing tools, like network analyzers.
            A Name Resolution Block need not contain any Records, except the nrb_record_end Record which MUST be the last Record.  The addresses and names in NRB Records MAY be repeated multiple times; i.e., the same IP address may resolve to multiple names, the same name may resolve to the multiple IP addresses, and even the same address-to-name pair may appear multiple times, in the same NRB or across NRBs.
        seq:
          - id: records
            -orig-id: Name Resolution Records
            repeat: eos
            type: record
            doc: |
              This is followed by zero or more Name Resolution Records (in the TLV format), each of which contains an association between a network address and a name.  An nrb_record_end MUST be added after the last Record, and MUST exist even if there are no other Records in the NRB.
          - id: options
            -orig-id: Options (variable)
            type: options
        types:
          record:
            doc: contains an association between a network address and a name.
            seq:
              - id: type
                -orig-id: Record Type
                enum: record_type
                type: u2
                doc: |
                  Record Types other than those specified earlier MUST be ignored and skipped past.  More Record Types will likely be defined in the future, and MUST NOT break backwards compatibility.
              - id: size
                -orig-id: Record Value Length
                type: u2
              - id: value
                -orig-id: Record Value
                size: size
                doc: |
                  Each Record Value is aligned to and padded to a 32-bit boundary.  The corresponding Record Value Length reflects the actual length of the Record Value; it does not include the lengths of the Record Type field, the Record Value Length field, any padding for the Record Value, or anything after the Record Value.  For Record Types with name strings, the Record Length does include the zero-value octet terminating that string.  A Record Length of 0 is valid, unless indicated otherwise.
            enums:
              record_type:
                0x0000:
                  id: end
                  -orig-id: nrb_record_end
                  doc: The nrb_record_end record delimits the end of name resolution records.  This record is needed to determine when the list of name resolution records has ended and some options (if any) begin.
                0x0001:
                  id: ipv4
                  -orig-id: nrb_record_ipv4
                  doc: |
                    The nrb_record_ipv4 record specifies an IPv4 address (contained in the first 4 octets), followed by one or more zero-terminated UTF-8 strings containing the DNS entries for that address.  The minimum valid Record Length for this Record Type is thus 6: 4 for the IP octets, 1 character, and a zero-value octet terminator.  Note that the IP address is treated as four octets, one for each octet of the IP address; it is not a 32-bit word, and thus the endianness of the SHB does not affect this field's value.
                    Example: '127 0 0 1'"localhost".
                    [Open issue: is an empty string (i.e., just a zero-value octet) valid?]
                0x0002:
                  id: ipv6
                  -orig-id: nrb_record_ipv6
                  doc: |
                    The nrb_record_ipv6 record specifies an IPv6 address (contained in the first 16 octets), followed by one or more zero-terminated strings containing the DNS entries for that address.  The minimum valid Record Length for this Record Type is thus 18: 16 for the IP octets, 1 character, and a zero-value octet terminator.
                    Example: '20 01 0d b8 00 00 00 00 00 00 00 00 12 34 56 78'"somehost".
                    [Open issue: is an empty string (i.e., just a zero-value octet) valid?]
              options:
                2:
                  id: server_dns_name
                  -orig-id: ns_dnsname
                  doc: |
                    The ns_dnsname option is a UTF-8 string containing the name of the machine (DNS server) used to perform the name resolution.
                    Example: "our_nameserver".
                3:
                  id: server_ipv4_addr
                  -orig-id: ns_dnsIP4addr
                  doc: |
                    The ns_dnsIP4addr option specifies the IPv4 address of the DNS server.  Note that the IP address is treated as four octets, one for each octet of the IP address; it is not a 32-bit word, and thus the endianness of the SHB does not affect this field's value.
                    Example: '192 168 0 1'.
                4:
                  id: server_ipv6_addr
                  -orig-id: ns_dnsIP6addr
                  doc: |
                    The ns_dnsIP6addr option specifies the IPv6 address of the DNS server.
                    Example: '20 01 0d b8 00 00 00 00 00 00 00 00 12 34 56 78'.
      interface_statistics:
        doc: |
          The Interface Statistics Block (ISB) contains the capture statistics for a given interface and it is optional.  The statistics are referred to the interface defined in the current Section identified by the Interface ID field.  An Interface Statistics Block is normally placed at the end of the file, but no assumptions can be taken about its position - it can even appear multiple times for the same interface.
          All the fields that refer to packet counters are 64-bit values, represented with the octet order of the current section.  Special care must be taken in accessing these fields: since all the blocks are aligned to a 32-bit boundary, such fields are not guaranteed to be aligned on a 64-bit boundary.
        seq:
          - id: interface_id
            -orig-id: Interface ID
            type: u4
            doc: |
              specifies the interface these statistics refers to; the correct interface will be the one whose Interface Description Block (within the current Section of the file) is identified by same number (see Section 4.2) of this field.
          - id: timestamp
            type: timestamp
            doc: time this statistics refers to.
          - id: options
            -orig-id: Options (variable)
            type: options
        enums:
          options:
            2:
              id: start_time
              -orig-id: isb_starttime
              doc: |
                The isb_starttime option specifies the time the capture started; time will be stored in two blocks of four octets each.  The format of the timestamp is the same as the one defined in the Enhanced Packet Block (Section 4.3).
                Example: '97 c3 04 00 aa 47 ca 64' in Little Endian, decodes to 06/29/2012 06:16:50 UTC.
            3:
              id: end_time
              -orig-id: isb_endtime
              doc: |
                The isb_endtime option specifies the time the capture ended; time will be stored in two blocks of four octets each.  The format of the timestamp is the same as the one defined in the Enhanced Packet Block (Section 4.3).
                Example: '96 c3 04 00 73 89 6a 65', in Little Endian, decodes to 06/29/2012 06:17:00 UTC.
            4:
              id: interface_received
              -orig-id: isb_ifrecv
              doc: |
                The isb_ifrecv option specifies the 64-bit unsigned integer number of packets received from the physical interface starting from the beginning of the capture.
                Example: the decimal number 100.
            5:
              id: interface_dropped
              -orig-id: isb_ifdrop
              doc: |
                The isb_ifdrop option specifies the 64-bit unsigned integer number of packets dropped by the interface due to lack of resources starting from the beginning of the capture.
                Example: '0'.
            6:
              id: filter_accepted
              -orig-id: isb_filteraccept
              doc: |
                The isb_filteraccept option specifies the 64-bit unsigned integer number of packets accepted by filter starting from the beginning of the capture.
                Example: the decimal number 100.
            7:
              id: os_dropped
              -orig-id: isb_osdrop
              doc: |
                The isb_osdrop option specifies the 64-bit unsigned integer number of packets dropped by the operating system starting from the beginning of the capture.
                Example: '0'.
            8:
              id: delivered_to_user
              -orig-id: isb_usrdeliv
              doc: |
                The isb_usrdeliv option specifies the 64-bit unsigned integer number of packets delivered to the user starting from the beginning of the capture.  The value contained in this field can be different from the value 'isb_filteraccept - isb_osdrop' because some packets could still be in the OS buffers when the capture ended.
                Example: '0'.

      decryption_secrets:
        seq:
          - id: type
            -orig-id: Secrets Type
            type: u4
            doc-ref: https://www.winpcap.org/pipermail/pcap-ng-format/
          - id: length
            -orig-id: Secrets Length
            type: u4
          - id: data
            -orig-id: Secrets Data
            size: length
          - id: options
            -orig-id: Options
            type: options
        enums:
          type:
            0x544c534b:
              id: tls_key_log
              doc-ref: https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS/Key_Log_Format
            0x57474b4c:
              id: wireguard_key_log
              doc: text string - the output of Handshake extractor
              doc-ref: https://git.zx2c4.com/wireguard-tools/tree/contrib/extract-handshakes
            0x5a4e574b:
              id: zigbee_nwk_key_and_panid
              doc: little endian
              doc-ref:
                - https://zigbeealliance.org/wp-content/uploads/2019/11/docs-05-3474-21-0csg-zigbee-specification.pdf#%5B%7B%22num%22%3A1199%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C70%2C387%2C0%5D

            0x5a415053:
              id: zigbee_application_support_link_key
              doc-ref: https://zigbeealliance.org/wp-content/uploads/2019/11/docs-05-3474-21-0csg-zigbee-specification.pdf#%5B%7B%22num%22%3A1224%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C70%2C651%2C0%5D

      hone_common_block_header:
        seq:
          - id: process_id
            -orig-id: Process ID
            type: u4
          - id: timestamp
            type: timestamp

      hone_machine_info:
        doc-ref: https://raw.githubusercontent.com/google/linux-sensor/master/hone-pcapng.txt
        seq:
          - id: block_header
            type: hone_common_block_header
          - id: options
            -orig-id: Options
            type: options
        enums:
          options_types:
            2: state
            3: executable_path
            4: argv
            5: parent_process_id
            6: user_id
            7: group_id
            8: user_name
            9: group_name

      hone_connection_event:
        doc-ref: https://raw.githubusercontent.com/google/linux-sensor/master/hone-pcapng.txt
        seq:
          - id: block_header
            type: hone_common_block_header
          - id: options
            -orig-id: Options
            type: options
        enums:
          options_types:
            2: event_type
      custom:
        doc: |
          A Custom Block (CB) is the container for storing custom data that is not part of another block; for storing custom data as part of another block, see Section 3.5.1.  The Custom Block is optional, can be repeated any number of times, and can appear before or after any other block except the first Section Header Block which must come first in the file.  Different Custom Blocks, of different type codes and/or different Private Enterprise Numbers, may be used in the same pcapng file.
          The Custom Block uses the type code 0x00000BAD (2989 in decimal) for a custom block that pcapng re-writers can copy into new files, and the type code 0x40000BAD (1073744813 in decimal) for one that should not be copied.  See Section 6.2 for details.
        seq:
          - id: private_enterprise_number
            -orig-id: Private Enterprise Number (PEN)
            type: u4
            doc: |
              An IANA-assigned Private Enterprise Number identifying the organization which defined the Custom Block.  See Section 6.1 for details.  The PEN number MUST be encoded using the same endianness as the Section Header Block it is within the scope of.
          - id: custom_data
            -orig-id: Custom Data
            size-eos: true
      # Experimental Blocks (unfinished in the RFC)
      # compression:
        # doc: |
          # The Compression Block is optional.  A file can contain an arbitrary number of these blocks.  A Compression Block, as the name says, is used to store compressed data.
        # seq:
          # - id: type
            # -orig-id: Compr. Type
            # type: u1
            # enum: type
            # doc: specifies the compression algorithm. Probably some kind of dumb and fast compression algorithm could be effective with some types of traffic (for example web), but which?
          # - id: data
            # -orig-id: Compressed Data
            # type: capture
            # size-eos: true
            # doc: data of this block. Once decompressed, it is made of other blocks.
        # enums:
          # type:
            # 0: uncompressed
            # 1: lempel_ziv
            # 2: gzip
      # encryption:
        # doc: |
          # The Encryption Block is optional.  A file can contain an arbitrary number of these blocks.  An Encryption Block is used to store encrypted data.
        # seq:
          # - id: type
            # -orig-id: Encr. Type
            # type: u1
            # #enum: type
            # doc: specifies the encryption algorithm.  Possible values for this field are ??? (TODO) NOTE: this block should probably contain other fields, depending on the encryption algorithm.  To be defined precisely.
          # - id: data
            # -orig-id: Encrypted Data
            # type: capture
            # size-eos: true
            # doc: data of this block.  Once decrypted, it originates other blocks.
      # fixed_length:
        # doc: |
          # The Fixed Length Block is optional.  A file can contain an arbitrary number of these blocks.  A Fixed Length Block can be used to optimize the access to the file.  Its format is shown in Figure 18.  A Fixed Length Block stores records with constant size.  It contains a set of Blocks (normally Enhanced Packet Blocks or Simple Packet Blocks), of which it specifies the size.  Knowing this size a priori helps to scan the file and to load some portions of it without truncating a block, and is particularly useful with cell-based networks like ATM.
        # seq:
          # - id: cell_size
            # -orig-id: Cell Size
            # type: u2
            # doc: the size of the blocks contained in the data field.
          # - id: data
            # -orig-id: Fixed Size Data
            # size-eos: true
            # doc: data of this block.
      # directory:
        # doc: |
          # If present, this block contains the following information:
          # A directory block MUST be followed by at least N packets, otherwise it MUST be considered invalid.  It can be used to efficiently load portions of the file to memory and to support operations on memory mapped files.  This block can be added by tools like network analyzers as a consequence of file processing.
        # seq:
          # - id: packets_count
            # -orig-id: number of indexed packets
            # type: ?
            # doc: number of indexed packets (N)
          # - id: table
            # -orig-id: table with position and length of any indexed packet
            # size-eos: true
            # doc: table with position and length of any indexed packet (N entries)
      # traffic_statistics_and_monitoring:
        # doc: |
          # One or more blocks could be defined to contain network statistics or traffic monitoring information. They could be use to store data collected from RMON or Netflow probes, or from other network monitoring tools.
        # seq:

      # event_security:
        # doc: |
          # This block could be used to store events.  Events could contain generic information (for example network load over 50%, server down...) or security alerts.  An event could be:
            # o  skipped, if the application doesn't know how to do with it
            # o  processed independently by the packets.  In other words, the applications skips the packets and processes only the alerts
            # o  processed in relation to packets: for example, a security tool could load only the packets of the file that are near a security alert; a monitoring tool could skip the packets captured while the server was down.
        # seq:
    enums:
      type:
        #11.1.  Standardized Block Type Codes
        #  Every Block is uniquely identified by a 32-bit integer value, stored in the Block Header.
        #  As pointed out in Section 3.1, Block Type codes whose Most Significant Bit (bit 31) is set to 1 are reserved for local use by the application.
        #  All the remaining Block Type codes (0x00000000 to 0x7FFFFFFF) are standardized by this document.  Requests for new Block Type codes should be sent to the pcap- ng-format mailing list [6].
        #  [Open issue: reserve 0x40000000-0x7FFFFFFF for do-not-copy-bit range of base types?]
        0x80000000: reserved_for_local_use
        0x00000000: reserved
        0x0A0D0D0A:
          id: section_header
          doc: |
            The block type of the Section Header Block is the integer corresponding to the 4-char string "\r\n\n\r" (0x0A0D0D0A).  This particular value is used for 2 reasons:
            1.  This number is used to detect if a file has been transferred via FTP or HTTP from a machine to another with an inappropriate ASCII conversion.  In this case, the value of this field will differ from the standard one ("\r\n\n\r") and the reader can detect a possibly corrupted file.
            2.  This value is palindromic, so that the reader is able to recognize the Section Header Block regardless of the endianness of the section.  The endianness is recognized by reading the Byte Order Magic, that is located 8 octets after the Block Type.
        0x00000001: interface_description
        0x00000006: enhanced_packet
        0x00000003: simple_packet
        0x00000004: name_resolution
        0x00000005: interface_statistics
        0x00000bad: custom00000bad # Custom Block that rewriters can copy into new files (Section 4.7)
        0x40000bad: custom40000bad # Custom Block that rewriters should not copy into new files (Section 4.7)
        0x00000002:
          id: legacy_packet
          -orig-id: packet
        #alternative_packet
        #compression
        #encryption
        #fixed_length
        #directory
        #traffic_statistics_and_monitoring
        #event_security
        0x00000007: irig_timestamp # Gianluca Varenni <gianluca.varenni@cacetech.com>, CACE Technologies LLC)
        0x00000008: afdx_encapsulation_information # Gianluca Varenni <gianluca.varenni@cacetech.com>, CACE Technologies LLC)
        0x00000009: systemd_journal_export
        0x0000000A: decryption_secrets
        0x00000101: hone_machine_info
        0x00000102: hone_connection_event

        # sysdig blocks are not yet really implemented even in sysdig itself
        0x00000201: sysdig_machine_info_v0 # todo
        0x00000202: sysdig_process_info_v1 # todo
        0x00000209: sysdig_process_info_block_v3 # todo
        0x00000210: sysdig_process_info_block_v4 # todo
        0x00000211: sysdig_process_info_block_v5 # todo
        0x00000212: sysdig_process_info_block_v6 # todo
        0x00000213: sysdig_process_info_block_v7 # todo
        0x00000203: sysdig_fd_list # todo
        0x00000204: sysdig_event # todo
        0x00000208: sysdig_event_block_with_flags # todo
        0x00000205: sysdig_interface_list # todo
        0x00000206: sysdig_user_list # todo
        0x00000207: sysdig_process_info_v2 # todo
