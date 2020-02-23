TOPDIR := $(shell pwd)

GNUPLOT_TERMINAL := epslatex color solid #dashlength 4
GNUPLOT := gnuplot  
FIG2DEV := fig2dev
MKOCTFILE := mkoctfile
OCTAVE := octave
PLATFORM := $(shell uname -s)
OCTAVE_FLAGS := --silent 
EPSTOPDF := epstopdf


FIG_SRC := nodes1_color.fig model.fig 2node.fig lssc.fig

SS_GP :=  sS_demand_input.gp sS_demand.gp
IP_GP :=  IP_dem.gp IP_dem_input.gp

GNUPLOT_SRC := $(SS_GP) $(IP_GP) CL1.gp CL2.gp


CUSTOM_DAT := sS_demand.dat IP_dem.dat Sequential.dat

VN_GP := VN.gp

IPROFILE_GP := Rprofile.gp  R1profile.gp 

CONV_GP := Conv.gp

CUSTOM1_GP := $(VN_GP) $(IPROFILE_GP) $(CONV_GP)
## End of user specified files.

FIG_TEX := $(FIG_SRC:.fig=.tex)
FIG_EPS := $(FIG_SRC:.fig=.eps)
FIG_PDF := $(FIG_SRC:.fig=.pdf)

GNUPLOT_TEX := $(GNUPLOT_SRC:.gp=.tex)
GNUPLOT_DAT := $(GNUPLOT_SRC:.gp=.dat)
GNUPLOT_EPS := $(GNUPLOT_SRC:.gp=.eps)
GNUPLOT_PDF := $(GNUPLOT_SRC:.gp=.pdf)

CUSTOM1_TEX := $(CUSTOM1_GP:.gp=.tex)
CUSTOM1_EPS := $(CUSTOM1_GP:.gp=.eps)
CUSTOM1_PDF := $(CUSTOM1_GP:.gp=.pdf)

TEX_PARTS := $(FIG_TEX) $(GNUPLOT_TEX) $(CUSTOM1_TEX)
EPS_PARTS := $(FIG_EPS) $(GNUPLOT_EPS) $(CUSTOM1_EPS)
PDF_PARTS := $(FIG_PDF) $(GNUPLOT_PDF) $(CUSTOM1_PDF)


all:  $(TEX_PARTS) $(PDF_PARTS) getfigs

#@is used as a delimiter for sed.
#will put directoru/figurename in figure.tex
define do-get-figs
	echo $(basename $(fig))
	sed -e "s@$(basename $(fig))@sc/$(basename $(fig))@" $(fig) > $(addsuffix .t,$(fig))
	sed -e "s@sc/sc/$(basename $(fig))@sc/$(basename $(fig))@" $(addsuffix .t,$(fig)) > $(fig)
	rm -f $(fig).t
endef


define do-gnuplot-command
echo making $*.tex and $*.eps
sed -e "s/^#* *set terminal.*/set terminal $(GNUPLOT_TERMINAL)/" \
    -e "s/^#* *set output.*/set output \"$*.tex\"/" $< > $<.t;
$(GNUPLOT) $<.t
if [ $$? -eq 0 -a -s $*.tex -a -s $*.eps ]; then true; else rm -f $*.tex $*.tex.t $*.eps; fi
rm -f $<.t
endef

clean:
	rm -f $(TEX_PARTS)
	rm -f $(EPS_PARTS)
	rm -f $(PDF_PARTS)

.PHONY: clean

realclean: clean
	rm -f *~

.PHONY: realclean

getfigs : 
	@$(foreach fig, $(TEX_PARTS), $(do-get-figs))

$(FIG_TEX) : %.tex : %.fig
	@echo making $@
	@$(FIG2DEV) -L pstex_t -p $* $< > $@.t
	@mv $@.t $@

$(FIG_EPS) : %.eps : %.fig
	@echo making $@
	@$(FIG2DEV) -L pstex $< > $@.t
	@mv $@.t $@


$(GNUPLOT_TEX) : %.tex : %.gp 
	@$(do-gnuplot-command)

$(GNUPLOT_EPS) : %.eps : %.gp  
	@$(do-gnuplot-command)

$(CUSTOM1_TEX) : %.tex : %.gp Sequential.dat
	@$(do-gnuplot-command)

$(CUSTOM1_EPS) : %.eps : %.gp Sequential.dat
	@$(do-gnuplot-command

$(PDF_PARTS) : %.pdf : %.eps
	@echo making $@
	@$(EPSTOPDF) $< --outfile $@.t 2> /dev/null
	@mv $@.t $@