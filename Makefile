AIR ?= 1
ADT := adt
MXMLC ?= mxmlc
COMPC ?= compc
ifeq ($(AIR),1)
	AMXMLC ?= amxmlc
	ACOMPC ?= acompc
else
	AMXMLC := $(MXMLC)
	ACOMPC := $(COMPC)
endif

DIR_ROOT := .
DIR_FONTS := $(DIR_ROOT)/fonts
DIR_SRC := $(DIR_ROOT)/src
DIR_LIBS := $(DIR_ROOT)/libs
DIR_BUILD := $(DIR_ROOT)/bin

BIN_FONTS := $(DIR_BUILD)/fonts/Embedded-Fonts.swc
BIN_LIB := $(DIR_BUILD)/R3Lib.swc
BIN_DEBUG := $(DIR_BUILD)/develop/R3Air.swf
BIN_RELEASE := $(DIR_BUILD)/release/R3Air.swf
BIN_HYBRID := $(DIR_BUILD)/release/air.swf
BIN_PREPARE := $(DIR_BUILD)/release/R3.airi
BIN_PACKAGE := $(DIR_BUILD)/release/R3.air
BIN_PACKAGE_NATIVE := $(DIR_BUILD)/release/R3
SRCS := src/Main.as $(shell find $(DIR_SRC) -type f -name "*.as")
SRCS_FONTS := $(shell find $(DIR_FONTS) -type f -name "*.as") \
	$(shell find $(DIR_FONTS) -type f -name "*.ttf") \
	$(shell find $(DIR_FONTS) -type f -name "*.ttc")
SRCS_ASSETS := \
	$(wildcard $(DIR_SRC)/game/noteskins/*.swf) \
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
CONFIGS_APP_HYBRID := $(CONFIGS_APP) $(DIR_ROOT)/config-hybrid.xml
DESC_APP := $(DIR_ROOT)/application.xml
DESC_APP_MOBILE := $(DIR_ROOT)/application-mobile.xml
DATA_ICONS := $(wildcard $(DIR_ROOT)/data/icons/*.png)

TIMESTAMP := $(shell date "+%Y-%m-%dT%H:%M:%S")
VERSION := 2.0
CERT_PASSWORD ?= ffr
# when building offline `make package TSA=none`
TSA ?= http://timestamp.digicert.com

FLAGS_COMMON := \
	-define+='CONFIG::timeStamp','"$(TIMESTAMP)"'
EXTRAMXFLAGS ?=
EXTRACOMPCFLAGS ?=

TARGET_PLAYER ?=
ifneq ($(TARGET_PLAYER),)
	FLAGS_COMMON := $(FLAGS_COMMON) \
		-target-player $(TARGET_PLAYER)
endif

export SCORE_SAVE_SALT ?=
FLAGS_COMMON := $(FLAGS_COMMON) \
	+env.SCORE_SAVE_SALT='$(SCORE_SAVE_SALT)'

ifneq ($(SCORE_SAVE_SALT),)
	FLAGS_COMMON := $(FLAGS_COMMON) \
		-define+='R3::HASH_STRING','"hash:$(SCORE_SAVE_SALT)"'
endif
ifneq ($(BRAND_NAME_SHORT),)
	FLAGS_COMMON := $(FLAGS_COMMON) \
		-define+='R3::BRAND_NAME_SHORT','"$(BRAND_NAME_SHORT)"' \
		-define+='R3::BRAND_NAME_LONG','"$(BRAND_NAME_LONG)"'
endif

all: debug release lib

debug: $(BIN_DEBUG)
release: $(BIN_RELEASE)
hybrid: $(BIN_HYBRID)
lib: $(BIN_LIB)
fonts: $(BIN_FONTS)
package: $(BIN_PACKAGE_NATIVE)

clean:
	@if [ -d "$(DIR_BUILD)/release/R3" ]; then chmod -R +w "$(DIR_BUILD)/release/R3"; fi
	rm -rf "$(DIR_BUILD)"

$(BIN_FONTS): $(CONFIGS_FONTS) $(SRCS_FONTS)
	$(ACOMPC) \
		$(patsubst %,-load-config+=%,$(CONFIGS_FONTS)) \
		$(EXTRACOMPCFLAGS) \
		-output $@

$(BIN_LIB): $(SRCS) $(CONFIGS_LIB)
	$(ACOMPC) \
		$(patsubst %,-load-config+=%,$(CONFIGS_LIB)) \
		$(FLAGS_COMMON) $(EXTRAMXFLAGS) \
		-output $@

$(BIN_DEBUG): $(SRCS) $(SRCS_ASSETS) $(CONFIGS_APP_DEBUG)
	$(AMXMLC) \
		$(patsubst %,-load-config+=%,$(CONFIGS_APP_DEBUG)) \
		$(FLAGS_COMMON) $(EXTRAMXFLAGS) \
		-output $@ \
		$<

$(BIN_RELEASE): $(SRCS) $(SRCS_ASSETS) $(CONFIGS_APP_RELEASE)
	$(AMXMLC) \
		$(patsubst %,-load-config+=%,$(CONFIGS_APP_RELEASE)) \
		$(FLAGS_COMMON) $(EXTRAMXFLAGS) \
		-output $@ \
		$<

$(BIN_HYBRID): $(SRCS) $(SRCS_ASSETS) $(CONFIGS_APP_HYBRID)
	$(AMXMLC) \
		$(patsubst %,-load-config+=%,$(CONFIGS_APP_HYBRID)) \
		$(FLAGS_COMMON) $(EXTRAMXFLAGS) \
		-output $@ \
		$<

$(BIN_PREPARE): $(BIN_RELEASE) $(DESC_APP) $(SRCS_DATA)
	$(ADT) -prepare $@ $(DESC_APP) -C $(dir $<) $(notdir $<) -C $(DIR_ROOT) $(patsubst $(DIR_ROOT)/%,%,$(SRCS_DATA))

$(BIN_PACKAGE): $(BIN_PREPARE) $(SRC_CERT)
	$(ADT) -package -storetype pkcs12 -keystore $(SRC_CERT) -storepass $(CERT_PASSWORD) -tsa $(TSA) -target air $@ $<

$(BIN_PACKAGE_NATIVE): $(BIN_PACKAGE) $(SRC_CERT)
	$(ADT) -package -target bundle $@ $<
	@chmod -R +w $@/R3
	@chmod +x $@/R3

$(SRC_CERT):
	$(ADT) -certificate -cn "Air Signing Certificate" 2048-RSA $@ $(CERT_PASSWORD)

.PHONY: all clean debug release hybrid package lib fonts
