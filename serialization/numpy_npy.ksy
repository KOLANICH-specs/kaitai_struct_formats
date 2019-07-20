meta:
  id: numpy_npy
  title: A Simple File Format for NumPy Arrays
  application: numpy
  file-extension: npy
  license: Unlicense
  endian: le
  xref:
    wikidata: Q197520
  imports:
    - /common/ndarray_descriptor
    - /common/ndarray
  ks-opaque-types: true
doc: |
  Serialization format used by numpy.
  To parse it properly you need a parser for a text format, unofficially nicknamed by me as PON (using the analogy to JSON). That format is a Python literal expression and it is assummed (in the threat model that there is no vulnrs in python itself like CVE-2021-3177) that it can be securely parsed using `ast.literal_eval`. See the docs for `header` field for more inffo on serialization layout and `parsed_header` instance for an easy way to get a secure parser impl for your language.

  An lot of bad mistakes have been made when designing this format:
    * it uses dicts in python syntax:
      * in order to parse the array one has to have a parser for python language syntax. This cripples interoperability: noone wants to create a parser for python syntax or bring whole python to just parse a `numpy` array.
      * it is tempting to `exec` these dicts, which could have been a security issue. It is especially tempting taking in account the fact that `literal_eval` was not available in the standard lib at the time of introduction of this format.
      * they had to use `ast.parse` and manual walking of the tree in order to avoid the issu that in past. Fortunately now in python there is `ast.literal_eval`, which evaluates expressions of primitive types without RCE.
    The schema of the dicts is fixed, the values in the dicts are integers, the better solution would be to put these numbers as standardized variable-length integers or use something like JSON or bencode.
    * it relies on pickle for serializing non-primitive objects, which is a remote code execution. If one needs `pickle`, he is already fucked up, and pickle is definitily capable to serialize numpy arrays, so there is no benefits to embed `pickle` into this format. The better solution is to state that serializing anything except arrays of literal types is out of scope of the format, and that if one needs to serialize something with the help of `pickle`, then he should `pickle` the whole `numpy.ndarray`.

  Testing:
    import numpy as np
    import numpy_npy
    from io import BytesIO
    b = BytesIO()
    a = np.array(range(6), dtype=np.int8)
    np.save(b, a, allow_pickle=False)
    p = numpy_npy.NumpyNpy.from_bytes(b.getvalue())

  Warning: This spec cannot currently be used to parse structured arrays and arrays of fixed-length strings , such as "S10". They are currently out of scope. Behavior when the file being parsed contains them is undefined. Because of limitations of KS no errors will be emitted, just the stream will be parsed incorrectly with unpredictable effect and probably even a vulnerability.

doc-ref:
  - https://github.com/numpy/numpy/blob/067cb067cb17a20422e51da908920a4fbb3ab851/doc/neps/nep-0001-npy-format.rst
  - https://docs.scipy.org/doc/numpy/reference/generated/numpy.lib.format.html
  - https://github.com/numpy/numpy/blob/master/numpy/lib/format.py

seq:
  - id: signature
    contents: [0x93, NUMPY]
  - id: version
    type: version
    doc: the version of the file format is not tied to the version of the numpy package.
  - id: header_size
    -orig-id: HEADER_LEN
    type:
      switch-on: version.major >= 2
      cases:
        true: u4
        false: u2
  - id: header
    type: strz
    encoding: ascii
    size: header_size
    doc: |
      Contains a Python literal expression of a dictionary. DO NOT `exec` it! If you use python, use `ast.literal_eval`. If you use another language, see `parsed_header` for the hacky solution of transforming PON into JSON, which can then be securely parsed.
      The dictionary contains three keys:
          "descr" : dtype.descr
              An object that can be passed as an argument to the numpy.dtype() constructor to create the array's dtype.
          "fortran_order" : bool
              Whether the array data is Fortran-contiguous or not.
              Since Fortran-contiguous arrays are a common form of non-C-contiguity, we allow them to be written directly to disk for efficiency.
          "shape" : tuple of int
              The shape of the array.
      For repeatability and readability, this dictionary is formatted using pprint.pformat() so the keys are in alphabetic order. A writer SHOULD implement this if possible. A reader MUST NOT depend on this.
  - id: data_initial
    size-eos: true
    type: ndarray(parsed_header.descriptor)
    doc: |
      Following the header comes the array data. If the dtype contains Python objects (i.e. dtype.hasobject is True), then the data is a Python pickle of the array. Otherwise the data is the contiguous (either C- or Fortran-, depending on fortran_order) bytes of the array. Consumers can figure out the number of bytes by multiplying the number of elements given by the shape (noting that shape=() means there is 1 element) by dtype.itemsize.
instances:
  data:
    value: data_initial.data
  dims_m_2:
    value: parsed_header.dimensions.as<u8> - 2

  parsed_header:
    -affected-by: 314
    value: real_parsed_header.as<fake_parsed_header>

  real_parsed_header:
    -affected-by: 314
    pos: 0
    type: numpy_parsed_header(header)
    doc: |
      # save it as numpy_parsed_header.py
      import json
      import re

      from kaitaistruct import KaitaiStruct

      braceFixingRx = re.compile(r",\s*([\]\}])")


      def literalEvalSurrogate(s: str):
        """A surrogate of `ast.literal_eval` as a solution for the langs not having python syntax parser"""
        s = s.strip()
        s = s.replace("(", "[").replace(")", "]")
        s = braceFixingRx.subn(lambda x: x.group(1), s)[0]
        s = s.replace("True", "true").replace("False", "false")
        s = s.replace("'", '"')
        return json.loads(s)


      class NumpyParsedHeader(KaitaiStruct):
        __slots__ = ("item_type", "fortran_order", "shape", "dimensions")

        def __init__(self, header_str: str, _io, _parent=None, _root=None):
          self._parent = _parent
          header = literalEvalSurrogate(header_str)
          self.item_type = header["descr"]
          if not isinstance(self.item_type, str):
            raise NotImplementedError(repr(self.item_type))
          if self.item_type[0] == "S" and (len(self.item_type) != 2 or self.item_type[1] != "1"):
            raise NotImplementedError(repr(self.item_type))
          self.fortran_order = header["fortran_order"]
          self.shape = header["shape"]
          self.dimensions = len(self.shape)

types:
  fake_parsed_header:
    -affected-by: 314
    instances:
      shape:
        value: '[0, 0]'
      item_type:
        value: '"<I"'

  version:
    seq:
      - id: major
        type: u1
      - id: minor
        type: u1
