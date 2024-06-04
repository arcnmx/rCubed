DIR_ROOT := .
DIR_FONTS := $(DIR_ROOT)/fonts
DIR_SRC := $(DIR_ROOT)/src
DIR_LIBS := $(DIR_ROOT)/libs
DIR_BUILD := $(DIR_ROOT)/bin

BIN_FONTS := $(DIR_BUILD)/fonts/Embedded-Fonts.swc
BIN_LIB := $(DIR_BUILD)/R3Lib.swc
BIN_DEBUG := $(DIR_BUILD)/develop/R3Air.swf
BIN_RELEASE := $(DIR_BUILD)/release/R3Air.swf
BIN_PREPARE := $(DIR_BUILD)/release/R3.airi
BIN_PACKAGE := $(DIR_BUILD)/release/R3.air
BIN_PACKAGE_NATIVE := $(DIR_BUILD)/release/R3
SRCS := src/Main.as $(shell find $(DIR_SRC) -type f -name "*.as")
SRCS_FONTS := $(shell find $(DIR_FONTS) -type f -name "*.as") \
	$(shell find $(DIR_FONTS) -type f -name "*.ttf") \
	$(shell find $(DIR_FONTS) -type f -name "*.ttc")
SRCS_ASSETS := \
	$(shell find $(DIR_SRC) -type f -name "*.swf") \
	$(shell find $(DIR_LIBS) -type f -name "*.swc") \
	$(BIN_FONTS)
SRCS_DATA := $(wildcard $(DIR_ROOT)/data/icons/*.png) \
	$(DIR_ROOT)/changelog.txt
SRC_CERT := certs/air-make.p12
CONFIGS_FONTS := $(DIR_FONTS)/config.xml
CONFIGS_LIB := $(DIR_ROOT)/config.xml $(DIR_ROOT)/config-lib.xml
CONFIGS_APP := $(DIR_ROOT)/config.xml $(DIR_ROOT)/config-app.xml
CONFIGS_APP_DEBUG := $(CONFIGS_APP) $(DIR_ROOT)/config-debug.xml
CONFIGS_APP_RELEASE := $(CONFIGS_APP) $(DIR_ROOT)/config-release.xml
DESC_APP := $(DIR_ROOT)/application.xml
DESC_APP_MOBILE := $(DIR_ROOT)/application-mobile.xml
DATA_ICONS := $(wildcard $(DIR_ROOT)/data/icons/*.png)

BRAND_NAME_LONG := FlashFlashRevolution
BRAND_NAME_SHORT := FFR
ROOT_URL := www.flashflashrevolution.com
VERSION := 2.0
CERT_PASSWORD := ffr
# when building offline `make package TSA=none`
TSA := http://timestamp.digicert.com

TIMESTAMP := $(shell date "+%Y-%m-%dT%H:%M:%S")
#SCORE_SAVE_SALT ?=
FLAGS_COMMON := \
	-define 'R3::VERSION' '"$(VERSION)"' \
	-define 'R3::BRAND_NAME_LONG' '"$(BRAND_NAME_LONG)"' \
	-define 'R3::BRAND_NAME_SHORT' '"$(BRAND_NAME_SHORT)"' \
	-define 'R3::ROOT_URL' '"$(ROOT_URL)"' \
	-define 'R3::VERSION_PREFIX' '""' \
	-define 'R3::HASH_STRING' '"hash:$(SCORE_SAVE_SALT)"' \
	-define 'CONFIG::timeStamp' '"$(TIMESTAMP)"'
FLAGS_LIB := $(FLAGS_COMMON) \
	-define 'R3::VERSION_PREFIX' '"MAIN_LIB"' \
	-define 'CONFIG::debug' 'false' \
	-define 'CONFIG::release' 'false' \
	-define 'CONFIG::updater' 'false'
FLAGS_APP := $(FLAGS_COMMON)
FLAGS_APP_RELEASE := $(FLAGS_APP) \
	-define 'CONFIG::debug' 'false' \
	-define 'CONFIG::release' 'true' \
	-define 'R3::VERSION_SUFFIX' '""'
FLAGS_APP_DEBUG := $(FLAGS_APP) \
	-define 'CONFIG::debug' 'true' \
	-define 'CONFIG::release' 'false' \
	-define 'R3::VERSION_SUFFIX' '"D"'
#FLAGS_APP_DEBUG := $(FLAGS_APP_DEBUG) -advanced-telemetry

all: debug release lib

debug: $(BIN_DEBUG)
release: $(BIN_RELEASE)
lib: $(BIN_LIB)
fonts: $(BIN_FONTS)
package: $(BIN_PACKAGE_NATIVE)

clean:
	rm -rf "$(DIR_BUILD)"

$(BIN_FONTS): $(CONFIGS_FONTS) $(SRCS_FONTS)
	acompc \
		$(patsubst %,-load-config+=%,$(CONFIGS_FONTS)) \
		-output $@

$(BIN_LIB): $(SRCS) $(CONFIGS_LIB)
	acompc \
		$(FLAGS_LIB) \
		$(patsubst %,-load-config+=%,$(CONFIGS_LIB)) \
		-output $@

$(BIN_DEBUG): $(SRCS) $(SRCS_ASSETS) $(CONFIGS_APP_DEBUG) $(BIN_FONTS)
	amxmlc \
		$(FLAGS_APP_DEBUG) \
		$(patsubst %,-load-config+=%,$(CONFIGS_APP_DEBUG)) \
		-output $@ \
		$<

$(BIN_RELEASE): $(SRCS) $(SRCS_ASSETS) $(CONFIGS_APP_RELEASE) $(BIN_FONTS)
	amxmlc \
		$(FLAGS_APP_RELEASE) \
		$(patsubst %,-load-config+=%,$(CONFIGS_APP_RELEASE)) \
		-output $@ \
		$<

$(BIN_PREPARE): $(BIN_RELEASE) $(DESC_APP) $(SRCS_DATA)
	adt -prepare $@ $(DESC_APP) -C $(dir $<) $(notdir $<) -C $(DIR_ROOT) $(patsubst $(DIR_ROOT)/%,%,$(SRCS_DATA))

$(BIN_PACKAGE): $(BIN_PREPARE) $(SRC_CERT)
	adt -package -storetype pkcs12 -keystore $(SRC_CERT) -storepass $(CERT_PASSWORD) -tsa $(TSA) -target air $@ $<

$(BIN_PACKAGE_NATIVE): $(BIN_PACKAGE) $(SRC_CERT)
	adt -package -target bundle $@ $<
	chmod +x $@/R3

$(SRC_CERT):
	adt -certificate -cn "Air Signing Certificate" 2048-RSA $@ $(CERT_PASSWORD)

.PHONY: all clean debug release package lib fonts
