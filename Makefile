prefix ?= /usr/local

all: bin/changelog-tool

deps:
	stable fetch

bin/changelog-tool: deps
	mkdir -p bin
	stable env ponyc -o bin

install:
	mkdir -p $(prefix)/bin
	cp bin/changelog-tool $(prefix)/bin

test: deps
	cd tests && \
		stable env ponyc -d && ./tests && \
		rm tests && cd ..

clean:
	rm -rf bin

.PHONY: all install
