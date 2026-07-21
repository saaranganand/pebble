FLAGS := -define:YAML_STATIC=true

# build libyaml.a locally (it was missing on macos)
YAML_DIR := libs/odin-yaml
YAML_SRC := $(YAML_DIR)/shared/libyaml

UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(UNAME_S),Darwin)
	YAML_OS := macos
else
	YAML_OS := linux
endif

ifeq ($(UNAME_M),x86_64)
	YAML_ARCH := x86_64
else
	YAML_ARCH := aarch64
endif

YAML_LIB := $(YAML_DIR)/lib/$(YAML_OS)/$(YAML_ARCH)/libyaml.a

run: $(YAML_LIB)
	odin run src/ $(FLAGS)

build: $(YAML_LIB)
	odin build src/ $(FLAGS)

# put static lib
$(YAML_LIB):
	cd $(YAML_SRC) && ./bootstrap && ./configure
	$(MAKE) -C $(YAML_SRC)
	mkdir -p $(dir $@)
	cp $(YAML_SRC)/src/.libs/libyaml.a $@
