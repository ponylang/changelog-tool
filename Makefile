prefix ?= /usr/local
config ?= release
arch ?=
static ?= false
linker ?=

APPLICATION := changelog-tool
COMPILE_WITH := corral run -- ponyc
FETCH_DEPS_WITH := corral fetch
CLEAN_DEPS_WITH := corral clean

BUILD_DIR ?= build/$(config)
SRC_DIR := $(APPLICATION)
binary := $(BUILD_DIR)/$(APPLICATION)

ifdef config
	ifeq (,$(filter $(config),debug release))
		$(error Unknown configuration "$(config)")
	endif
endif

ifeq ($(config),release)
	PONYC = $(COMPILE_WITH)
else
	PONYC = $(COMPILE_WITH) --debug
endif

ifneq ($(arch),)
  PONYC += --cpu $(arch)
endif

ifdef static
  ifeq (,$(filter $(static),true false))
    $(error "static must be true or false)
  endif
endif

ifeq ($(static),true)
  PONYC += --static
endif

ifneq ($(linker),)
  PONYC += --link-ldcmd=$(linker)
endif

# Default to version from `VERSION` file but allowing overridding on the
# make command line like:
# make version="nightly-19710702"
# overridden version *should not* contain spaces or characters that aren't
# legal in filesystem path names
ifndef version
  version := $(shell cat VERSION)
  ifneq ($(wildcard .git),)
    sha := $(shell git rev-parse --short HEAD)
    tag := $(version)-$(sha)
  else
    tag := $(version)
  endif
else
  foo := $(shell touch VERSION)
  tag := $(version)
endif

SOURCE_FILES := $(shell find $(SRC_DIR) -name \*.pony)
VERSION := "$(tag) [$(config)]"
GEN_FILES_IN := $(shell find $(SRC_DIR) -name \*.pony.in)
GEN_FILES = $(patsubst %.pony.in, %.pony, $(GEN_FILES_IN))

%.pony: %.pony.in VERSION
	sed s/%%VERSION%%/$(version)/ $< > $@

$(binary): $(GEN_FILES) $(SOURCE_FILES) | $(BUILD_DIR)
	$(FETCH_DEPS_WITH)
	$(PONYC) -o $(BUILD_DIR) $(SRC_DIR)

install: $(binary)
	@echo "install"
	mkdir -p $(DESTDIR)$(prefix)/bin
	cp $^ $(DESTDIR)$(prefix)/bin

test: $(binary)
	$(FETCH_DEPS_WITH)
	cd tests && \
		$(COMPILE_WITH) -d -V1 && ./tests && \
		rm tests && \
		sh verification.sh && \
		cd ..

clean:
	$(CLEAN_DEPS_WITH)
	rm -rf $(BUILD_DIR) $(GEN_FILES)

all: test $(binary)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

.PHONY: all clean install test




