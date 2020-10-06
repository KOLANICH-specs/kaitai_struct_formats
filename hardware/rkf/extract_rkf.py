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


def extractRkfFileFromBootSh(imgPath: Path, rkfsDirPath: Path):
	Path("./kernel").unlink()
	unmkbootimg(i=str(imgPath))
	return saveRkfFile(Path("./kernel"), rkfsDirPath)


def bulkExtractRkfFiles(files):
	for f in files:
		print(f, "->", extractRkfFileFromBootSh(f, Path("./rkfs")))


if __name__ == "__main__":
	bulkExtractRkfFiles(files=[])
