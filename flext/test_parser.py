from parglare import Grammar, Parser, GLRParser
import re
def test():
	g=Grammar.from_file("./FlexT.pglr", re_flags=re.MULTILINE, ignore_case=True)
	#g=Grammar.from_file("./FlexT.pglr", debug_parse=True, debug_colors=True, re_flags=re.MULTILINE, ignore_case=True)
	#p=Parser(g, build_tree=True)
	p=GLRParser(g, build_tree=True)
	#p.parse_file("./General Data Types/Auxiliary/GUID.rfi")
	print(p.parse_file("./General Data Types/Auxiliary/testGUID.rfi").tree_str())
test()