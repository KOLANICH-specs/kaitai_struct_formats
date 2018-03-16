meta:
  id: android_parcel
  title: Android Parcel
  application:
    - Android
    - Android Binder
  xref:
    wikidata: Q17121613
  license: Apache-2.0
  encoding: utf-16
  endian: le # in fact machine endianess, but most of machines are LE

doc: |
  Container for a message (data and object references) that canbe sent through an IBinder.  A Parcel can contain both flattened datathat will be unflattened on the other side of the IPC (using the variousmethods here for writing specific types, or the general{@link Parcelable} interface), and references to live {@link IBinder}objects that will result in the other side receiving a proxy IBinderconnected with the original IBinder in the Parcel.
    Parcel is **not** a general-purpose serialization mechanism.  This class (and the corresponding{@link Parcelable} API for placing arbitrary objects into a Parcel) isdesigned as a high-performance IPC transport.  As such, it is notappropriate to place any Parcel data in to persistent storage: changesin the underlying implementation of any of the data in the Parcel canrender older data unreadable.
  The bulk of the Parcel API revolves around reading and writing dataof various types.  There are six major classes of such functions available.

  Primitives
  ----------
  The most basic data functions are for writing and reading primitivedata types: {@link #writeByte}, {@link #readByte}, {@link #writeDouble},{@link #readDouble}, {@link #writeFloat}, {@link #readFloat}, {@link #writeInt},{@link #readInt}, {@link #writeLong}, {@link #readLong},{@link #writeString}, {@link #readString}.  Most otherdata operations are built on top of these.  The given data is written andread using the endianess of the host CPU.
  # Primitive Arrays
  There are a variety of methods for reading and writing raw arraysof primitive objects, which generally result in writing a 4-byte lengthfollowed by the primitive data items.  The methods for reading can eitherread the data into an existing array, or create and return a new array.
  # Parcelables
  The Parcelable protocol provides an extremely efficient (butlow-level) protocol for objects to write and read themselves from Parcels.You can use the direct methods writeParcelable(Parcelable, int) and readParcelable(ClassLoader) or writeParcelableArray and readParcelableArray(ClassLoader) to write or read.  Thesemethods write both the class type and its data to the Parcel, allowingthat class to be reconstructed from the appropriate class loader whenlater reading.
  There are also some methods that provide a more efficient way to workwith Parcelables: writeTyped*.  These methodsdo not write the class information of the original object: instead, thecaller of the read function must know what type to expect and pass in theappropriate Parcelable.Creator Parcelable.Creator instead toproperly construct the new object and read its data.  (To more efficientwrite and read a single Parcelable object that is not null, you can directlycall .writeToParcel and createFromParcel yourself.)
  # Bundles
  A special type-safe container, called Bundle, is availablefor key/value maps of heterogeneous values.  This has many optimizationsfor improved performance when reading and writing data, and its type-safeAPI avoids difficult to debug type errors when finally marshalling thedata contents into a Parcel.  The methods to use are writeBundle(Bundle), readBundle(), and readBundle(ClassLoader).
  # Active Objects
  An unusual feature of Parcel is the ability to read and write activeobjects.  For these objects the actual contents of the object is notwritten, rather a special token referencing the object is written.  Whenreading the object back from the Parcel, you do not get a new instance ofthe object, but rather a handle that operates on the exact same object thatwas originally written.  There are two forms of active objects available.
  Binder objects are a core facility of Android's general cross-processcommunication system.  The {@link IBinder} interface describes an abstractprotocol with a Binder object.  Any such interface can be written in toa Parcel, and upon reading you will receive either the original objectimplementing that interface or a special proxy implementationthat communicates calls back to the original object.  The methods to use are{@link #writeStrongBinder(IBinder)},{@link #writeStrongInterface(IInterface)}, {@link #readStrongBinder()},{@link #writeBinderArray(IBinder[])}, {@link #readBinderArray(IBinder[])},{@link #createBinderArray()},{@link #writeBinderList(List)}, {@link #readBinderList(List)},{@link #createBinderArrayList()}.</p>
  *<p>FileDescriptor objects, representing raw Linux file descriptor identifiers,can be written and {@link ParcelFileDescriptor} objects returned to operateon the original file descriptor.  The returned file descriptor is a dupof the original file descriptor: the object and fd is different, butoperating on the same underlying file stream, with the same position, etc.The methods to use are writeFileDescriptor(FileDescriptor), readFileDescriptor().
  #Untyped Containers
  A final class of methods are for writing and reading standard Javacontainers of arbitrary types.  These all revolve around the writeValue(Object) and readValue(ClassLoader) methods which define the types of objects allowed.  The container methods are write*(Object[]), read*(ClassLoader).
doc-ref:
  - https://github.com/android/platform_frameworks_base/blob/master/core/java/android/os/Parcel.java
  - https://developer.android.com/reference/android/os/Parcel
enums:
  exception:
    "-1": security
    "-2": bad_parcelable
    "-3": illegal_argument
    "-4": null_pointer
    "-5": illegal_state
    "-6": network_main_thread
    "-7": unsupported_operation
    "-8": service_specific
    "-9": parcelable
    "-128": has_reply_header #special
    "-129": transaction_failed
  type:
    "-1": "null"
    0: string
    1: integer
    2: map
    3: bundle
    4: parcelable
    5: short
    6: long
    7: float
    8: double
    9: boolean
    10: char_sequence #CHARSEQUENCE
    11: val_list
    12: sparse_int_array #SPARSEARRAY
    13: byte_array #BYTEARRAY
    14: string_array #STRINGARRAY
    15: ibinder
    16: parcelable_array #PARCELABLEARRAY
    17: object_array #OBJECTARRAY
    18: int_array #INTARRAY
    19: long_array #LONGARRAY
    20: byte
    21: serializable
    22: sparse_boolean_array #SPARSEBOOLEANARRAY
    23: boolean_array #BOOLEANARRAY
    24: char_sequence_array #CHARSEQUENCEARRAY
    25: persistable_bundle #PERSISTABLEBUNDLE
    26: size
    27: sizef
    28: double_array #DOUBLEARRAY
types:
  sizef:
    seq:
      - id: width
        type: f4
      - id: height
        type: f4
  size:
    seq:
      - id: width
        type: s4
      - id: height
        type: s4
  parcel_str: #uncertain
    seq:
      - id: length
        type: s4
      - id: value
        type: str
        size: length
    instances:
      is_null:
        value: length == -1
  byte_array:
    seq:
      - id: length
        type: s4
      - id: data
        size: length
    instances:
      is_null:
        value: length == -1
  int_array:
    seq:
      - id: length
        type: s4
      - id: data
        type: u4
        repeat: expr
        repeat-expr: length
    instances:
      is_null:
        value: length == -1

  long_array:
    seq:
      - id: length
        type: s4
      - id: data
        type: u8
        repeat: expr
        repeat-expr: length
    instances:
      is_null:
        value: length == -1
  double_array:
    seq:
      - id: length
        type: s4
      - id: data
        type: f8
        repeat: expr
        repeat-expr: length
    instances:
      is_null:
        value: length == -1

  string_array:
    seq:
      - id: length
        type: s4
      - id: data
        type: parcel_str
        repeat: expr
        repeat-expr: length
    instances:
      is_null:
        value: length == -1

  # file_descriptor_array:
    # seq:
      # - id: length
        # type: s4
      # - id: data
        # type: file_descriptor
        # repeat: expr
        # repeat-expr: len
    # instances:
      # is_null:
        # value: length == -1

  sparse_int_array:
    seq:
      - id: length
        type: s4
      - id: data
        type: record
        repeat: expr
        repeat-expr: length
    types:
      record:
        seq:
          - id: key
            type: u4
          - id: value
            type: u4

  sparse_boolean_array:
    seq:
      - id: length
        type: s4
      - id: data
        type: record
        repeat: expr
        repeat-expr: length
    types:
      record:
        seq:
          - id: key
            type: u4
          - id: value_
            type: u4
        instances:
          value:
            value: not value_ == 0
  map:
    seq:
      - id: length
        type: s4
      - id: data
        type: record
        repeat: expr
        repeat-expr: length
    types:
      record:
        seq:
          - id: key
            type: value
          - id: value
            type: value

  array:
    seq:
      - id: length
        type: s4
      - id: data
        type: value
        repeat: expr
        repeat-expr: length
    instances:
      is_null:
        value: length == -1
  # char_sequence_array:
    # seq:
      # - id: length
        # type: s4
      # - id: data
        # type: char_sequence
        # repeat: expr
        # repeat-expr: len
    # instances:
      # is_null:
        # value: length == -1
  serializable:
    seq:
      - id: class_name
        type: parcel_str
      - id: blob
        type: byte_array

  # parcelable:
    # seq:
      # - id: class_name
        # type: parcel_str
      # - id: blob
        # type:
          # switch-on: class_name
          # cases: #dynamic, from runtime
  # parcelable_array:
    # seq:
      # - id: length
        # type: s4
      # - id: data
        # type: parcelable
        # repeat: expr
        # repeat-expr: len
    # instances:
      # is_null:
        # value: length == -1

  # bundle:
    # seq:
      # - id: length
        # type: u4
      # - id: parcelable
        # type: parcelable
  value:
    -orig-id: readValue
    seq:
      - id: type
        type: s4
        enum: type
      - id: value
        type:
          switch-on: type
          cases:
            type::integer: s4
            type::short: s4
            type::boolean: s4
            type::long: s8
            type::float: f4
            type::double: f8
            type::byte: u1
            #type::boolean_array: boolean_array
            type::boolean_array: int_array
            type::string_array: string_array
            type::byte_array: byte_array
            type::int_array: int_array
            type::long_array: long_array
            type::double_array: double_array

            type::sparse_int_array: sparse_int_array
            type::sparse_boolean_array: sparse_boolean_array
            type::map: map
            type::list: array
            type::object_array: array
            #type::char_sequence_array: char_sequence_array
            type::size: size
            type::sizef: sizef
            type::serializable: serializable
            type::string: parcel_str
            #type::parcelable: parcelable
            #type::parcelable_array: parcelable_array
            #type::char_sequence: char_sequence #TextUtils.writeToParcel
            #type::ibinder: strong_binder #nativeWriteStrongBinder
            #type::bundle: bundle # loading will be deferred
            #type::persistable_bundle: persistable_bundle
