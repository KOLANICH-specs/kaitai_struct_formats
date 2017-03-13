meta:
  id: flac
  endian: be
  title: flac
doc: |
  A FLAC bitstream consists of the "fLaC" marker at the beginning of the stream, followed by a mandatory metadata block (called the STREAMINFO block), any number of ther metadata blocks, then the audio frames.
  The audio data is composed of one or more audio frames. Each frame consists of a frame header, which contains a sync code, information about the frame like the block size, sample rate, number of channels, et cetera, and an 8-bit CRC. The frame header also contains either the sample number of the first sample in the frame (for variable-blocksize streams), or the frame number (for fixed-blocksize streams). This allows for fast, sample-accurate seeking to be performed. Following the frame header are encoded subframes, one for each channel, and finally, the frame is zero-padded to a byte boundary. Each subframe has its own header that specifies how the subframe is encoded.
  Since a decoder may start decoding in the middle of a stream, there must be a method to determine the start of a frame. A 14-bit sync code begins each frame. The sync code will not appear anywhere else in the frame header. However, since it may appear in the subframes, the decoder has two other ways of ensuring a correct sync. The first is to check that the rest of the frame header contains no invalid data. Even this is not foolproof since valid header patterns can still occur within the subframes. The decoder's final check is to generate an 8-bit CRC of the frame header and compare this to the CRC stored at the end of the frame header.
  Again, since a decoder may start decoding at an arbitrary frame in the stream, each frame header must contain some basic information about the stream because the decoder may not have access to the STREAMINFO metadata block at the start of the stream. This information includes sample rate, bits per sample, number of channels, etc. Since the frame header is pure overhead, it has a direct effect on the compression ratio. To keep the frame header as small as possible, FLAC uses lookup tables for the most commonly used values for frame parameters. For instance, the sample rate part of the frame header is specified using 4 bits. Eight of the bit patterns correspond to the commonly used sample rates of 8/16/22.05/24/32/44.1/48/96 kHz. However, odd sample rates can be specified by using one of the 'hint' bit patterns, directing the decoder to find the exact sample rate at the end of the frame header. The same method is used for specifying the block size and bits per sample. In this way, the frame header size stays small for all of the most common forms of audio data.
  Individual subframes (one for each channel) are coded separately within a frame, and appear serially in the stream. In other words, the encoded audio data is NOT channel-interleaved. This reduces decoder complexity at the cost of requiring larger decode buffers. Each subframe has its own header specifying the attributes of the subframe, like prediction method and order, residual coding parameters, etc. The header is followed by the encoded audio data for that channel.
  
  FLAC specifies a subset of itself as the Subset format. The purpose of this is to ensure that any streams encoded according to the Subset are truly "streamable", meaning that a decoder that cannot seek within the stream can still pick up in the middle of the stream and start decoding. It also makes hardware decoder implementations more practical by limiting the encoding parameters such that decoder buffer sizes and other resource requirements can be easily determined. flac generates Subset streams by default unless the "--lax" command-line option is used. The Subset makes the following limitations on what may be used in the stream:
    The blocksize bits in the frame header must be 0001-1110. The blocksize must be <=16384; if the sample rate is <= 48000Hz, the blocksize must be <=4608.
    The sample rate bits in the frame header must be 0001-1110.
    The bits-per-sample bits in the frame header must be 001-111.
    If the sample rate is <= 48000Hz, the filter order in LPC subframes must be less than or equal to 12, i.e. the subframe type bits in the subframe header may not be 101100-111111.
    The Rice partition order in a Rice-coded residual section must be less than or equal to 8.
seq:
  - id: signature
    contents: "fLaC"
  - id: metadata_blocks
    type: metadata_block
    repeat: expr
    repeat-expr: 1 or more
  - id: frames
    type: frame
    repeat: eos
types:
  metadata_block:
    seq:
      - id: header
        type: mb_header
        doc: "A block header that specifies the type and size of the metadata block data."
      - id: data:
        size: header.len
        type:
          switch-on: header.block_type
          cases:
            'block_type::streaminfo': mb_streaminfo
            'block_type::padding': mb_padding
            'block_type::application': mb_application
            'block_type::seektable': mb_seektable
            'block_type::vorbis_comment': mb_vorbis_comment
            'block_type::cuesheet': mb_cuesheet
            'block_type::picture': mb_picture
    types:
      mb_streaminfo:
        doc: |
          This block has information about the whole stream, like sample rate, number of channels, total number of samples, etc. It must be present as the first metadata block in the stream. Other metadata blocks may follow, and ones that the decoder doesn't understand, it will skip.
          NOTE: FLAC specifies a minimum block size of 16 and a maximum block size of 65535, meaning the bit patterns corresponding to the numbers 0-15 in the minimum blocksize and maximum blocksize fields are invalid. 
        seq:
          - id: minimum_block_size
            type: u2
            doc: "The minimum block size (in samples) used in the stream."
          - id: maximum_block_size
            type: u2
            doc: "The maximum block size (in samples) used in the stream. (Minimum blocksize == maximum blocksize) implies a fixed-blocksize stream."
          - id: minimum_frame_size
            type: u3
            doc: "The minimum frame size (in bytes) used in the stream. May be 0 to imply the value is not known."
          - id: maximum_frame_size
            type: u3
            doc: "The maximum frame size (in bytes) used in the stream. May be 0 to imply the value is not known."
          - id: sample_rate
            type: b20
            doc: "Sample rate in Hz. Though 20 bits are available, the maximum sample rate is limited by the structure of frame headers to 655350Hz. Also, a value of 0 is invalid."
          - id: last_channel
            type: b3
            doc: "(number of channels)-1. FLAC supports from 1 to 8 channels"
          - id: sample_size_m_1
            type: b5
            doc: "(bits per sample)-1. FLAC supports from 4 to 32 bits per sample. Currently the reference encoder and decoders only support up to 24 bits per sample."
          - id: Total_samples
            type: b36
            doc: "Total samples in stream. 'Samples' means inter-channel sample, i.e. one second of 44.1Khz audio will have 44100 samples regardless of the number of channels. A value of zero here means the number of total samples is unknown."
          - id: md5
            size: 16
            doc: "MD5 signature of the unencoded audio data. This allows the decoder to determine if an error exists in the audio data even when the error does not result in an invalid bitstream."
      mb_padding:
        doc: "This block allows for an arbitrary amount of padding. The contents of a PADDING block have no meaning. This block is useful when it is known that metadata will be edited after encoding; the user can instruct the encoder to reserve a PADDING block of sufficient size so that when metadata is added, it will simply overwrite the padding (which is relatively quick) instead of having to insert it into the right place in the existing file (which would normally require rewriting the entire file)."
        seq:
          - id: zeros
            content: 0
            repeat: eos
      mb_application:
        doc: "This block is for use by third-party applications. The only mandatory field is a 32-bit identifier. This ID is granted upon request to an application by the FLAC maintainers. The remainder is of the block is defined by the registered application. Visit the registration page if you would like to register an ID for your application with FLAC."
        seq:
          - id: app_id
            type: u4
            doc: "Registered application ID. (Visit the registration page to register an ID with FLAC.)"
          - id: data
            type: u1
            repeat: eos

      mb_seektable:
        doc: |
          This is an optional block for storing seek points. It is possible to seek to any given sample in a FLAC stream without a seek table, but the delay can be unpredictable since the bitrate may vary widely within a stream. By adding seek points to a stream, this delay can be significantly reduced. Each seek point takes 18 bytes, so 1% resolution within a stream adds less than 2k. There can be only one SEEKTABLE in a stream, but the table can have any number of seek points. There is also a special 'placeholder' seekpoint which will be ignored by decoders but which can be used to reserve space for future seek point insertion.
          NOTE: The number of seek points is implied by the metadata header 'length' field, i.e. equal to length / 18.
        seq:
          - id: seekpoints
            type: seekpoint
            repeat: eos
        types:
          seekpoint:
            doc: |
              NOTES
              For placeholder points, the second and third field values are undefined.
              Seek points within a table must be sorted in ascending order by sample number.
              Seek points within a table must be unique by sample number, with the exception of placeholder points.
              The previous two notes imply that there may be any number of placeholder points, but they must all occur at the end of the table.
            seq:
              - id: header
                type: u8
                doc: Sample number of first sample in the target frame, or 0xFFFFFFFFFFFFFFFF for a placeholder point.
              - id: header
                type: u8
                doc: Offset (in bytes) from the first byte of the first frame header to the first byte of the target frame's header.
              - id: header
                type: u2
                doc: Number of samples in the target frame.
      
      mb_vorbis_comment:
        doc: "This block is for storing a list of human-readable name/value pairs. Values are encoded using UTF-8. It is an implementation of the Vorbis comment specification (without the framing bit). This is the only officially supported tagging mechanism in FLAC. There may be only one VORBIS_COMMENT block in a stream. In some external documentation, Vorbis comments are called FLAC tags to lessen confusion."
        seq:
          - id: comment
            type: str
            doc: |
              Also known as FLAC tags, the contents of a vorbis comment packet as specified [here](https://www.xiph.org/vorbis/doc/v-comment.html) (without the framing bit). Note that the vorbis comment spec allows for on the order of 2 ^ 64 bytes of data where as the FLAC metadata block is limited to 2 ^ 24 bytes. Given the stated purpose of vorbis comments, i.e. human-readable textual information, this limit is unlikely to be restrictive. Also note that the 32-bit field lengths are little-endian coded according to the vorbis spec, as opposed to the usual big-endian coding of fixed-length integers in the rest of FLAC.
            doc-ref: "https://www.xiph.org/vorbis/doc/v-comment.html"

      mb_cuesheet:
        doc: "This block is for storing various information that can be used in a cue sheet. It supports track and index points, compatible with Red Book CD digital audio discs, as well as other CD-DA metadata such as media catalog number and track ISRCs. The CUESHEET block is especially useful for backing up CD-DA discs, but it can be used as a general purpose cueing mechanism for playback."
        seq:
          - id: Media catalog number
            type: str
            size: 128
            doc: |
              Media catalog number, in ASCII printable characters 0x20-0x7e. In general, the media catalog number may be 0 to 128 bytes long; any unused characters should be right-padded with NUL characters. For CD-DA, this is a thirteen digit number, followed by 115 NUL bytes.
          - id: number of lead-in samples
            type: u8
            doc: |
              The number of lead-in samples. This field has meaning only for CD-DA cuesheets; for other uses it should be 0. For CD-DA, the lead-in is the TRACK 00 area where the table of contents is stored; more precisely, it is the number of samples from the first sample of the media to the first sample of the first index point of the first track. According to the Red Book, the lead-in must be silence and CD grabbing software does not usually store it; additionally, the lead-in must be at least two seconds but may be longer. For these reasons the lead-in length is stored here so that the absolute position of the first track can be computed. Note that the lead-in stored here is the number of samples up to the first index point of the first track, not necessarily to INDEX 01 of the first track; even the first track may have INDEX 00 data.
          - id: is_cd
            type: b1
            doc: 1 if the CUESHEET corresponds to a Compact Disc, else 0.
          - id: reserved0
            type: b7
            content: 0
          - id: reserved1
            size: 258
            content: 0
          - id: number_of_tracks
            size: u1
            doc: "The number of tracks. Must be at least 1 (because of the requisite lead-out track). For CD-DA, this number must be no more than 100 (99 regular tracks and one lead-out track)."
          - id: tracks
            type: cuesheet_track
            doc: "One or more tracks. A CUESHEET block is required to have a lead-out track; it is always the last track in the CUESHEET. For CD-DA, the lead-out track number must be 170 as specified by the Red Book, otherwise is must be 255."
            repeat: expr
            repeat-expr: number_of_tracks
        types:
          cuesheet_track:
            seq:
              - id: Track offset
                type: u8
                doc: "Track offset in samples, relative to the beginning of the FLAC audio stream. It is the offset to the first index point of the track. (Note how this differs from CD-DA, where the track's offset in the TOC is that of the track's INDEX 01 even if there is an INDEX 00.) For CD-DA, the offset must be evenly divisible by 588 samples (588 samples = 44100 samples/sec * 1/75th of a sec)."
              - id: Track number
                type: u1
                doc: "A track number of 0 is not allowed to avoid conflicting with the CD-DA spec, which reserves this for the lead-in. For CD-DA the number must be 1-99, or 170 for the lead-out; for non-CD-DA, the track number must for 255 for the lead-out. It is not required but encouraged to start with track 1 and increase sequentially. Track numbers must be unique within a CUESHEET."
              - id: Track ISRC
                type: str
                size: 12
                doc: "This is a 12-digit alphanumeric code; A value of 12 ASCII NUL characters may be used to denote absence of an ISRC."
                doc-ref:
                  - "https://www.ifpi.org/content/library/isrc_handbook.pdf"
                  - "http://www.disctronics.co.uk/technology/cdaudio/cdaud_isrc.htm"
              - id: track type
                type: b1
                doc: "0 for audio, 1 for non-audio. This corresponds to the CD-DA Q-channel control bit 3."
              - id: The pre-emphasis flag
                type: b1
                doc: "0 for no pre-emphasis, 1 for pre-emphasis. This corresponds to the CD-DA Q-channel control bit 5; see [here](http://www.chipchapin.com/CDMedia/cdda9.php3)."
              - id: reserved0
                type: b6
                content: 0
              - id: reserved1
                size: 13
                content: 0
              - id: number_of_track_index_points
                type: u1
                doc: "There must be at least one index in every track in a CUESHEET except for the lead-out track, which must have zero. For CD-DA, this number may be no more than 100."
              - id: tracks_index_points
                type: cuesheet_track_index
                doc: "The number of track index points. There must be at least one index in every track in a CUESHEET except for the lead-out track, which must have zero. For CD-DA, this number may be no more than 100. For all tracks except the lead-out track, one or more track index points."
            types:
              cuesheet_track_index:
                seq:
                  - id: index_point_offset
                    type: u8
                    doc: "Offset in samples, relative to the track offset, of the index point. For CD-DA, the offset must be evenly divisible by 588 samples (588 samples = 44100 samples/sec * 1/75th of a sec). Note that the offset is from the beginning of the track, not the beginning of the audio data."
                  - id: index_point_offset
                    type: u1
                    doc: "The index point number. For CD-DA, an index number of 0 corresponds to the track pre-gap. The first index in a track must have a number of 0 or 1, and subsequently, index numbers must increase by 1. Index numbers must be unique within a track."
                  - id: reserved
                    size: 3
                    content: 0

      mb_picture:
        doc: "This block is for storing pictures associated with the file, most commonly cover art from CDs. There may be more than one PICTURE block in a file. The picture format is similar to the APIC frame in ID3v2. The PICTURE block has a type, MIME type, and UTF-8 description like ID3v2, and supports external linking via URL (though this is discouraged). The differences are that there is no uniqueness constraint on the description field, and the MIME type is mandatory. The FLAC PICTURE block also includes the resolution, color depth, and palette size so that the client can search for a suitable picture without having to scan them all."
        seq:
          - id: picture_type
            type: u4
            doc: "The picture type according to the ID3v2 APIC frame. There may only be one each of picture types 32x32_file_icon and other_file_icon in a file."
            enum: pic_type
          - id: mime_type_len
            type: u4
            doc: "The length of the MIME type string in bytes."
          - id: mime_type
            type: str
            size: mime_type_len
            doc: "The MIME type string, in printable ASCII characters 0x20-0x7e. The MIME type may also be --> to signify that the data part is a URL of the picture instead of the picture data itself."
          - id: description_len
            type: u4
            doc: "The length of the MIME type string in bytes."
          - id: description
            type: str
            size: description_len
            doc: "The description of the picture, in UTF-8."
          - id: width
            type: u4
            doc: "The width of the picture in pixels."
          - id: height
            type: u4
            doc: "The height of the picture in pixels."
          - id: color_depth
            type: u4
            doc: "The color depth of the picture in bits-per-pixel."
          - id: indexed_colors_depth
            type: u4
            doc: "For indexed-color pictures (e.g. GIF), the number of colors used, or 0 for non-indexed pictures."
          - id: pic_data_len
            type: u4
            doc: "The length of the picture data in bytes."
          - id: pic_data
            size: pic_data_len
            doc: "The binary picture data."
        enums:
          pic_type: # Others are reserved and should not be used. 
            0: other
            1: 32x32_file_icon #32x32 pixels 'file icon' (png only)
            2: other_file_icon
            3: front_cover
            4: back_cover
            5: leaflet_page
            6: media # (e.g. label side of cd)
            7: lead_performer #lead artist/lead performer/soloist
            8: performer #artist/performer
            9: conductor
            10: band # band/orchestra
            11: composer
            12: lyricist # text writer
            13: recording_location
            14: during_recording
            15: during_performance
            16: screen_capture
            17: a_bright_coloured_fish
            18: illustration
            19: performer_logo
            20: publisher_logo

      mb_header:
        seq:
          - id: is_last
            type: b1
          - id: block_type
            type: b7
            enum: type
          - id: len
            type: u3
            doc: "Length (in bytes) of metadata to follow (does not include the size of the mb_HEADER)"
        enums:
          block_type:
            0 : streaminfo
            1 : padding
            2 : application
            3 : seektable
            4 : vorbis_comment
            5 : cuesheet
            6 : picture
            127 : invalid #to avoid confusion with a frame sync code

  frame:
    seq:
      - id: header
        type: frame_header
      - id: subframes
        type: subframe
        repeat: expr
        repeat-expr: header.channels_count
        doc: "Where defined, the channel order follows SMPTE/ITU-R recommendations."
      - id: padding
        type: subframe
        doc: Zero-padding to byte alignment.
      - id: footer
        type: frame_footer
    types:
      frame_header:
        seq:
          - id: sync_code0
            type: u1
            content: 0xFF
          - id: sync_code1
            type: b6
            content: 0b111110
          - id: reserved
            type: b1
            content: 0
          - id: variable_block_size
            type: b1
            doc: |
              0 : fixed-blocksize stream; frame header encodes the frame number
              1 : variable-blocksize stream; frame header encodes the sample number
              must be the same throughout the entire stream.
              determines how to calculate the sample number of the first sample in the frame. If the bit is 0 (fixed-blocksize), the frame header encodes the frame number as above, and the frame's starting sample number will be the frame number times the blocksize. If it is 1 (variable-blocksize), the frame header encodes the frame's starting sample number itself. (In the case of a fixed-blocksize stream, only the last block may be shorter than the stream blocksize; its starting sample number will be calculated as the frame number times the previous frame's blocksize, or zero if it is the first frame).
          - id: block_size_enc
            doc: "in inter-channel samples"
            type: b4
            enum: block_size
          - id: sample_rate
            type: b4
            enum: sample_rate
          - id: channel_assignment
            type: b4
            enum: channel_assignment
          - id: sample_size_enc
            type: b3
            enum: sample_size
            doc: "[encoded] Sample size in bits"
          - id: reserved
            type: b1
            content: 0
          #The "UTF-8" coding used for the sample/frame number is the same variable length code used to store compressed UCS-2, extended to handle larger input.
          - id: coded sample number
            if: variable_block_size
            doc: "UTF-8" coded sample number (decoded number is 36 bits)"
            size: 8-56 bits
          - id: coded_frame_number
            if: !variable_block_size
            doc: "UTF-8" coded frame number (decoded number is 31 bits)
            size: 8-48 bits
          <?> 	if(blocksize bits == 011x)
             8/16 bit (blocksize-1)
          <?> 	if(sample rate bits == 11xx)
             8/16 bit sample rate
          - id: crc_8
            type: u1
            doc: "CRC-8 (polynomial = x^8 + x^2 + x^1 + x^0, initialized with 0) of everything before the crc, including the sync code
        instances:
          channels_count:
            value: ((0b1000&channel_assignment!=0)?2:((channel_assignment & 0b0111)+1))
            doc: "if channel_assignment ∈ [0b0000, 0b0111]  channels_count=channel_assignment+1, else channels_count=2 (joint stereo)"
          sample_size:
            value:
              switch-on: sample_size_enc
              cases:
                'sample_size::from_streaminfo': _root.metadata_blocks[0].data.sample_size
                'sample_size::eight' : 8
                'sample_size::tvelve' : 12
                'sample_size::sixteen' : 16
                'sample_size::twenty' : 20
                'sample_size::twenty_four' : 24
          block_size_in_samples:
            value:
              switch-on: block_size_enc
              cases:
                '0b0001': 192
                '0b0010': 576 * (2**(block_size_enc-2)) #576
                '0b0011': 576 * (2**(block_size_enc-2)) #1152
                '0b0100': 576 * (2**(block_size_enc-2)) #2304
                '0b0101': 576 * (2**(block_size_enc-2)) #4608
                
                '0b0110': get 8 bit (blocksize-1) from end of header
                '0b0111': get 16 bit (blocksize-1) from end of header
                
                '0b1000': 256 * (2**(block_size_enc-8)) # 256
                '0b1001': 256 * (2**(block_size_enc-8)) # 512
                '0b1010': 256 * (2**(block_size_enc-8)) # 1024
                '0b1011': 256 * (2**(block_size_enc-8)) # 2048
                '0b1100': 256 * (2**(block_size_enc-8)) # 4096
                '0b1101': 256 * (2**(block_size_enc-8)) # 8192
                '0b1110': 256 * (2**(block_size_enc-8)) # 16384
                '0b1111': 256 * (2**(block_size_enc-8)) # 32768
          sample_rate:
            value:
              switch-on: block_size_enc
              cases:
                '0b0000': _root.metadata_blocks[0].data.sample_rate
                '0b0001': 88200
                '0b0010': 176400
                '0b0011': 192000
                '0b0100': 8000
                '0b0101': 16000
                '0b0110': 22050
                '0b0111': 24000
                '0b1000': 32000
                '0b1001': 44100
                '0b1010': 48000
                '0b1011': 96000
                '0b1100': get 8 bit sample rate (in kHz) from end of header
                '0b1101': get 16 bit sample rate (in Hz) from end of header
                '0b1110': get 16 bit sample rate (in tens of Hz) from end of header
        enums:
          channel_assignment:
            0: mono
            1: stereo
            2: LRC
            3: quadro
            4: five_zero
            5: five_one
            6: seven
            7: eight
            0b1000 : left_side_stereo # channel 0 is the left channel, channel 1 is the side(difference) channel
            0b1001 : right_side_stereo # channel 0 is the side(difference) channel, channel 1 is the right channel
            0b1010 : mid_side_stereo # channel 0 is the mid(average) channel, channel 1 is the side(difference) channel
          sample_size:
            0b000 : from_streaminfo
            0b001 : eight
            0b010 : tvelve
            0b011 : reserved0
            0b100 : sixteen
            0b101 : twenty
            0b110 : twenty_four
            0b111 : reserved1
      frame_footer:
        seq:
          - id: crc_16
            type: u2
            doc: "CRC-16 (polynomial = x^16 + x^15 + x^2 + x^0, initialized with 0) of everything before the crc, back to and including the frame header sync code"

      subframe:
        seq:
          - id: header
            type: subframe_header
          - id: data
            type:
              switch-on: header.subframe_type
              cases:
                'subframe_type::subframe_constant': subframe_constant
                'subframe_type::subframe_verbatim': subframe_verbatim
                'subframe_type::subframe_fixed': subframe_fixed
                'subframe_type::subframe_lpc': subframe_lpc
        types:
          subframe_header:
            seq:
              - id: padding
                type: b1
                doc: "Zero bit padding, to prevent sync-fooling string of 1s"
                content: 0
              - id: subframe_lpc
                type: b1
              - id: lpc_order_m1
                type: b6
                if: subframe_lpc
                doc: "1xxxxx : SUBFRAME_LPC, xxxxx=order-1"
              - id: reserved
                type: b1
                contents: 0
                if: !subframe_lpc
              - id: subframe_fixed
                type: b1
                if: !subframe_lpc && !reserved
              - id: fixed_order
                type: b3
                if: !subframe_lpc && !reserved && subframe_fixed
              - id: subframe_type_other
                type: b6
                doc: "Zero bit padding, to prevent sync-fooling string of 1s"
                enum: subframe_type
                if: !subframe_lpc && !reserved && !subframe_fixed
              - id: wasted_bits_per_sample
                type: b1
                contents: 0b0
                doc: |
                  <1+k> 	'Wasted bits-per-sample' flag:
                  0 : no wasted bits-per-sample in source subblock, k=0
                  1 : k wasted bits-per-sample in source subblock, k-1 follows, unary coded; e.g. k=3 => 001 follows, k=7 => 0000001 follows.
                terminator: 0b1
            instances:
              subframe_type:
                value: (subframe_lpc ? subframe_type::subframe_lpc : 0) + (subframe_verbatim ? subframe_type::subframe_verbatim : 0) + subframe_type_other
                enum: subframe_type
            enums:
              subframe_type:
                0b000000 : subframe_constant
                0b000001 : subframe_verbatim
                0b001000 : subframe_fixed
                0b100000 : subframe_lpc


          subframe_constant:
            seq:
              - id: constant
                type: bn
                doc: "<n> 	Unencoded constant value of the subblock, n = frame's bits-per-sample."
          subframe_fixed:
            seq:
              - id: warmup
                type: bn
                doc: "Unencoded warm-up samples (n = frame's bits-per-sample * predictor order)."
              - id: residual
                type: residual
                doc: "Encoded residual"
          subframe_lpc:
            seq:
              - id: warmup
                type: bn
                doc: "Unencoded warm-up samples (n = frame's bits-per-sample * lpc order)."
              - id: coefficients_precision
                type: b4
                doc: "(Quantized linear predictor coefficients' precision in bits)-1 (1111 = invalid)."
              - id: coefficient_shift
                type: b5
                doc: "Quantized linear predictor coefficient shift needed in bits (NOTE: this number is signed two's-complement)."
              - id: coefficients
                type: bn
                doc: "Unencoded predictor coefficients (n = qlp coeff precision * lpc order) (NOTE: the coefficients are signed two's-complement)."
              - id: residual
                type: residual
                doc: "Encoded residual"
          subframe_verbatim:
            seq:
              - id: unencoded_subblock
                type: bn
                doc: "Unencoded subblock; n = frame's bits-per-sample, i = frame's blocksize."

          residual:
            seq:
              - id: method
                type: b2
              - id: data
                type:
                  switch-on: header.subframe_type
                  cases:
                    'method::rice_4': residual_coding_method_partitioned_rice
                    'method::rice_5': residual_coding_method_partitioned_rice
            enum:
              method:
                0b00 : rice_4 #partitioned Rice coding with 4-bit Rice parameter; RESIDUAL_CODING_METHOD_PARTITIONED_RICE follows
                0b01 : rice_5 #partitioned Rice coding with 5-bit Rice parameter; RESIDUAL_CODING_METHOD_PARTITIONED_RICE2 follows
            types:
              residual_coding_method_partitioned_rice:
                seq:
                  - id: order
                    type: b4
                  - id: partitions
                    type:
                      switch-on: _parent.subframe_type
                      cases:
                        'method::rice_4': rice_partition
                        'method::rice_5': rice2_partition
                    repeat: expr
                    repeat-expr: 2**order
                types:
                  rice_partition:
                    seq:
                      - id: parameter
                        type: b4
                      - id: unencoded_binary
                        type: b5
                        if: code == 0b1111
                      - id: encoded_residual
                        type: ?
                        if: code != 0b1111
                        doc: |
                          if the partition order is zero, n = frame's blocksize - predictor order
                          else if this is not the first partition of the subframe, n = (frame's blocksize / (2^partition order))
                          else n = (frame's blocksize / (2^partition order)) - predictor order
                  rice2_partition:
                    seq:
                      - id: parameter
                        type: b5
                      - id: unencoded_binary
                        type: b5
                        if: code == 0b11111
                      - id: encoded_residual
                        type: ?
                        if: code != 0b11111
                        doc: |
                          if the partition order is zero, n = frame's blocksize - predictor order
                          else if this is not the first partition of the subframe, n = (frame's blocksize / (2^partition order))
                          else n = (frame's blocksize / (2^partition order)) - predictor order
