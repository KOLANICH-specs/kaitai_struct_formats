meta:
  id: eink_rkf
  title: Rockchip Waveform blob
  file-extension: rkf
  license: Unlicense
  endian: le
  xref:
    wikidata:
      - Q189897
      - Q1187307
  encoding: utf-8

doc: |
  E-ink screen waveforms in the format used by Rockchip chips.
  Though the files have "rkf" extensions, they are usually baked into linux kernel module specific for the device, which is itself baked into the kernel image (since most of firmwares are Android-based, you may need unmkbootimg tool). You can extract them from kernels using the added function (not a ready-to use script because different vendors have different to store firmwares, you will have to customize it).

  import base64
  import hashlib
  import mmap
  import struct
  from pathlib import Path

  import sh
  from fsutilz import MMap


  def carveRkf(m: mmap.mmap, sig=b"rkf:"):
    sigOfs = m.find(sig)
    if sigOfs:
      firstByte = sigOfs - 8
      size = struct.unpack("<I", m[firstByte : firstByte + 4])[0]
      return m[firstByte : firstByte + size + 4]  # size too, but is not counted in size


  def saveRkfFile(sourceImage=Path("./kernel"), targetDir=Path(".")) -> None:
    with MMap(sourceImage) as mm:
      carved = carveRkf(mm)
      if carved:
        fileName = base64.b64encode(hashlib.md5(carved).digest()).decode("ascii")
        (targetDir / (fileName + ".rkf")).write_bytes(carved)
        return fileName


  unmkbootimg = sh.Command("./unmkbootimg")


  def extractRkfFileFromBootSh(dirWithBootSh: Path, rkfsDirPath: Path):
    Path("./kernel").unlink()
    unmkbootimg(i=str(dirWithBootSh / "boot.img"))
    return saveRkfFile(Path("./kernel"), rkfsDirPath)


  def bulkExtractRkfFiles(files):
    for f in files:
      f = Path(".") / "simple" / f
      print(f, "->", extractRkfFileFromBootSh(f, Path("./rkfs")))


  if __name__ == "__main__":
    bulkExtractRkfFiles(files=[])


  It is very rare situation if they are available as separate files. Fut sometimes they are:
    https://github.com/onyx-intl/rk2906_tools/blob/master/OemDataPacket/waveform.rkf
    https://cloud-api.yandex.net/v1/disk/public/resources/download?public_key=https://yadi.sk/d/8qTREsnnmC58G
    https://4pda.ru/forum/dl/post/5291434/waveform.zip
    https://4pda.ru/forum/dl/post/5296523/waveforms.zip

seq:
  - id: blob_size
    type: u4
  - id: rest_of_blob
    type: rest_of_blob
    size: blob_size

types:
  rest_of_blob:
    seq:
      - id: unkn2
        type: u4
      - id: header
        type: header
      - id: records1
        type: record1
        repeat: expr
        repeat-expr: 5
      - id: records2
        type: record2
        repeat: expr
        repeat-expr: 5
      - id: records3
        type: record3
      - id: records4
        type: record4
  header:
    seq:
      - id: signature
        contents: ["rkf:"]
      - id: version
        size: 7
        type: str
      - id: date_str
        type: strz
      - id: unkn
        type: u1
      - id: vendor
        type: strz
        size: 16
      - id: product
        size: 32
        type: strz
      - id: unkn1
        type: u4
      - id: unkn2
        type: u4
      - id: unkn3
        size: 60
  record1:
    seq:
      - id: unkn0
        type: u4
      - id: unkn2
        type: u4
      - id: unkn3
        type: u4
      - id: unkn4
        type: u4
      - id: unkn5
        size: 3*16
  record2:
    seq:
      - id: unkn0
        type: u4
        repeat: expr
        repeat-expr: 14
      - id: unkn1
        size: 200
        doc: zeros
  record3:
    seq:
      - id: unkn0
        size: 16
        repeat: expr
        repeat-expr: 64
  record4:
    seq:
      - id: unkn
        size: 48
