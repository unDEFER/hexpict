debug: src/main.d
	dub build

release: src/main.d
	dub build --build=release

docs: details/ru/A.md
	make -C doc/ru/
