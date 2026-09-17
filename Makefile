.RECIPEPREFIX = >

SRC_DIR  := src
BETA_DIR := intermediary_data/beta_interpolation
CONT_DIR := intermediary_data/continuum_extrapolation
FIX_DIR  := intermediary_data/fixed_point
VOL_DIR  := intermediary_data/infinite_volume

# generate folder structure
$(shell mkdir -p $(BETA_DIR) $(CONT_DIR) $(FIX_DIR) $(VOL_DIR))
$(shell mkdir -p assets)

LATTSZE := 24 28 32 36 40 
BETAS   := 920 940 960 980 100 102 104 108 110 114 120 128 136 146
OPS     := plaq sym
TIMES   := $(shell seq 2.5 0.1 6.7)
GSQ     := $(shell seq 1.8 0.1 10.4)
FIX_GSQ := $(shell seq 4.5 0.1 8.5)

TMINS  := $(shell seq 3 0.1 4)
TMAXS  := 5.0 5.5 6.0
TMINS2 := 2.5 3.5
TMAXS2 := 6.0 6.8

PLOT_STYLE = styles/paperdraft.mplstyle

PVOL_BETAS  := 960 980 102
PVOL_TIMES  := 2.5 3.5 4.5 6.0
PLOT_GSQ    := 2.0 4.0 6.0 8.0
PLOT_TICKS  := 2.0 2.5 3.5 4.5 6.0

define FIX_PT
FIX_SCRIPT  := $(SRC_DIR)/fit_fixed_point.py
FIX_INPUTS  := $(foreach G,$(FIX_GSQ),$(CONT_DIR)/$(1)_gsquared$(G)_tmin$(2)_tmax$(3)_dt$(4).json.gz)
FIX_TARGET  := $(FIX_DIR)/$(1)_tmin$(2)_tmax$(3)_dt$(4).json.gz
OUTPUTS += $(FIX_TARGET)
$$(FIX_TARGET): $$(FIX_INPUTS)
> python $$(FIX_SCRIPT) $$^ --output_filename $$@ 
endef

define EXT_CONT
EXT_SCRIPT := $(SRC_DIR)/extrapolate_continuum.py
EXT_TIMES  := $(shell seq $(3) $(5) $(4))
EXT_INPUTS := $$(foreach T,$$(EXT_TIMES),$$(BETA_DIR)/t$$(T)_$(1).json.gz)
EXT_TARGET := $(CONT_DIR)/$(1)_gsquared$(2)_tmin$(3)_tmax$(4)_dt$(5).json.gz
OUTPUTS += $(EXT_TARGET)
$$(EXT_TARGET): $$(EXT_INPUTS)
> python $$(EXT_SCRIPT) $$^ --output_filename $$@ \
                            --g_squared $(2)           
endef

define INT_FINITE_A
INT_FIT_ORDER := 4
INT_SCRIPT := $(SRC_DIR)/fit_beta_against_g2.py
INT_INPUTS = $(foreach BETA,$(BETAS),$(VOL_DIR)/b$(BETA)_t$(2)_$(1).json.gz)
INT_TARGET := $(BETA_DIR)/t$(2)_$(1).json.gz
OUTPUTS += $(INT_TARGET)
$$(INT_TARGET): $$(INT_INPUTS)
> python $$(INT_SCRIPT) $$^ --output_filename $$@ \
                            --order $$(INT_FIT_ORDER)           
endef

define EXT_VOL
SCRIPT := $(SRC_DIR)/extrapolate_infinite_volume.py
INPUTS := $(foreach L,$(LATTSZE),raw_data/l$(L)t$(L)b$(1).txt)
TARGET := $(VOL_DIR)/b$(1)_t$(3)_$(2).json.gz
OUTPUTS += $(TARGET)
$$(TARGET): $$(INPUTS) 
> python $$(SCRIPT) $$^ --output_filename $$@ \
                        --operator $(2)       \
                        --time $(3)
endef

## PLOTS
define PLOT_VOL
PVOL_SCRIPT := $(SRC_DIR)/plot_infinite_volume_extrapolation.py
PVOL_INPUT  = $(foreach TIME,$(PVOL_TIMES),$(foreach BETA,$(PVOL_BETAS),$(VOL_DIR)/b$(BETA)_t$(TIME)_$(1).json.gz))
PVOL_TARGET := assets/volume_extrapolation_$(1).pdf
$$(PVOL_TARGET): $$(PVOL_INPUT)
> python $$(PVOL_SCRIPT) $$^ --output_filename $$@ \
                             --plot_styles $(PLOT_STYLE)
endef
ASSETS += assets/volume_extrapolation_plaq.pdf
ASSETS += assets/volume_extrapolation_sym.pdf

define PLOT_FINITE_A
FINA_SCRIPT := $(SRC_DIR)/plot_beta_against_g2.py
FINA_INPUT  := $(foreach TIME,$(PVOL_TIMES),$(BETA_DIR)/t$(TIME)_$(1).json.gz)
FINA_TARGET := assets/beta_interpolation_finite_a_$(1).pdf
$$(FINA_TARGET): $$(FINA_INPUT)
> python $$(FINA_SCRIPT) $$^ --plot_filename $$@ \
                             --plot_styles $(PLOT_STYLE)
endef
ASSETS += assets/beta_interpolation_finite_a_plaq.pdf
ASSETS += assets/beta_interpolation_finite_a_sym.pdf

# plot fixed point scan
PFIX_SCRIPT := ${SRC_DIR}/plot_fixed_point_scan.py
PFIX_INPUT  := $(foreach OP,$(OPS),$(foreach TMIN,$(TMINS),$(foreach TMAX,$(TMAXS),$(FIX_DIR)/$(OP)_tmin$(TMIN)_tmax$(TMAX)_dt0.1.json.gz)))
PFIX_TARGET := assets/fixed_point_scan.pdf
ASSETS += $(PFIX_TARGET)

# plot continuum beta function
CONTB_SCRIPT := ${SRC_DIR}/plot_beta_against_g2_continuum.py
CONTB_INPUT  := $(foreach OP,$(OPS),$(foreach G,$(GSQ),$(CONT_DIR)/$(OP)_gsquared$(G)_tmin3.5_tmax6.0_dt0.2.json.gz))
CONTB_TARGET := assets/continuum_betafunction.pdf
ASSETS += $(CONTB_TARGET)

# plot continuum extrapolation
PCONT_SCRIPT := $(SRC_DIR)/plot_continuum_extrapolation.py
PCONT_FIT_DATA := $(foreach OP,$(OPS),$(foreach G,$(PLOT_GSQ),$(CONT_DIR)/$(OP)_gsquared$(G)_tmin3.5_tmax6.0_dt0.2.json.gz))
PCONT_UNFIT_DATA := $(foreach OP,$(OPS),$(foreach G,$(PLOT_GSQ),$(CONT_DIR)/$(OP)_gsquared$(G)_tmin2.5_tmax6.8_dt0.2.json.gz))
PCONT_TARGET := assets/continuum_extrapolation.pdf
ASSETS += $(PCONT_TARGET)

all: dload_data .WAIT $(ASSETS)

all:
$(foreach OP,$(OPS),$(foreach TMIN,$(TMINS),$(foreach TMAX,$(TMAXS),$(eval $(call FIX_PT,$(OP),$(TMIN),$(TMAX),0.1)))))
$(foreach OP,$(OPS),$(foreach TMIN,$(TMINS2),$(foreach TMAX,$(TMAXS2),$(eval $(call FIX_PT,$(OP),$(TMIN),$(TMAX),0.2)))))

$(foreach OP,$(OPS),$(foreach G,$(GSQ),$(foreach TMIN,$(TMINS),$(foreach TMAX,$(TMAXS),$(eval $(call EXT_CONT,$(OP),$(G),$(TMIN),$(TMAX),0.1))))))
$(foreach OP,$(OPS),$(foreach G,$(GSQ),$(foreach TMIN,$(TMINS2),$(foreach TMAX,$(TMAXS2),$(eval $(call EXT_CONT,$(OP),$(G),$(TMIN),$(TMAX),0.2))))))

$(foreach OP,$(OPS),$(foreach TIME,$(TIMES),$(eval $(call INT_FINITE_A,$(OP),$(TIME)))))

$(foreach OP,$(OPS),$(foreach TIME,$(TIMES),$(foreach BETA,$(BETAS),$(eval $(call EXT_VOL,$(BETA),$(OP),$(TIME))))))

$(foreach OP,$(OPS),$(eval $(call PLOT_VOL,$(OP))))
$(foreach OP,$(OPS),$(eval $(call PLOT_FINITE_A,$(OP))))

$(PFIX_TARGET): $(PFIX_INPUT)
> python $(PFIX_SCRIPT) $^ --plot_filename $@ \
                           --plot_styles $(PLOT_STYLE)


$(CONTB_TARGET): $(CONTB_INPUT)
> python $(CONTB_SCRIPT) $^   --plot_filename $@ \
                              --plot_styles $(PLOT_STYLE)

$(PCONT_TARGET): $(PCONT_FIT_DATA) $(PCONT_UNFIT_DATA)
> python $(PCONT_SCRIPT) $(PCONT_FIT_DATA) --unfit_filenames $(PCONT_UNFIT_DATA) \
                                           --tick_times $(PLOT_TICKS) \
                                           --output_file $@ \
                                           --plot_styles $(PLOT_STYLE)
.PHONY: clean dload_data

clean: 
> rm -rf raw_data
> rm -rf intermediary_data
> rm -rf assets

dload_data:
> uvx zenodo_get -d 10.5281/zenodo.10719052 -o raw_data


