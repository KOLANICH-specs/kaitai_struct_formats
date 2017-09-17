meta:
  id: lingvo_lsd
  title: ABBYY Lingvo new (≥ x5) format
  endian: le
  encoding: utf8be
  file-extension: lsd
  application: ABBYY Lingvo
  license: MIT
doc-ref: https://github.com/nongeneric/lsd2dsl/tree/master/dictlsd
seq:
  - id: header
    type: header
  - id: name
    type: ustr1
  - id: first_heading
    type: ustr1
  - id: last_heading
    type: ustr1
  - id: capitals
    type: ustr4r
  - id: icon_len
    type: u2
  - id: icon
    size: icon_len
  - id: checksum
    type: u4
  - id: pages_end
    type: u4
  - id: overlay_data
    type: u4
types:
  symbols:
    seq:
      - id: len
        type: u4
      - id: bits_per_symbol
        type: u1
      - id: data
        type: symbol
        repeat: expr
        repeat-expr: len
    types:
      symbol:
        seq:
          - id: symbol
            size: b1
            repeat: expr
            repeat-expr: _parent.bits_per_symbol
  ustr1:
    seq:
      - id: len
        type: u1
      - id: data
        type: str
        size: len
  ustr4r:
    seq:
      - id: len
        type: u4
        process: reverse32
      - id: data
        type: str
        size: len
  ustr4:
    seq:
      - id: len
        type: u4
      - id: data
        type: str
        size: len
  ustr8:
    seq:
      - id: len
        type: u8
      - id: data
        type: str
        size: len

  len_table:
    seq:
      - id: count
        type: u4
      - id: bits_per_len
        type: u1
      - id: symidxs
        type: symidx_record
        repeat: expr
        repeat-expr: count
    instances:
      idx_bit_size:
        value: floor(log2(count))+1 # count of bits needed for a number, the same as ceil(log2(count+1)) and propfind
    types:
      symidx_record:
        seq:
          - id: symidx
            size: _parent.idx_bit_size/8
          - id: len
            size: _parent.bits_per_len/8
  version:
    seq:
      - id: revision
        type: b12
      - id: minor
        type: b4
      - id: major
        type: u2

  header:
    seq:
      - id: signature
        -orig-id: magic
        contents: "LingVo"
      - id: unkn0
        size: 2
      - id: version
        type: version
      - id: unkn1
        type: u4
      - id: checksum
        type: u4
      - id: count
        -orig-id: entriesCount
        type: u4
      - id: annotation_offset
        -orig-id: annotationOffset
        type: u4
      - id: dictionary_encoder_offset
        -orig-id: dictionaryEncoderOffset
        type: u4
      - id: articles_offset
        -orig-id: articlesOffset
        type: u4
      - id: pages_offset
        -orig-id: pagesOffset
        type: u4
      - id: unkn2
        type: u4
      - id: unkn3
        type: u2
      - id: unkn4
        type: u2
      - id: source_language
        type: u2
        enum: language_code
      - id: target_language
        type: u2
        enum: language_code
  overlay_heading:
    seq:
      - id: name
        type: ustr8
      - id: offset
        type: u4
      - id: unk2
        type: u4
      - id: inflated_size
        type: u4
      - id: stream_size
        type: u4
  user_dictionary:
    seq:
      - id: prefix
        type: ustr4
      - id: article_symbols
        type: symbols
      - id: heading_symbols
        type: symbols
      - id: lt_articles
        type: len_table
      - id: lt_headings
        type: len_table
      - id: lt_prefix_lengths
        type: len_table
      - id: unkn
        type: u4
      - id: lt_postfix_lengths
        type: len_table
      - id: huffman_numbers
        -orig-id: _huffman1Number, _huffman2Number
        type: u4
        repeat: expr
        repeat-expr: 2
enums:
  language_code:
    1555: abazin
    1556: abkhaz
    1557: adyghe
    1078: afrikaans
    1559: agul
    1052: albanian
    1545: altaic
    1025: arabic
    5121: arabic_algeria
    15361: arabic_bahrain
    3073: arabic_egypt
    2049: arabic_iraq
    11265: arabic_jordan
    13313: arabic_kuwait
    12289: arabic_lebanon
    4097: arabic_libya
    6145: arabic_morocco
    8193: arabic_oman
    16385: arabic_qatar
    1025: arabic_saudi_arabia
    10241: arabic_syria
    7169: arabic_tunisia
    14337: arabic_uae
    9217: arabic_yemen
    1067: armenian
    1067: armenian_eastern
    33835: armenian_grabar
    32811: armenian_western
    1101: assamese
    1558: awar
    1560: aymara
    2092: azeri_cyrillic
    1068: azeri_latin
    1561: bashkir
    1069: basque
    1059: belarusian
    1562: bemba
    1093: bengali
    1563: blackfoot
    1536: breton
    1564: bugotu
    1026: bulgarian
    1109: burmese
    1565: buryat
    1059: byelorussian
    1027: catalan
    1566: chamorro
    1544: chechen
    1028: chinese
    3076: chinese_hong_kong
    5124: chinese_macau
    2052: chinese_prc
    4100: chinese_singapore
    1028: chinese_taiwan
    1074: chuana
    1567: chukcha
    1568: chuvash
    1569: corsican
    1546: crimean_tatar
    1050: croatian
    1570: crow
    1029: czech
    1632: dakota
    1030: danish
    1571: dargin
    1571: dargwa
    1572: dungan
    1043: dutch
    2067: dutch_belgian
    1043: dutch_standard
    1033: english
    3081: english_australian
    10249: english_belize
    4105: english_canadian
    9225: english_caribbean
    6153: english_ireland
    8201: english_jamaica
    35849: english_law
    33801: english_medical
    5129: english_new_zealand
    13321: english_philippines
    34825: english_proper_names
    7177: english_south_africa
    11273: english_trinidad
    2057: english_united_kingdom
    1033: english_united_states
    12297: english_zimbabwe
    1573: eskimo_cyrillic
    1581: eskimo_latin
    1537: esperanto
    1061: estonian
    1574: even
    1575: evenki
    1080: faeroese
    1080: faroese
    1065: farsi
    1538: fijian
    1035: finnish
    2067: flemish
    1036: french
    2060: french_belgian
    3084: french_canadian
    5132: french_luxembourg
    6156: french_monaco
    33804: french_proper_names
    1036: french_standard
    4108: french_swiss
    1122: frisian
    1576: frisian_legacy
    1577: friulian
    2108: gaelic
    1084: gaelic_scottish
    1552: gaelic_legacy
    1578: gagauz
    1110: galician
    1579: galician_legacy
    1580: ganda
    1079: georgian
    1031: german
    3079: german_austrian
    34823: german_law
    5127: german_liechtenstein
    4103: german_luxembourg
    36871: german_medical
    32775: german_new_spelling
    35847: german_new_spelling_law
    37895: german_new_spelling_medical
    39943: german_new_spelling_proper_names
    38919: german_proper_names
    1031: german_standard
    2055: german_swiss
    1032: greek
    32776: greek_kathareusa
    1581: greenlandic
    1140: guarani
    1582: guarani_legacy
    1095: gujarati
    1583: hani
    1128: hausa
    1652: hausa_legacy
    1141: hawaiian
    1539: hawaiian_legacy
    1037: hebrew
    1081: hindi
    1038: hungarian
    1039: icelandic
    1584: ido
    1057: indonesian
    1585: ingush
    1586: interlingua
    2108: irish
    1552: irish_legacy
    1040: italian
    33808: italian_proper_names
    1040: italian_standard
    2064: italian_swiss
    1041: japanese
    1548: kabardian
    1640: kachin
    1587: kalmyk
    1099: kannada
    1589: karachay_balkar
    1588: karakalpak
    1120: kashmiri
    2144: kashmiri_india
    1590: kasub
    1591: kawa
    1087: kazakh
    1592: khakas
    1593: khanty
    1107: khmer
    1594: kikuyu
    1595: kirgiz
    1597: komi_permian
    1596: komi_zyryan
    1598: kongo
    1111: konkani
    1042: korean
    2066: korean_johab
    1599: koryak
    1600: kpelle
    1601: kumyk
    1602: kurdish
    1603: kurdish_cyrillic
    1604: lak
    1108: lao
    1083: lappish
    1142: latin
    1540: latin_legacy
    1062: latvian
    1655: latvian_gothic
    1605: lezgin
    1063: lithuanian
    2087: lithuanian_classic
    1606: luba
    1071: macedonian
    1607: malagasy
    1086: malay
    2110: malay_brunei_darussalam
    1086: malay_malaysian
    1100: malayalam
    1608: malinke
    1082: maltese
    1112: manipuri
    1609: mansi
    1153: maori
    1102: marathi
    1610: mari
    1611: maya
    1612: miao
    1613: minankabaw
    1614: mohawk
    1104: mongol
    1615: mordvin
    1616: nahuatl
    1617: nanai
    1618: nenets
    1121: nepali
    2145: nepali_india
    1619: nivkh
    1620: nogay
    1044: norwegian
    1044: norwegian_bokmal
    2068: norwegian_nynorsk
    1621: nyanja
    1622: occidental
    1623: ojibway
    32777: old_english
    32780: old_french
    33799: old_german
    32784: old_italian
    1657: old_slavonic
    32778: old_spanish
    1096: oriya
    1547: ossetic
    1145: papiamento
    1624: papiamento_legacy
    1625: pidgin_english
    1654: pinyin
    1045: polish
    1046: portuguese
    1046: portuguese_brazilian
    2070: portuguese_standard
    1541: provencal
    1094: punjabi
    1131: quechua
    1131: quechua_bolivia
    2155: quechua_ecuador
    3179: quechua_peru
    1626: quechua_legacy
    1047: rhaeto_romanic
    1048: romanian
    2072: romanian_moldavia
    1627: romany
    1628: ruanda
    1629: rundi
    1049: russian
    2073: russian_moldavia
    34841: russian_old_ortho
    32793: russian_old_spelling
    33817: russian_proper_names
    1083: saami
    1542: samoan
    1103: sanskrit
    1630: selkup
    3098: serbian_cyrillic
    2074: serbian_latin
    1631: shona
    1113: sindhi
    1632: sioux
    1051: slovak
    1060: slovenian
    1143: somali
    1633: somali_legacy
    1070: sorbian
    1634: sotho
    1034: spanish
    11274: spanish_argentina
    16394: spanish_bolivia
    13322: spanish_chile
    9226: spanish_colombia
    5130: spanish_costa_rica
    7178: spanish_dominican_republic
    12298: spanish_ecuador
    17418: spanish_el_salvador
    4106: spanish_guatemala
    18442: spanish_honduras
    2058: spanish_mexican
    3082: spanish_modern_sort
    19466: spanish_nicaragua
    6154: spanish_panama
    15370: spanish_paraguay
    10250: spanish_peru
    33802: spanish_proper_names
    20490: spanish_puerto_rico
    1034: spanish_traditional_sort
    14346: spanish_uruguay
    8202: spanish_venezuela
    1635: sunda
    1072: sutu
    1089: swahili
    1636: swazi
    1053: swedish
    2077: swedish_finland
    1637: tabassaran
    1553: tagalog
    1639: tahitian
    1064: tajik
    1638: tajik_legacy
    1097: tamil
    1092: tatar
    1098: telugu
    1054: thai
    1105: tibet
    1640: tinpo
    1641: tongan
    1073: tsonga
    1074: tswana
    1642: tun
    1055: turkish
    1090: turkmen
    1656: turkmen_latin
    1643: turkmen_legacy
    1644: tuvin
    1645: udmurt
    1646: uighur
    1646: uighur_cyrillic
    1647: uighur_latin
    1058: ukrainian
    1653: universal
    2080: urdu_india
    1056: urdu_pakistan
    1554: user
    2115: uzbek_cyrillic
    1091: uzbek_latin
    1075: venda
    1066: vietnamese
    1648: visayan
    1106: welsh
    1543: welsh_legacy
    1070: wend
    1160: wolof
    1649: wolof_legacy
    1076: xhosa
    1157: yakut
    1650: yakut_legacy
    1085: yiddish
    1651: zapotec
    1077: zulu
