TOPDIR := $(shell pwd)

GNUPLOT_TERMINAL := epslatex color solid  #dashlength 4
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



FIG_SRC := 2tanks_dist.fig two_tanks.fig MPC_gen.fig

GNUPLOT_SRC := CL1.gp CL2.gp unstable_x.gp unstable_u1.gp unstable_u2.gp

OCTAVE_SRC :=

EXTRA_EPS :=

EXTRA_JPG :=

TABLE_SRC :=

CUSTOM_DAT := 

CUSTOM_OCT := 

CUSTOM_TEX :=

CUSTOM_TAB := 
EXTRA_CC :=

## End of user specified files.

FIG_TEX := $(FIG_SRC:.fig=.tex)
FIG_EPS := $(FIG_SRC:.fig=.eps)
FIG_PDF := $(FIG_SRC:.fig=.pdf)

GNUPLOT_TEX := $(GNUPLOT_SRC:.gp=.tex)
GNUPLOT_EPS := $(GNUPLOT_SRC:.gp=.eps)
GNUPLOT_PDF := $(GNUPLOT_SRC:.gp=.pdf)
GNUPLOT_DAT := $(GNUPLOT_SRC:.gp=.dat)









## The parts of the figures we create.  The PDF parts will be
## generated automatically by the rules in epstopdf.sty.  They are
## listed here so we can use them in the clean rules.

TEX_PARTS := $(FIG_TEX) $(GNUPLOT_TEX) $(OCTAVE_TEX) $(TABLE_TEX)	\
	     $(CUSTOM_TEX) $(CUSTOM_TABTEX)
EPS_PARTS := $(FIG_EPS) $(GNUPLOT_EPS) $(OCTAVE_EPS) $(CUSTOM_EPS) 
PDF_PARTS := $(FIG_PDF) $(GNUPLOT_PDF) $(OCTAVE_PDF) $(EXTRA_PDF) $(CUSTOM_PDF) 
## The first target is the one that will be made by default (by typing
## "make" with no target arguments).  The traditional name for the default
## target is "all".

all: $(PAPER_SRC) $(TEX_PARTS) $(PDF_PARTS) $(EXTRA_JPG) getfigs

getfigs : 
	@$(foreach fig, $(TEX_PARTS), $(do-get-figs))

define do-get-figs
	echo $(basename $(fig))
	sed -e "s@$(basename $(fig))@mpc/$(basename $(fig))@" $(fig) > $(addsuffix .t,$(fig))
	sed -e "s@mpc/mpc/$(basename $(fig))@mpc/$(basename $(fig))@" $(addsuffix .t,$(fig)) > $(fig)
	rm -f $(fig).t
endef

clean:
	rm -f $(PAPER_MISC)
	rm -f $(TEX_PARTS)
	rm -f $(EPS_PARTS)
	rm -f $(PDF_PARTS)
	rm -f $(EXTRA_O)
.PHONY: clean

realclean: clean
	rm -f $(OCTAVE_DAT) $(PAPER_XBIB) $(CUSTOM_DAT) $(EXTRA_OCT)
.PHONY: realclean

distclean: realclean
	rm -f *~
.PHONY: distclean

dist: $(DISTFILES)
	echo $(PACKAGE)-$(VERSION) > .fname
	rm -rf `cat .fname`
	mkdir `cat .fname`
	ln $(DISTFILES) `cat .fname`
	tar chf `cat .fname`.tar `cat .fname`
	rm -rf `cat .fname`
	tar xf `cat .fname`.tar
	chmod -R a+rwX `cat .fname`
	tar chf `cat .fname`.tar `cat .fname`
	gzip --best `cat .fname`.tar
	date -u > md5sum
	md5sum `cat .fname`.tar.gz >> md5sum
	touch `cat .fname`.tar.gz md5sum
	rm -rf `cat .fname`
	rm -f .fname
.PHONY: dist

## How to generate epslatex (.eps + .tex) files from a .fig file.
##
## By using a pattern rule like
##
##   $(FIG_TEX) : %.tex : %.fig
##
## instead of simply
##
##   %.tex : %.fig
##
## we limit the application of this rule to those files in the
## $(FIG_TEX) list.

$(FIG_TEX) : %.tex : %.fig
	@echo making $@
	@$(FIG2DEV) -L pstex_t -p $* $< > $@.t
	@mv $@.t $@

$(FIG_EPS) : %.eps : %.fig
	@echo making $@
	@$(FIG2DEV) -L pstex $< > $@.t
	@mv $@.t $@

## Rules for making epslatex (.eps + .tex) files from a .gp file.

define do-gnuplot-command
echo making $*.tex and $*.eps
sed -e "s/^#* *set terminal.*/set terminal $(GNUPLOT_TERMINAL)/" \
    -e "s/^#* *set output.*/set output \"$*.tex\"/" $< > $<.t;
$(GNUPLOT) $<.t
if [ $$? -eq 0 -a -s $*.tex -a -s $*.eps ]; then true; else rm -f $*.tex $*.tex.t $*.eps; fi
rm -f $<.t
endef

$(GNUPLOT_TEX) : %.tex : %.gp %.dat
	@$(do-gnuplot-command)

$(GNUPLOT_EPS) : %.eps : %.gp %.dat
	@$(do-gnuplot-command)

## Rule for generating .pdf files from .eps files

$(PDF_PARTS) : %.pdf : %.eps
	@echo making $@
	@$(EPSTOPDF) $< --outfile $@.t 2> /dev/null
	@mv $@.t $@


## Custom rules go here:

