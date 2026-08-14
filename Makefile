
.RECIPEPREFIX = >
VPATH = intermediary_data/infinite_volume:raw_data

SRC_DIR = src

BETAS = 920 940 960 980 100 102 104 108 110 114 120 128 136 146
OPS = plaq sym
TIMES := $(shell seq 2.5 0.1 6.7)
GSQ   := $(shell seq 1.8 0.1 10.4)

define EXT_VOL
OUT_DIR := intermediary_data/infinite_volume
script := ${SRC_DIR}/extrapolate_infinite_volume.py
INPUTS := $(wildcard raw_data/*b$(1).txt)
output := b{beta}_t{time}_{op}.json.gz
TARGET := $(subst {op},$(2),$(subst {time},$(3),$(subst {beta},$(1),$(output))))
OUTPUTS += $(TARGET)
$$(TARGET): $$(INPUTS)
> python $$(script) $$^ --output_filename ${OUT_DIR}/$$@ \
                              --operator $(2)             \
                              --time $(3)
endef


all:
$(foreach OP,$(OPS),$(foreach TIME,$(TIMES),$(foreach BETA,$(BETAS),$(eval $(call EXT_VOL,$(BETA),$(OP),$(TIME))))))

all: $(OUTPUTS)
