meta:
  id: openal_hrir
  title: OpenAL Head-Related Impulse Response
  application:
    - OpenAL
  file-extension: mhr
  xref:
    wikidata:
      - Q1432854
      - Q910775
  license: LGPL-2.1
  endian: le
doc: |
  The format to store head-related impulse responses to have binaural spatial sound in the apps using OpenAL.
  The examples can be found by the link: https://github.com/kcat/openal-soft/tree/master/hrtf
doc-ref: https://github.com/kcat/openal-soft/blob/master/docs/hrtf.txt

seq:
  - id: signature
    -orig-id: magic
    contents: MinPHR02
  - id: sample_rate
    type: u4
    doc: The sample rate the data set is designed for (OpenAL Soft will not use it if the output device's playback rate doesn't match).
  - id: sample_type
    type: u1
    enum: sample_type
  - id: channel_type
    type: u1
    enum: channel_type

  - id: hrir_size
    type: u1
    doc: |
      Specifies how many sample points (or finite impulse response filter coefficients) make up each HRIR.
      Can be 8 to 128 in steps of 8.
  - id: fields_count
    -orig-id: fdCount
    type: u1
    doc: |
      The number of fields used by the data set.
      Can be 1 to 16.
  - id: fields
    type: field(_index)
    repeat: expr
    repeat-expr: fields_count

  - id: hrirs
    type: hrir(_index)
    repeat: expr
    repeat-expr: hrir_count

  - id: delays
    type: delay
    repeat: expr
    repeat-expr: hrir_count
    doc: |
      The propagation delay (in samples) for each HRIR a signal must wait before being convolved with the corresponding minimum-phase HRIR filter.
      Each can be 0 to 63.
instances:
  channel_count:
    value: "(channel_type == channel_type::mono ? 1 : (channel_type == channel_type::stereo ? 2 : 0))"
  hrir_count:
    value: fields[fields_count-1].sum
types:
  s3:
    seq:
      - id: sign
        type: b1
      - id: ext_mod
        type: b23
    instances:
      value:
        value: (sign?ext_mod-(1<<23):ext_mod)
  field:
    params:
      - id: index
        type: u1
    seq:
      - id: distance
        type: u2
        -unit: mm
        doc: |
          The distance in millimeters for that field.
          Can be 50mm to 2500mm
      - id: elevation_count
        -orig-id: evCount
        type: u1
        doc: Can be 5 to 128.
      - id: elevations_descriptors
        type: elevation_descr(_index)
        repeat: expr
        repeat-expr: elevation_count
    instances:
      angle_step:
        value: 90. / elevation_count
        -unit: degC
        doc: Angle in degrees (since there is no pi in KS).
      sum:
        value: ((index>0?_parent.fields[index-1].sum:0)+elevations_descriptors[elevation_count-1].sum).as<u4> # cast works around a bug in KSC
    types:
      elevation_descr:
        params:
          - id: index
            type: u1
        seq:
          - id: azimuth_count
            type: u1
            -orig-id: azCount
            doc: |
              Number of azimuths (and thus HRIRs) that make up each elevation.
              Azimuths start clockwise from the front, constructing a full circle. Mono HRTFs use the same HRIRs for both ears by reversing the azimuth calculation (ie. left = angle, right = 360-angle).
              Each can be 1 to 128.
              Elevations start at the bottom (-90 degrees), and increment upwards.
        instances:
          sum:
            value: ((index>0?_parent.elevations_descriptors[index-1].sum:0)+azimuth_count).as<u4> # cast works around a bug in KSC
          theta:
            -unit: degC
            value: -90. + _parent.angle_step * index
          angle_step:
            value: 360. / azimuth_count
            -unit: degC
            doc: Angle in degrees (since there is no π constant in KS).
  hrir:
    params:
      - id: idx
        type: u4
    seq:
      - id: coefficients
        type:
          switch-on: _root.channel_type
          cases:
            channel_type::mono: mono
            channel_type::stereo: stereo
        doc: |
          Ear coefficients. The HRIRs must be minimum-phase. This allows the use of a smaller filter length, reducing computation. For reference, the default data set uses a 32-point filter while even the smallest data set provided by MIT used a 128-sample filter (a 4x reduction by applying minimum-phase reconstruction).
        repeat: expr
        repeat-expr: _root.hrir_size
    instances:
      delay:
        value: _root.delays[idx]
    types:
      point:
        seq:
          - id: value
            type:
              switch-on: _root.sample_type
              cases:
                sample_type::s2: s2
                sample_type::s3: s3
      mono:
        seq:
          - id: left
            type: point
        instances:
          right:
            value: left
      stereo:
        seq:
          - id: left
            type: point
          - id: right
            type: point
  delay:
    seq:
      - id: channels
        type:
          switch-on: _root.channel_type
          cases:
            channel_type::mono: mono
            channel_type::stereo: stereo
    types:
      mono:
        seq:
          - id: left
            type: u1
        instances:
          right:
            value: left
      stereo:
        seq:
          - id: left
            type: u1
          - id: right
            type: u1

enums:
  sample_type:
    0: s2
    1: s3
  channel_type:
    0: mono
    1: stereo
