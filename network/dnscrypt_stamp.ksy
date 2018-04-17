meta:
  id: dnscrypt_stamp
  title: DNSCrypt-proxy unserialized `stamp`
  license: Unlicense
  application: DNSCrypt-proxy
  endian: le
doc: |
  DNSCrypt stamps. sdns:// followed by base64-serialized binary string. IMHO not the best idea: not human-readable. This ksy decodes the binary string.
doc-ref: https://github.com/jedisct1/dnscrypt-proxy/wiki/stamps
seq:
  - id: protocol
    type: u1
    enum: protocol
  - id: props
    type: props
  - id: addr
    type: pas_str
    doc: is the IP address, as a string, with a port number if the server is not accessible over the standard port for the protocol (443). IPv6 strings must be included in square brackets: `[fe80::6d6d:f72c:3ad:60b8]`.
  - id: data
    type:
      switch-on: protocol
      cases:
        #'protocol::plain': plain 
        'protocol::crypt': crypt
        'protocol::over_https': over_https
        'protocol::over_tls': over_tls
enums:
  protocol:
    0x00: plain
    0x01: crypt
    0x02: over_https
    0x03: over_tls
types:
  props:
    seq:
      - id: reserved0
        type: b5
      - id: censorship
        type: b1
      - id: keeps_logs
        type: b1
      - id: dnssec
        type: b1
      - id: reserved1
        type: b46
  pas_str:
    seq:
      - id: len
        type: u1
      - id: str
        size: addr_len
        type: str
  blob:
    seq:
      - id: len
        type: u1
      - id: str
        size: addr_len
  blob_list:
    seq:
      - id: blobs
        type: subblob
        repeat: until
        repeat-until: not _.is_followed
    types:
      subblob:
        seq:
          - id: is_followed
            type: b1
          - id: len
            type: b7
          - id: addr
            size: len
  crypt:
    seq:
      - id: public_key
        -orig-id: pk
        type: blob
      - id: provider_name
        type: pas_str
  over_https:
    seq:
      - id: over_tls
        type: over_tls
      - id: path
        type: pas_str
        doc: is the absolute URI path, such as `/.well-known/dns-query`.
  over_tls:
    seq:
      - id: hashes
        -orig-id: hash0
        type: blob_list
      - id: hostname
        type: pas_str
        doc: is the SHA256 digest of one of the TBS certificate found in the validation chain, typically the certificate used to sign the resolver's certificate.