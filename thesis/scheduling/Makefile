TOPDIR := $(shell pwd)

GNUPLOT_TERMINAL := epslatex dashlength 4
GNUPLOT := gnuplot  
FIG2DEV := fig2dev
MKOCTFILE := mkoctfile
OCTAVE := octave
PLATFORM := $(shell uname -s)
ifeq ($(PLATFORM),Linux)
PLOTICUS := ploticus
else
PLOTICUS := pl
endif

OCTAVE_FLAGS := --silent 
EPSTOPDF := epstopdf



FIG_SRC := ABexample.fig ABgantt.fig

PLOTICUS_EPS := T_12_CL.eps T_24_CL.eps  gantt_24.eps gantt_12.eps gantt_NT.eps gantt_Periodic.eps gantt_NT_disturbance.eps\
CL_T_disturbance.eps CL_NT_disturbance.eps

PLOTICUS_DAT := STA_T_12.dat STB_T_12.dat schedule_T_12.dat schedule_T_24.dat \
STA_T_24.dat STB_T_24.dat gantt_NT.dat gantt_Periodic.dat iprofile_Periodic.dat \
STA_NT_disturbnace.dat STB_NT_disturbance.dat STA_T_disturbance.dat STB_T_disturbance.dat \
BOA_NT_disturbance.dat BOB_NT_disturbance.dat BOA_T_disturbance.dat BOB_T_disturbance.dat \
gantt_NT_disturbance.dat

## End of user specified files.

FIG_TEX := $(FIG_SRC:.fig=.tex)
FIG_EPS := $(FIG_SRC:.fig=.eps)
FIG_PDF := $(FIG_SRC:.fig=.pdf)

PLOTICUS_PDF := $(PLOTICUS_EPS:.eps=.pdf)

## The parts of the figures we create.  The PDF parts will be
## generated automatically by the rules in epstopdf.sty.  They are
## listed here so we can use them in the clean rules.

TEX_PARTS := $(FIG_TEX) 
EPS_PARTS := $(FIG_EPS) $(PLOTICUS_EPS)
PDF_PARTS := $(FIG_PDF) $(PLOTICUS_PDF)

## The first target is the one that will be made by default (by typing
## "make" with no target arguments).  The traditional name for the default
## target is "all".

all: $(TEX_PARTS) $(PDF_PARTS)  getfigs

getfigs : 
	@$(foreach fig, $(TEX_PARTS), $(do-get-figs))

define do-get-figs
	echo $(basename $(fig))
	sed -e "s@$(basename $(fig))@scheduling/$(basename $(fig))@" $(fig) > $(addsuffix .t,$(fig))
	sed -e "s@scheduling/scheduling/$(basename $(fig))@scheduling/$(basename $(fig))@" $(addsuffix .t,$(fig)) > $(fig)
	rm -f $(fig).t
endef

clean:
	rm -f $(TEX_PARTS)
	rm -f $(EPS_PARTS)
	rm -f $(PDF_PARTS)
.PHONY: clean

realclean: clean
	rm -f *~
.PHONY: realclean


$(FIG_TEX) : %.tex : %.fig
	@echo making $@
	@$(FIG2DEV) -L pstex_t -p $* $< > $@.t
	@mv $@.t $@

$(FIG_EPS) : %.eps : %.fig
	@echo making $@
	@$(FIG2DEV) -L pstex $< > $@.t
	@mv $@.t $@

$(PDF_PARTS) : %.pdf : %.eps
	@echo making $@
	@$(EPSTOPDF) $< --outfile $@.t 2> /dev/null
	@mv $@.t $@

#to make T_24_CL
T_24_CL.eps: schedule_T_24.dat STA_T_24.dat STB_T_24.dat  schedule_inv.p
	@cp schedule_T_24.dat schedule.dat
	@cp STA_T_24.dat STA.dat
	@cp STB_T_24.dat STB.dat
	@$(PLOTICUS) -eps schedule_inv.p
	@mv schedule_inv.eps T_24_CL.eps
	@rm STA.dat
	@rm STB.dat
	@rm schedule.dat

#to make T_12_CL
T_12_CL.eps: schedule_T_12.dat STA_T_12.dat STB_T_12.dat  schedule_inv.p
	@cp schedule_T_12.dat schedule.dat
	@cp STA_T_12.dat STA.dat
	@cp STB_T_12.dat STB.dat
	@$(PLOTICUS) -eps schedule_inv.p
	@mv schedule_inv.eps T_12_CL.eps
	@rm STA.dat
	@rm STB.dat
	@rm schedule.dat
#to make gantt_12.pdf

gantt_12.eps: selectgantt.p gantt_T_12.dat
	@cp gantt_T_12.dat selectgantt.dat
	@$(PLOTICUS) -eps selectgantt.p
	@mv selectgantt.eps gantt_12.eps
	@rm selectgantt.dat

#to make gantt_24.pdf
gantt_24.eps: selectgantt.p gantt_T_24.dat
	@cp gantt_T_24.dat selectgantt.dat
	@$(PLOTICUS) -eps selectgantt.p
	@mv selectgantt.eps gantt_24.eps
	@rm selectgantt.dat

gantt_NT.eps: selectgantt.p gantt_NT.dat
	@cp gantt_NT.dat selectgantt.dat
	@$(PLOTICUS) -eps selectgantt.p
	@mv selectgantt.eps gantt_NT.eps
	@rm selectgantt.dat

gantt_Periodic.eps: gantt_Periodic.dat iprofile_Periodic.dat gantt_Periodic.p
	@$(PLOTICUS) -eps gantt_Periodic.p

gantt_NT_disturbance.eps: gantt_NT_disturbance.dat gantt_disturbance.p
	@cp gantt_NT_disturbance.dat selectgantt.dat
	@$(PLOTICUS) -eps gantt_disturbance.p
	@mv gantt_disturbance.eps gantt_NT_disturbance.eps
	@rm selectgantt.dat

CL_T_disturbance.eps:  STA_T_disturbance.dat STB_T_disturbance.dat  BOB_T_disturbance.dat BOA_T_disturbance.dat inventoryprofile_disturbance.p
	@cp STA_T_disturbance.dat STA.dat
	@cp STB_T_disturbance.dat STB.dat
	@cp BOA_T_disturbance.dat BOA.dat
	@cp BOB_T_disturbance.dat BOB.dat
	@$(PLOTICUS) -eps inventoryprofile_disturbance.p
	@mv inventoryprofile_disturbance.eps CL_T_disturbance.eps
	@rm STA.dat
	@rm STB.dat
	@rm BOA.dat
	@rm BOB.dat

CL_NT_disturbance.eps:  STA_NT_disturbance.dat STB_NT_disturbance.dat  BOB_NT_disturbance.dat BOA_NT_disturbance.dat inventoryprofile_disturbance.p
	@cp STA_NT_disturbance.dat STA.dat
	@cp STB_NT_disturbance.dat STB.dat
	@cp BOA_NT_disturbance.dat BOA.dat
	@cp BOB_NT_disturbance.dat BOB.dat
	@$(PLOTICUS) -eps inventoryprofile_disturbance.p
	@mv inventoryprofile_disturbance.eps CL_NT_disturbance.eps
	@rm STA.dat
	@rm STB.dat
	@rm BOA.dat
	@rm BOB.dat
