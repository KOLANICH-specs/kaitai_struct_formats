def disasm(code):
	for i, op in enumerate(code):
		if op.opcode_or_macro:
			print(f"0x{i:x}\t{op.opcode.name.upper()}\t({op.opcode.value:02})  \t0x{op.z:x},0x{op.w:x},0x{op.x:x},0x{op.y:x}")
		else:
			print(op.macro, (op.z, op.w, op.x, op.y))

def printTramLine(l, mode):
	for sym in l.symbols:
		print("{}: 0x3{:02x}/0x2{:02x} ({}), offset 0x{:x}".format(mode, sym.address, sym.address, "?", sym.value))

def printTramTable(t):
	for el in t.data:
		print("Lookup-table block:?, size:0x{:x}".format(el.size))
		printTramLine(el.read, "Read")
		printTramLine(el.write, "Write")

def printTrams(trams):
	printTramTable(trams.tables)
	printTramTable(trams.delay_lines) 

def printGPRs(gprs):
	for el in gprs.inputs:
		print("in IN: 0x{:x}, OUT: 0x{:x}".format(el.input + gprs.gpr_base, el.output + gprs.gpr_base))

	for el in gprs.dynamic:
		print("GPR Dynamic:  0x{:x}".format(el.start + gprs.gpr_base))

	for el in gprs.static:
		print("GPR Static:  0x{:x}, Value:0x{:x}".format(el.start + gprs.gpr_base, el.value))

	for el in gprs.control:
		print("GPR Control: 0x{:x}({}), value:0x{:x}, Min:0x{:x}, Max:0x{:x}".format(el.start + gprs.gpr_base, el.name, el.value, el.min, el.max))

	for el in gprs.constant:
		print("GPR Constant: 0x{:x}({}), Value:0x{:h}}".format(el.start + gprs.gpr_base, el.name, el.value))

def printHeader(hdr):
	printGPRs(hdr.gprs)
	printTrams(hdr.trams)
