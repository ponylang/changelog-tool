prefix ?= /usr/local

all: bin/changelog-tool

deps:
	stable fetch

bin/changelog-tool: deps
	mkdir -p bin
	ponyc -o bin

install: bin/changelog-tool
	mkdir -p $(prefix)/bin
	cp $^ $(prefix)/bin

test: deps
	cd tests && ponyc -d && ./tests && rm tests

clean:
	rm -rf bin

.PHONY: all install
