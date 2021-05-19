meta:
  id: mediatek_epo
  title: MediaTek Extended Prediction Orbit
  license: MIT
  endian: le

doc-ref: https://github.com/DashSight/MediaTek-GPS-Utils

doc: |
  Ephemeris data in Mediatek EPO format
  CRC8 can be used in this format.

  tmp files are not parsed.
  at the moment all the records are of type 2
  
  EPO_GPS_3_1.DAT 12 records
  EPO_GPS_3_10.DAT 12
  EPO_GPS_3_2.DAT 12
  EPO_GPS_3_3.DAT 12
  EPO_GPS_3_4.DAT 12
  EPO_GPS_3_5.DAT 12
  EPO_GPS_3_6.DAT 12
  EPO_GPS_3_7.DAT 12
  EPO_GPS_3_8.DAT 12
  EPO_GPS_3_9.DAT 12
  EPO_GR_3_1.DAT 21 records
  EPO_GR_3_10.DAT 21
  EPO_GR_3_2.DAT 21
  EPO_GR_3_3.DAT 21
  EPO_GR_3_4.DAT 21
  EPO_GR_3_5.DAT 21
  EPO_GR_3_6.DAT 21
  EPO_GR_3_7.DAT 21
  EPO_GR_3_8.DAT 21
  EPO_GR_3_9.DAT 21
  QGPS.DAT 1 record
  QG_R.DAT Not parsed

seq:
  - id: records
    type: record
    repeat: eos

instances:
  gps_offset_seconds:
    value: 315964786

types:
  gps_hour:
    params:
      - id: gps_hour
        type: u4
    instances:
      epoch_time:
        value: gps_hour * 3600 + _root.gps_offset_seconds
      gps_week:
        value: gps_hour / 168  # hours per week
      hour_in_week:
        value: gps_hour % 168
      sec_in_week:
        value: gps_hour * 3600

  record: # 75
    seq:
      - id: header
        type: header
      - id: unkn
        size: epo_size - sizeof<header>
    instances:
      header1:
        pos: 0
        size: 3
      header2:
        pos: 60
        size: 3
      header3:
        pos: 72
        size: 3
      is_type_1:
        value: header1 == header2
      is_type_2:
        value: header1 == header3
      type:
        value: "(is_type_1 ? 1 : (is_type_2 ? 2 : 0))"
      epo_size:
        -orig-id: EPO_SET_SIZE
        value: "(is_type_1 ? 1920 : (is_type_2 ? 2304 : 0))"
    types:
      header:
        seq:
          - id: raw_lo
            type: u2
          - id: raw_hi
            type: u1
        instances:
          starts:
            pos: 0
            type: gps_hour(raw_hi << 16 | raw_lo)
          ends:
            pos: 0
            type: gps_hour(starts.gps_hour + 6)
