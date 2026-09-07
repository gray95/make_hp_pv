
.RECIPEPREFIX = >
VPATH = intermediary_data/infinite_volume:intermediary_data/beta_interpolation:intermediary_data/continuum_extrapolation:intermediary_data/fixed_point:raw_data:assets

SRC_DIR = src

BETAS = 920 940 960 980 100 102 104 108 110 114 120 128 136 146
OPS   = plaq sym
TIMES       := $(shell seq 2.5 0.1 6.7)
GSQ         := $(shell seq 1.8 0.1 10.4)
FIX_GSQ     := $(shell seq 4.5 0.1 8.5)

TMINS := $(shell seq 3 0.1 4)
TMAXS := 5.0 5.5 6.0

PLOT_STYLE = styles/paperdraft.mplstyle

define FIX_PT
FIX_IN_DIR  := intermediary_data/continuum_extrapolation
FIX_SCRIPT  := ${SRC_DIR}/fit_fixed_point.py
FIX_INPUTS  := $(foreach G,$(FIX_GSQ),$(FIX_IN_DIR)/$(1)_gsquared$(G)_tmin$(2)_tmax$(3)_dt0.1.json.gz)
FIX_OUTPUT  := intermediary_data/fixed_point/{op}_tmin{tmin}_tmax{tmax}_dt{dt}.json.gz
FIX_TARGET  := $(subst {op},$(1),$(subst {tmin},$(2),$(subst {tmax},$(3),$(subst {dt},0.1,$(FIX_OUTPUT)))))
OUTPUTS += $(FIX_TARGET)
$$(FIX_TARGET): $$(FIX_INPUTS)
> python $$(FIX_SCRIPT) $$^ --output_filename $$@ 
endef

define EXT_CONT
EXT_SCRIPT := ${SRC_DIR}/extrapolate_continuum.py
EXT_IN_DIR := intermediary_data/beta_interpolation
EXT_TIMES  := $(shell seq $(3) 0.1 $(4))
EXT_INPUTS := $(foreach T,$(EXT_TIMES),$(EXT_IN_DIR)/t$(T)_$(1).json.gz)
EXT_OUTPUT := intermediary_data/continuum_extrapolation/{op}_gsquared{gsq}_tmin{tmin}_tmax{tmax}_dt{dt}.json.gz
EXT_TARGET := $(subst {op},$(1),$(subst {gsq},$(2),$(subst {tmin},$(3),$(subst {tmax},$(4),$(subst {dt},0.1,$(EXT_OUTPUT))))))
OUTPUTS += $(EXT_TARGET)
$$(EXT_TARGET): $$(EXT_INPUTS)
> python $$(EXT_SCRIPT) $$^ --output_filename $$@ \
                            --g_squared $(2)           
endef

define INT_FINITE_A
INT_FIT_ORDER := 4
INT_SCRIPT := ${SRC_DIR}/fit_beta_against_g2.py
INT_IN_DIR := intermediary_data/infinite_volume
INT_INPUTS := $(foreach BETA,$(BETAS),$(INT_IN_DIR)/b$(BETA)_t$(2)_$(1).json.gz)
INT_OUTPUT := intermediary_data/beta_interpolation/t{time}_{op}.json.gz
INT_TARGET := $(subst {time},$(2),$(subst {op},$(1),$(INT_OUTPUT)))
OUTPUTS += $(INT_TARGET)
$$(INT_TARGET): $$(INT_INPUTS)
> python $$(INT_SCRIPT) $$^ --output_filename $$@ \
                            --order $(INT_FIT_ORDER)           
endef

define EXT_VOL
SCRIPT := ${SRC_DIR}/extrapolate_infinite_volume.py
INPUTS := $(wildcard raw_data/*b$(1).txt)
OUTPUT := intermediary_data/infinite_volume/b{beta}_t{time}_{op}.json.gz
TARGET := $(subst {op},$(2),$(subst {time},$(3),$(subst {beta},$(1),$(OUTPUT))))
OUTPUTS += $(TARGET)
$$(TARGET): $$(INPUTS)
> python $$(SCRIPT) $$^ --output_filename $$@ \
                        --operator $(2)       \
                        --time $(3)
endef

define PLOT_VOL
PVOL_BETAS = 960 980 102
PVOL_TIMES = 2.5 3.5 4.5 6.0
PVOL_SCRIPT := ${SRC_DIR}/plot_infinite_volume_extrapolation.py
PVOL_INPUT  := $(foreach TIME,$(PVOL_TIMES),$(foreach BETA,$(PVOL_BETAS),intermediary_data/infinite_volume/b$(BETA)_t$(TIME)_$(1).json.gz))
PVOL_OUTPUT := assets/volume_extrapolation_{op}.pdf
PVOL_TARGET := $(subst {op},$(1),$(PVOL_OUTPUT))
OUTPUTS += $(PVOL_TARGET)
$$(PVOL_TARGET): $$(PVOL_INPUT)
> python $$(PVOL_SCRIPT) $$^ --output_filename $$@ \
                             --plot_styles $(PLOT_STYLE)
endef

define PLOT_FINITE_A
FINA_SCRIPT := ${SRC_DIR}/plot_beta_against_g2.py
FINA_INPUT  := $(foreach TIME,$(PVOL_TIMES),intermediary_data/beta_interpolation/t$(TIME)_$(1).json.gz)
FINA_TARGET := assets/beta_interpolation_finite_a_$(1).pdf
##FINA_TARGET := $(subst {op},$(1),$(FINA_OUTPUT))
OUTPUTS += $(FINA_TARGET)
$$(FINA_TARGET): $$(FINA_INPUT)
> python $$(FINA_SCRIPT) $$^ --plot_filename $$@ \
                             --plot_styles $(PLOT_STYLE)
endef



all:
$(foreach OP,$(OPS),$(foreach TMIN,$(TMINS),$(foreach TMAX,$(TMAXS),$(eval $(call FIX_PT,$(OP),$(TMIN),$(TMAX))))))

$(foreach OP,$(OPS),$(foreach G,$(GSQ),$(foreach TMIN,$(TMINS),$(foreach TMAX,$(TMAXS),$(eval $(call EXT_CONT,$(OP),$(G),$(TMIN),$(TMAX)))))))

$(foreach OP,$(OPS),$(foreach TIME,$(TIMES),$(eval $(call INT_FINITE_A,$(OP),$(TIME)))))

$(foreach OP,$(OPS),$(foreach TIME,$(TIMES),$(foreach BETA,$(BETAS),$(eval $(call EXT_VOL,$(BETA),$(OP),$(TIME))))))

$(foreach OP,$(OPS),$(eval $(call PLOT_VOL,$(OP))))
$(foreach OP,$(OPS),$(eval $(call PLOT_FINITE_A,$(OP))))

all: $(OUTPUTS)

.PHONY: clean
clean: 
> rm intermediary_data/*/*.json.gz


