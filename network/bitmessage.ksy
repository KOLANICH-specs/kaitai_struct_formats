meta:
  id: bitmessage
  title: BitMessage protocol
  application: BitMessage
  license: Unlicense
  ks-version: 0.7
  endian: be
  encoding: utf-8
  xrefs:
    wikidata: Q13903041
doc: |
  Bitmessage is a decentralysed messagging system.
doc-ref: https://bitmessage.org/wiki/Protocol_specification
types:
  var_int:
    doc: |
      Variable-length integer
      Integer can be encoded depending on the represented value to save space. Variable length integers always precede an array/vector of a type of data that may vary in length. Varints MUST use the minimum possible number of bytes to encode a value. For example; the value 6 can be encoded with one byte therefore a varint that uses three bytes to encode the value 6 is malformed and the decoding task must be aborted. 
    seq:
      - id: u1
        type: u1
      - id: number
        type:
          switch-on: type
          cases:
            "type::u2": u2
            "type::u4": u4
            "type::u8": u8
        if: u1 >= 0xfd
    enums:
      type:
        0xfd: u2
        0xfe: u4
        0xff: u8
    instances:
      type:
        value: u1
        enum: type
      value:
        value: number
        if: u1 >= 0xfd
      value:
        value: u1
        if: type_or_u1 < 0xfd

  var_str:
    doc: variable_length_string
    seq:
      - id: length
        type: var_int
        doc: Length of the string
      - id: string
        type: str
        size: length.value
        doc: The string itself (can be empty)
  var_int_list:
    doc: variable-length list of integers
    seq:
      - id: count
        type: var_int
        doc: Number of var_ints below
      - id: data
        type: var_int
        repeat: expr
        repeat-expr: count.value
  
  network_address:
    doc: When a network address is needed in version message.
    -orig-id:: network_address
    seq:
      - id: services
        type: u8
        doc: same service(s) listed in version
      - id: ipv6
        size: 16
        doc: |
          IPv6 address.
          IPv4 addresses are written into the message as a 16 byte IPv4-mapped IPv6 address 
          (12 bytes 00 00 00 00  00 00 00 00  00 00 FF FF, followed by the 4 bytes of the IPv4 address).
      - id: port
        type: u2
        doc: port number
  network_address_ex:
    doc: When a network address is needed somewhere, this structure is used.
    seq:
      - id: time
        type: u8
        doc: the Time.
      - id: stream
        type: u4
        doc: Stream number for this node
      - id: network_address
        type: network_address

  network_address_list:
    seq:
      - id: count
        type: var_int
        doc: "Number of address entries (max: 1000)"
      - id: addr_list
        type: network_address_ex
        repeat: expr
        repeat-expr: count.value
  ecc_public_key:
    doc: The ECC public key used for encryption (uncompressed format; normally prepended with \x04 )
    seq:
      - id: data
        size: 64
  ecc_auth_enc_key_pair:
    seq:
      - id: public_signing_key
        type: ecc_public_key
      - id: public_encryption_key
        type: ecc_public_key
  ecc_signature:
    seq:
      - id: sig_length
        type: var_int
        doc: Length of the signature
      - id: signature
        size: sig_length.value
        doc: The ECDSA signature.
  sha256:
    seq:
      - id: hash
        size: 32
  ripemd:
    seq:
      - id: hash
        size: 20

  tag:
    doc: ???
    seq:
      - id: data
        size: 32

  
  inventory_vector:
    doc: Inventory vectors are used for notifying other nodes about objects they have or data which is being requested. Two rounds of SHA-512 are used, resulting in a 64 byte hash. Only the first 32 bytes are used; the later 32 bytes are ignored. 
    seq:
    - id: hash
      size: 32
      doc: Hash of the object
  inventory_vectors_list:
    seq:
      - id: count
        type: var_int
        doc: Number of inventory entries (maximum 50000)
      - id: inventory
        type: inventory_vector
        repeat: expr
        repeat-expr: count.value
        doc: Inventory vectors
  encrypted_payload:
    doc: Bitmessage uses [ECIES](https://en.wikipedia.org/wiki/Integrated_Encryption_Scheme) to encrypt its messages. For more information see [Encryption]
    doc-ref: https://en.wikipedia.org/wiki/Integrated_Encryption_Scheme
    seq:
      - id: iv
        size: 16
        doc: Initialization Vector used for AES-256-CBC
      - id: curve_type
        type: u2
        enum: curve_type
        doc: Elliptic Curve type
      - id: x
        type: key_component
        doc: X component of public key R
      - id: y
        type: key_component
        doc: Y component of public key R
      - id: encrypted
        size: sizeof() - sizeof(iv, y) - sizeof(mac)
        process: decrypt
        doc: Cipher text
      - id: mac
        type: sha256
        doc: HMACSHA256 Message Authentication Code
    instances:
      decrypted:
        value: encrypted
    types:
      key_component:
        seq:
          - id: length
            type: u2
          - id: component
            size: length
    enums:
      curve_type:
        0x02ca: sect283r1
  message: #protocol message, not the mail message
    seq:
      - id: signature
        -orig-id:: magic
        contents: [0xE9, 0xBE, 0xB4, 0xD9]
        doc: Magic value indicating message origin network, and used to seek to next message when stream state is unknown
      - id: command
        type: strz
        size: 12
        encoding: ascii
        doc: a string identifying the packet content, NULL padded (non-NULL padding results in packet rejected)
      - id: length
        type: u4
        doc: Length of payload in number of bytes. Because of other restrictions, there is no reason why this length would ever be larger than 1600003 bytes. Some clients include a sanity-check to avoid processing messages which are larger than this.
      - id: checksum
        type: u4
        doc: First 4 bytes of sha512(payload)
      - id: message_payload
        size: length
        type:
          switch-on: command
          cases:
            "error": error
            "version": version
            #"verack": verack
            #The verack message is sent in reply to version. This message consists of only a message header with the command string "verack". The TCP timeout starts out at 20 seconds; after verack messages are exchanged, the timeout is raised to 10 minutes.
            #If both sides announce that they support SSL, they MUST perform a SSL handshake immediately after they both send and receive verack. During this SSL handshake, the TCP client acts as a SSL client, and the TCP server acts as a SSL server. The current implementation (v0.5.4 or later) requires the AECDH-AES256-SHA cipher over TLSv1 protocol, and prefers the secp256k1 curve (but other curves may be accepted, depending on the version of python and OpenSSL used). 
            #"ping": ping
            #"pong": pong
            #should relay
            "addr": addr
            "inv": inv
            "getdata": getdata
            "object": object
            _: object
        doc: The actual data, a message or an object.
    types:
      error:
        seq:
          - id: fatal
            type: var_int
          - id: ban_time
            type: var_int
          - id: inventory_vector
            type: inventory_vector
          - id: error_text
            type: var_str
      
      version:
        doc: |
          When a node creates an outgoing connection, it will immediately advertise its version. The remote node will respond with its version. No futher communication is possible until both peers have exchanged their version. 
          A "verack" packet shall be sent if the version packet was accepted. Once you have sent and received a verack messages with the remote node, send an addr message advertising up to 1000 peers of which you are aware, and one or more inv messages advertising all of the valid objects of which you are aware. 
        seq:
          - id: version
            type: s4
            doc: Identifies protocol version being used by the node. Should equal 3. Nodes should disconnect if the remote node's version is lower but continue with the connection if it is higher.
          - id: services
            type: services
            doc: bitfield of features to be enabled for this connection
          - id: timestamp
            type: s8
            doc: standard UNIX timestamp in seconds
          - id: addr_recv
            type: network_address
            doc: The network address of the node receiving this message (not including the time or stream number)
          - id: addr_from
            type: network_address
            doc: The network address of the node emitting this message (not including
              the time or stream number and the ip itself is ignored by the receiver)
          - id: nonce
            type: u8
            doc: Random nonce used to detect connections to self.
          - id: user_agent
            type: var_str
            doc: User Agent (0x00 if string is 0 bytes long). Sending nodes must not include a user_agent longer than 5000 bytes.
          - id: stream_numbers
            type: var_int_list
            doc: The stream numbers that the emitting node is interested in. Sending nodes must not include more than 160000 stream numbers.
        types:
          services:
            seq:
              - id: network
                type: b1
                doc: This is a normal network node.
              - id: ssl
                type: b1
                doc: This node supports SSL/TLS in the current connect (python < 2.7.9 only supports a SSL client, so in that case it would only have this on when the connection is a client). 
              - id: pow
                type: b1
                doc: This node may do PoW on behalf of some its peers (PoW offloading/delegating), but it doesn't have to. Clients may have to meet additional requirements (e.g. TLS authentication) (proposal)
              - id: reserved
                type: b5

      addr:
        doc: Provide information on known nodes of the network. Non-advertised nodes should be forgotten after typically 3 hours 
        seq:
          - id: addr_list
            type: network_address_list
            doc: Addresses of other nodes on the network.
      inv:
        doc: Allows a node to advertise its knowledge of one or more objects. 
        seq:
          - id: inventory_vectors_list
            type: inventory_vectors_list
            doc: Number of inventory entries
      getdata:
        doc: getdata is used in response to an inv message to retrieve the content of a specific object after filtering known elements. 
        seq:
          - id: inventory_vectors_list
            type: inventory_vectors_list
            doc: Number of inventory entries

      object:
        doc: An object is a message which is shared throughout a stream. It is the only message which propagates; all others are only between two nodes. Objects have a type, like 'msg', or 'broadcast'. To be a valid object, the Proof Of Work must be done. The maximum allowable length of an object (not to be confused with the objectPayload) is 218 bytes. 
        seq:
          - id: nonce
            type: u8
            doc: Random nonce used for the Proof Of Work
          - id: expires
            -orig-id:: expiresTime
            type: u8
            doc: The "end of life" time of this object (be aware, in version 2 of the protocol this was the generation time). Objects shall be shared with peers until its end-of-life time has been reached. The node should store the inventory vector of that object for some extra period of time to avoid reloading it from another node with a small time delay. The time may be no further than 28 days + 3 hours in the future.
          - id: type
            -orig-id:: objectType
            type: u4
            enum: object_type
            doc: Undefined values are reserved. Nodes should relay objects even if they use an undefined object type.
          - id: version
            type: var_int
            doc: The object\'s version. Note that msg objects won\'t contain a version until Sun, 16 Nov 2014 22:00:00 GMT.
          - id: stream_number
            type: var_int
            doc: The stream number in which this object may propagate
          - id: object_payload
            -orig-id:: objectPayload
            type:
              switch-on: type
              cases:
                'object_type::getpubkey': getpubkey
                'object_type::pubkey': pubkey
                'object_type::getpubkey': getpubkey
            doc: This field varies depending on the object type; see below.
        types:
          getpubkey:
            seq:
              - id: ripe
                type: ripemd
                doc:  The ripemd hash of the public key. This field is only included when the address version is <= 3.
              - id: tag
                type: tag
                doc: The tag derived from the address version, stream number, and ripe. This field is only included when the address version is >= 4.
          pubkey:
            seq:
              - id: pubkey
                type:
                  switch-on: _parent.version.value
                  cases:
                    #1: pubkey_v1
                    2: pubkey_v2
                    3: pubkey_v3
                    4: pubkey_v4
            types:
              pubkey_v2:
                doc: A version 2 pubkey. This is still in use and supported by current clients but new v2 addresses are not generated by clients.
                seq:
                  - id: behavior_bitfield
                    type: u4
                    doc:  A bitfield of optional behaviors and features that can be expected from the node receiving the message.
                  - id: public_key_pair
                    type: ecc_auth_enc_key_pair
              pubkey_v3:
                seq:
                  - id: pubkey_v2
                    type: pubkey_v2
                  - id: nonce_trials_per_byte
                    type: var_int
                    doc: Used to calculate the difficulty target of messages accepted by this node. The higher this value, the more difficult the Proof of Work must be before this individual will accept the message. This number is the average number of nonce trials a node will have to perform to meet the Proof of Work requirement. 1000 is the network minimum so any lower values will be automatically raised to 1000.
                  - id: extra_bytes
                    type: var_int
                    doc: Used to calculate the difficulty target of messages accepted by this node. The higher this value, the more difficult the Proof of Work must be before this individual will accept the message. This number is added to the data length to make sending small messages more difficult. 1000 is the network minimum so any lower values will be automatically raised to 1000.
                  - id: signature
                    type: ecc_signature
                    doc: The ECDSA signature which, as of protocol v3, covers the object header starting with the time, appended with the data described in this table down to the extra_bytes.
              pubkey_v4:
                doc: |
                  When version 4 pubkeys are created, most of the data in the pubkey is encrypted. This is done in such a way that only someone who has the Bitmessage address which corresponds to a pubkey can decrypt and use that pubkey. This prevents people from gathering pubkeys sent around the network and using the data from them to create messages to be used in spam or in flooding attacks.
                  In order to encrypt the pubkey data, a double SHA-512 hash is calculated from the address version number, stream number, and ripe hash of the Bitmessage address that the pubkey corresponds to. The first 32 bytes of this hash are used to create a public and private key pair with which to encrypt and decrypt the pubkey data, using the same algorithm as message encryption (see Encryption). The remaining 32 bytes of this hash are added to the unencrypted part of the pubkey and used as a tag, as above. This allows nodes to determine which pubkey to decrypt when they wish to send a message.
                  In PyBitmessage, the double hash of the address data is calculated using the python code below:
                  doubleHashOfAddressData = hashlib.sha512(hashlib.sha512(encodeVarint(addressVersionNumber) + encodeVarint(streamNumber) + hash).digest()).digest() 
                seq:
                  - id: tag
                    type: tag
                    doc: The tag, made up of bytes 32-64 of the double hash of the address data (see example python code below)
                  - id: encrypted
                    size-eos: true
                    process: decrypt
                    type: pubkey_v3
                    doc: Encrypted pubkey data.

          msg:
            doc: Used for person-to-person messages. Note that msg objects won't contain a version in the object header until Sun, 16 Nov 2014 22:00:00 GMT.
            seq:
              - id: encrypted
                type: encrypted_payload
                doc:  Encrypted data. See Unencrypted Message Data Format
            instances:
              message:
                io: encrypted.decrypted
                pos: 0
                type: unencrypted_message_data
            types:
              unencrypted_message_data:
                seq:
                  - id: address_version
                    type: var_int
                    doc: Sender\'s address version number. This is needed in order to calculate the sender\'s address to show in the UI, and also to allow for forwards compatible changes to the public-key data included below.
                  - id: stream
                    type: var_int
                    doc: Sender's stream number
                  - id: behavior_bitfield
                    type: bitfield_features
                    doc: A bitfield of optional behaviors and features that can be expected from the node with this pubkey included in this msg message (the sender's pubkey).
                  - id: public_key_pair
                    type: ecc_auth_enc_key_pair
                  - id: nonce_trials_per_byte
                    type: var_int
                    if: address_version >= 3
                    doc: Used to calculate the difficulty target of messages accepted by this node. The higher this value, the more difficult the Proof of Work must be before this individual will accept the message. This number is the average number of nonce trials a node will have to perform to meet the Proof of Work requirement. 1000 is the network minimum so any lower values will be automatically raised to 1000.
                  - id: extra_bytes
                    type: var_int
                    if: address_version >= 3
                    doc: Used to calculate the difficulty target of messages accepted by this node. The higher this value, the more difficult the Proof of Work must be before this individual will accept the message. This number is added to the data length to make sending small messages more difficult. 1000 is the network minimum so any lower values will be automatically raised to 1000.
                  - id: destination_ripe
                    type: ripemd
                    doc: The ripe hash of the public key of the receiver of the message
                  - id: encoding_
                    type: var_int
                    doc: Message Encoding type. See encoding
                  - id: message_length
                    type: var_int
                    doc: Message Length
                  - id: message
                    size: message_length
                    type: str
                    doc: The message.
                  - id: ack_length
                    type: var_int
                    doc: Length of the acknowledgement data
                  - id: ack_data
                    size: ack_length
                    type: message
                    doc: The acknowledgement data to be transmitted. This takes the form of a Bitmessage protocol message, like another msg message. The POW therein must already be completed.
                  - id: signature
                    type: ecc_signature
                    doc: The ECDSA signature which covers the object header starting with the time, appended with the data described in this table down to the ack_data.
                instances:
                  encoding:
                    value: encoding_.value
                    enum: message_encoding
                    doc: Message Encoding type
                types:
                  bitfield_features:
                    seq:
                      - id: reserved
                        type: b27
                      - id: onion_router
                        type: b1
                        doc: (Proposal) Node can be used to onion-route messages. In theory any node can onion route, but since it requires more resources, they may have the functionality disabled. This field will be used to indicate that the node is willing to do this. 
                      - id: forward_secrecy
                        type: b1
                        doc: (Proposal) Receiving node supports a forward secrecy encryption extension. The exact design is pending. 
                      - id: extended_encoding
                        type: b1
                        doc: Receiving node supports extended encoding.
                      - id: include_destination
                        type: b1
                        doc: |
                            (Proposal) Receiving node expects that the RIPE hash encoded in their address preceedes the encrypted message data of msg messages bound for them. NOTE: since hardly anyone implements this, this will be redesigned as simple recipient verification: https://github.com/Bitmessage/PyBitmessage/pull/808#issuecomment-170189856
                      - id: does_ack
                        type: b1
                        doc: If true, the receiving node does send acknowledgements (rather than dropping them). 

                enums:
                  message_encoding:
                    0: ignore #  Any data with this number may be ignored. The sending node might simply be sharing its public key with you. 
                    1: trivial #  UTF-8. No 'Subject' or 'Body' sections. Useful for simple strings of data, like URIs or magnet links. '
                    2: simple # UTF-8. Uses 'Subject' and 'Body' sections. No MIME is used. messageToTransmit = 'Subject:' + subject + '\n' + 'Body:' + message
                    3: extended # See Extended encoding

          broadcast:
            doc: |
              Users who are subscribed to the sending address will see the message appear in their inbox. Broadcasts are version 4 or 5.
              Pubkey objects and v5 broadcast objects are encrypted the same way: The data encoded in the sender's Bitmessage address is hashed twice. The first 32 bytes of the resulting hash constitutes the "private" encryption key and the last 32 bytes constitute a tag so that anyone listening can easily decide if this particular message is interesting. The sender calculates the public key from the private key and then encrypts the object with this public key. Thus anyone who knows the Bitmessage address of the sender of a broadcast or pubkey object can decrypt it.
              The version of broadcast objects was previously 2 or 3 but was changed to 4 or 5 for protocol v3. Having a broadcast version of 5 indicates that a tag is used which, in turn, is used when the sender's address version is >=4. 
            seq:
              - id: tag
                type: tag
                doc:  The tag. This field is new and only included when the broadcast version is >= 5. Changed in protocol v3
              - id: encrypted
                type: encrypted_payload
                doc: Encrypted broadcast data. The keys are derived as described in the paragraph above.
            types:
              broadcast_plaintext:
                seq:
                  - id: broadcast_version
                    type: var_int
                    doc:  The version number of this broadcast protocol message which is equal to 2 or 3. This is included here so that it can be signed. This is no longer included in protocol v3
                  - id: address_version
                    type: var_int
                    doc: The sender's address version
                  - id: stream_number
                    type: var_int
                    doc: The sender's stream number
                  - id: behavior_bitfield
                    type: u4
                    doc:  A bitfield of optional behaviors and features that can be expected from the owner of this pubkey.
                  - id: public_key_pair
                    type: ecc_auth_enc_key_pair
                  - id: nonce_trials_per_byte
                    type: var_int
                    doc: Used to calculate the difficulty target of messages accepted by this node. The higher this value, the more difficult the Proof of Work must be before this individual will accept the message. This number is the average number of nonce trials a node will have to perform to meet the Proof of Work requirement. 1000 is the network minimum so any lower values will be automatically raised to 1000. This field is new and is only included when the address_version >= 3.
                  - id: extra_bytes
                    type: var_int
                    doc: Used to calculate the difficulty target of messages accepted by this node. The higher this value, the more difficult the Proof of Work must be before this individual will accept the message. This number is added to the data length to make sending small messages more difficult. 1000 is the network minimum so any lower values will be automatically raised to 1000. This field is new and is only included when the address_version >= 3.
                  - id: encoding
                    type: var_int
                    doc: The encoding type of the message
                  - id: message_length
                    type: var_int
                    doc: The message length in bytes
                  - id: message
                    size: message_length
                    doc: The message
                  - id: signature
                    type: ecc_signature
                    doc: The signature which did cover the unencrypted data from the broadcast version down through the message. In protocol v3, it covers the unencrypted object header starting with the time, all appended with the decrypted data.
        enums:
          object_type:
            0: getpubkey
            1: pubkey
            2: msg
            3: broadcast
