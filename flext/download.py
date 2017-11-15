#!/usr/bin/env python3
import encodings
import json  # don't optionally replace with ujson, serializes differently!
import os
from collections import OrderedDict
from pathlib import Path

import bs4
import dateutil.parser
import ratelimit  # https://github.com/tomasbasham/ratelimit
from tqdm import tqdm

try:
	import httpx
except ImportError:
	import requests as httpx

base = "http://geos0.icc.ru"
catalog = base + "/scripts/WWWBinV.dll/Cat"


def getCharset(soup: bs4.BeautifulSoup, default: str = "utf-8") -> str:
	el = soup.select_one("head > meta[http-equiv=Content-Type]")
	if el:
		for part in el["content"].split(";"):
			if "=" in part:
				part = part.split("=")
				if len(part) > 1 and part[0].lower == "charset":
					return part[1]
	return default


def bin2soup(bin: (bytes, bytearray)) -> bs4.BeautifulSoup:
	enc = "windows-1251"
	str = bin.decode(encoding=enc, errors="replace")
	soup = bs4.BeautifulSoup(str, "html5lib")
	enc1 = getCharset(soup, "windows-1251")
	if enc != enc1:
		str = bin.decode(encoding=enc1)
		soup = bs4.BeautifulSoup(str, "html5lib")
	return soup


def buildIndex(targetDir: Path) -> OrderedDict:
	catalogCacheFile = targetDir / "Cat"
	if not catalogCacheFile.is_file():
		catalogTextEncoded = httpx.get(catalog).content
		catalogCacheFile.write_bytes(catalogTextEncoded)
	else:
		print("Index source is already present. Delete " + str(catalogCacheFile) + " to regenerate")
		catalogTextEncoded = catalogCacheFile.read_bytes()

	parsed = bin2soup(catalogTextEncoded)
	table = parsed.select_one("table")
	rows = table.select("tr")
	res = {}
	header = [el.text.strip().lower() for el in rows[0].select("td")]

	rows = rows[1:]
	rowsRes = OrderedDict()
	for row in rows:
		rowRes = OrderedDict(zip(header, [el.text.strip() for el in row.select("td")]))
		# rowRes["date"]=dateutil.parser.parse(rowRes["date"])
		rowRes["uri"] = base + row.select_one("a[href]")["href"]

		cat = rowsRes
		if rowRes["class"] not in cat:
			cat[rowRes["class"]] = {}
		cat = cat[rowRes["class"]]
		if rowRes["status"] not in cat:
			cat[rowRes["status"]] = {}
		cat = cat[rowRes["status"]]

		cat[rowRes["file"]] = rowRes
	return rowsRes


def writeSource(soup: bs4.BeautifulSoup, fileName: Path) -> None:
	meta = {}
	for el in soup.select("head > meta"):
		if "name" in el.attrs:
			meta[el.attrs["name"]] = el.attrs["content"]
	metaStr = soup.select_one("font").text
	source = soup.select_one("pre").text

	source = "% " + metaStr + "\n" + "% " + json.dumps(meta) + "\n\n" + source

	with fileName.open("wt", encoding="utf-8") as f:
		f.write(source)


@ratelimit.rate_limited(period=2)
def downloadFormat(uri: str, path: Path) -> None:
	req = httpx.get(uri)
	soup = bin2soup(req.content)
	writeSource(soup, path)


def downloadFormats(index: OrderedDict, targetDir: Path) -> None:
	for clsName, cls in tqdm(index.items(), desc="Classes"):
		clsPath = targetDir / clsName.replace(".", "").replace("/", "").replace("\\", "")
		for statusName, status in tqdm(cls.items(), desc="Statuses in " + clsName):
			statusPath = clsPath / statusName.replace(".", "").replace("/", "").replace("\\", "")
			os.makedirs(str(statusPath), mode=0o771, exist_ok=True)
			for formatName, formatDescr in tqdm(status.items(), desc="Formats in " + statusName):
				formatPath = statusPath / formatName.replace("/", "").replace("\\", "")
				tqdm.write("downloading : " + formatDescr["uri"] + " -> " + str(formatPath))
				downloadFormat(formatDescr["uri"], formatPath)


def main() -> None:
	targetDir = Path(".")
	indexCacheFile = targetDir / "cat.json"
	if not indexCacheFile.is_file():
		with indexCacheFile.open("wt", encoding="utf-8") as f:
			index = buildIndex(targetDir)
			json.dump(index, f, indent="\t")
	else:
		print("Index is already present. Delete " + str(indexCacheFile) + " to regenerate")
		with indexCacheFile.open("rt", encoding="utf-8") as f:
			index = json.load(f)
	downloadFormats(index, targetDir)


if __name__ == "__main__":
	main()
