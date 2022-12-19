all:
	nuitka3 --follow-imports --output-dir=./out/ -o ./out/fgg fgg

clean:
	rm -rf ./bin/fgg
	rm -rf ./out

flushcache:
	rm -rf ./cache/*

flushphotos:
	rm -rf ./photo/*
	rm -rf ./photos/*

gallery:
	./bin/fgg
