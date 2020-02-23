TOPDIR := $(shell pwd)

GNUPLOT_TERMINAL := epslatex color solid
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



FIG_SRC := lssc.fig 

PLOTICUS_SRC := SS_gantt.p NTS_gantt.p TS_gantt.p

GNUPLOT_SRC := BOprofile.gp bullwhip.gp CL2.gp CL4.gp CL8.gp R3.gp R5.gp unstable_SC.gp stable_SC.gp SS_omega.gp Xf4.gp


## End of user specified files.

FIG_TEX := $(FIG_SRC:.fig=.tex)
FIG_EPS := $(FIG_SRC:.fig=.eps)
FIG_PDF := $(FIG_SRC:.fig=.pdf)

PLOTICUS_EPS := $(PLOTICUS_SRC:.p=.eps)
PLOTICUS_PDF := $(PLOTICUS_SRC:.p=.pdf)
PLOTICUS_DAT := $(PLOTICUS_SRC:.p=.dat)

GNUPLOT_TEX := $(GNUPLOT_SRC:.gp=.tex)
GNUPLOT_EPS := $(GNUPLOT_SRC:.gp=.eps)
GNUPLOT_PDF := $(GNUPLOT_SRC:.gp=.pdf)
GNUPLOT_DAT := $(GNUPLOT_SRC:.gp=.dat)
## The parts of the figures we create.  The PDF parts will be
## generated automatically by the rules in epstopdf.sty.  They are
## listed here so we can use them in the clean rules.

TEX_PARTS := $(FIG_TEX) $(GNUPLOT_TEX)
EPS_PARTS := $(FIG_EPS) $(PLOTICUS_EPS) $(GNUPLOT_EPS)
PDF_PARTS := $(FIG_PDF) $(PLOTICUS_PDF) $(GNUPLOT_PDF)

DAT_FILES := $(GNUPLOT_DAT) $(PLOTICUS_DAT)
DIST_PARTS := $(FIG_SRC) $(PLOTICUS_SRC) $(GNUPLOT_SRC) $(DAT_FILES) esc.tex 

#definition rules
define do-get-figs
	echo $(basename $(fig))
	sed -e "s@$(basename $(fig))@esc/$(basename $(fig))@" $(fig) > $(addsuffix .t,$(fig))
	sed -e "s@esc/esc/$(basename $(fig))@esc/$(basename $(fig))@" $(addsuffix .t,$(fig)) > $(fig)
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

all: $(TEX_PARTS) $(PDF_PARTS)  getfigs
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

$(GNUPLOT_TEX): %.tex : %.gp %.dat
	@echo making $@
	@$(do-gnuplot-command)

$(GNUPLOT_EPS): %.eps : %.gp %.dat
	@echo making $@
	@$(do-gnuplot-command)

$(PLOTICUS_EPS): %.eps : %.p %.dat
	@echo making $@
	@$(PLOTICUS) -eps $<

$(PDF_PARTS) : %.pdf : %.eps
	@echo making $@
	@$(EPSTOPDF) $< --outfile $@.t 2> /dev/null
	@mv $@.t $@

