prefix ?= /usr/local

all: bin/changelog-tool

deps:
	stable fetch

bin/changelog-tool: deps
	mkdir -p bin
	stable env ponyc -V1 -o bin

install:
	mkdir -p $(prefix)/bin
	cp bin/changelog-tool $(prefix)/bin

test: deps
	cd tests && \
		stable env ponyc -d -V1 && ./tests && \
		rm tests && \
		sh verification.sh && \
		cd ..

clean:
	rm -rf bin

.PHONY: all install
