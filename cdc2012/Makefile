TOPDIR := $(shell pwd)

#GNUPLOT_TERMINAL := epslatex color solid
GNUPLOT_TERMINAL := epslatex monochrome dashed
GNUPLOT := gnuplot  
FIG2DEV := fig2dev
MKOCTFILE := mkoctfile
OCTAVE := octave
OCTAVE_FLAGS := --silent
EPSTOPDF := epstopdf
PDFVIEWER := evince

TEXSUFFIXES := .pdf .aux .log .bbl .blg

PAPER_SRC  := paper.tex
PAPER      := $(basename $(PAPER_SRC))
PAPER_PDF  := $(addsuffix .pdf, $(PAPER))
PAPER_AUX  := $(addsuffix .aux, $(PAPER))
PAPER_XBIB := $(addsuffix .xbib, $(PAPER))
PAPER_MISC := $(addprefix $(PAPER), $(TEXSUFFIXES))

## User defines a list of files for FIG_SRC, GNUPLOT_SRC, OCTAVE_SRC,
## EXTRA_EPS, and EXTRA_JPG.  Other file names are constructed
## automatically from those lists.

## FIG_SRC.  These are figures that can be described completely using fig
## commands and that require no external data.

FIG_SRC := 2tanks.fig

## GNUPLOT_SRC. These are figures that can be described completely
## using gnuplot commands and that require no external data.

GNUPLOT_SRC := 


## OCTAVE_SRC.  These are figures described by a combination of a
## single data file generated from an Octave script and a
## corresponding plot description file for gnuplot:
##
##   base.m -- octave --> base.dat
##   base.dat + base.gp -- gnuplot --> base.tex + base.eps
##   base.eps -- epstopdf --> base.pdf
##
## The file base.tex is inserted in a LaTeX document with \input{base}.

OCTAVE_SRC := 

## EXTRA_EPS.  These are standalone PostScript figures that have no
## corresponding source files.

EXTRA_EPS := 

## EXTRA_JPG.  These are standalone jpeg figures that have no
## corresponding source files.

EXTRA_JPG := 

## TABLE_SRC. These Octave scripts generate a table that can
## be used in a LaTeX document
##
##   base.m -- octave --> base.tex
##
## The files base.tex is inserted in a LaTeX docment with \input{base}.

TABLE_SRC := 

## The following variables are used to list custom files that are more
## complicated than the default rules that use OCTAVE_SRC.
##
## These are CUSTOM_DAT for realclean  CUSTOM_OCT and CUSTOM_GP for DISTFILES and 
## CUSTOM_TEX for making PAPER_PDF

## user must supply rules for making CUSTOM_TEX and CUSTOM_DAT files at the bottom 

## CUSTOM_DAT.  You must specify rules to generate these files (search
## for "Custom rules go here" near the bottom of this file).  These
## files are removed by the realclean target.

unstable_dat := unstable_x.dat unstable_u1.dat unstable_u2.dat 
#sS_dat := sS_demand.dat sS_demand_input.dat  
#IP_dat := IP_dem.dat IP_dem_input.dat 
CUSTOM_DAT := $(unstable_dat) $(sS_dat) $(IP_dat)

## CUSTOM_OCT.  These are the Octave scripts that are used to generate
## the CUSTOM_DAT files.  The files listed here are included in the
## DISTFILES list.

CUSTOM_OCT := unstable_x.m 
#sS_demand.m IP_dem.m

## CUSTOM_TEX.  These files are figures generated using CUSTOM_DAT.
## For each file in the CUSTOM_TEX list, there should be one plot
## description file with the same base name:
##
##   base.gp + (some data files) -- gnuplot --> base.tex + base.eps
##   base.eps -- epstopdf --> base.pdf

CUSTOM_TEX := unstable_x.tex  unstable_u1.tex unstable_u2.tex
#sS_demand.tex IP_dem.tex IP_dem_input.tex sS_demand_input.tex 



## End of user specified files.

FIG_TEX := $(FIG_SRC:.fig=.tex)
FIG_EPS := $(FIG_SRC:.fig=.eps)
FIG_PDF := $(FIG_SRC:.fig=.pdf)

GNUPLOT_TEX := $(GNUPLOT_SRC:.gp=.tex)
GNUPLOT_EPS := $(GNUPLOT_SRC:.gp=.eps)
GNUPLOT_PDF := $(GNUPLOT_SRC:.gp=.pdf)

OCTAVE_DAT := $(OCTAVE_SRC:.m=.dat)
OCTAVE_GP  := $(OCTAVE_SRC:.m=.gp)
OCTAVE_TEX := $(OCTAVE_SRC:.m=.tex)
OCTAVE_EPS := $(OCTAVE_SRC:.m=.eps)
OCTAVE_PDF := $(OCTAVE_EPS:.eps=.pdf)

TABLE_TEX := $(TABLE_SRC:.m=.tex)

EXTRA_PDF := $(EXTRA_EPS:.eps=.pdf)

CUSTOM_GP  := $(CUSTOM_TEX:.tex=.gp)
CUSTOM_EPS := $(CUSTOM_TEX:.tex=.eps)
CUSTOM_PDF := $(CUSTOM_TEX:.tex=.pdf)



## The parts of the figures we create.  The PDF parts will be
## generated automatically by the rules in epstopdf.sty.  They are
## listed here so we can use them in the clean rules.

TEX_PARTS := $(FIG_TEX) $(GNUPLOT_TEX) $(OCTAVE_TEX) $(CUSTOM_TEX) $(TABLE_TEX)
EPS_PARTS := $(FIG_EPS) $(GNUPLOT_EPS) $(OCTAVE_EPS) $(CUSTOM_EPS)
PDF_PARTS := $(FIG_PDF) $(GNUPLOT_PDF) $(OCTAVE_PDF) $(EXTRA_PDF) $(CUSTOM_PDF)

## This ugly mess searches the main paper file for a \bibliography
## command and extracts the names of the .bib files.

BIB_SRC := $(foreach f, $(addsuffix .bib, $(shell sed -n '/^\\bibliography{/ { s/\\bibliography{\([^}]*\)}/\1/; s/,/ /g; p; q }' $(PAPER_SRC))), $(shell kpsewhich $f))

## The list of all the files that should go in the tar file.

DISTFILES := bibextract latex2pdf Makefile \
  $(PAPER_SRC) $(PAPER_XBIB) \
  $(FIG_SRC) $(GNUPLOT_SRC) $(OCTAVE_SRC) $(OCTAVE_GP) \
  $(CUSTOM_OCT) $(CUSTOM_GP) $(EXTRA_EPS) $(EXTRA_JPG)

## The name of the collection of files we will distribute.

PACKAGE := sample-docs

## The version number for the tar file.

VERSION := 0.1

## The first target is the one that will be made by default (by typing
## "make" with no target arguments).  The traditional name for the default
## target is "all".

all: $(PAPER_PDF)
.PHONY: all

$(PAPER_PDF) $(PAPER_AUX): $(PAPER_SRC) $(TEX_PARTS) $(PDF_PARTS) $(EXTRA_JPG) $(BIB_SRC)
	./latex2pdf $(PAPER_SRC)

view: $(PAPER_PDF)
	$(PDFVIEWER) $(PAPER_PDF) &
.PHONY: view

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

$(GNUPLOT_TEX) : %.tex : %.gp
	@$(do-gnuplot-command)

$(GNUPLOT_EPS) : %.eps : %.gp
	@$(do-gnuplot-command)

## Rule for generating .dat files  from .m files using Octave.

$(OCTAVE_DAT) : %.dat : %.m
	@echo making $@
	@$(OCTAVE) $(OCTAVE_FLAGS) $< || rm -f $@

## Rules for making epslatex (.eps + .tex) files from a .gp file and a
## .dat file created from an Octave .m file.

$(OCTAVE_TEX) : %.tex : %.gp %.dat
	@$(do-gnuplot-command)

$(OCTAVE_EPS) : %.eps : %.gp %.dat
	@$(do-gnuplot-command)

## Rule for generating .tex files from .m for generating a table

$(TABLE_TEX) : %.tex : %.m
	@echo making $@
	@$(OCTAVE) $(OCTAVE_FLAGS) $< || rm -f $@


## Rule for generating .pdf files from .eps files

$(PDF_PARTS) : %.pdf : %.eps
	@echo making $@
	@$(EPSTOPDF) $< --outfile $@.t 2> /dev/null
	@mv $@.t $@

## Rule for generating .oct files from .cc

$(EXTRA_OCT) : %.oct : %.cc
	@echo making $@
	@$(MKOCTFILE) $<

## A way to extract entries from the shared BibTeX data bases and
## create a local database just for this document.

$(PAPER_XBIB): $(PAPER_AUX) $(BIB_SRC)
	-./bibextract $(PAPER_AUX) > $(PAPER_XBIB)

## Custom rules go here:

#Make the dat files from the m files
$(unstable_dat): unstable_x.m
	@echo making $@
	@$(OCTAVE) $(OCTAVE_FLAGS) $< || rm -f $@

#$(sS_dat): %.dat : sS_demand.m
#	@echo making $@
#	@$(OCTAVE) $(OCTAVE_FLAGS) $< || rm -f $@

#$(IP_dat): %.dat : IP_dem.m
#	@echo making $@
#	@$(OCTAVE) $(OCTAVE_FLAGS) $< || rm -f $@

#Make the figures
$(CUSTOM_TEX) : %.tex : %.gp %.dat
	@$(do-gnuplot-command)

$(CUSTOM_EPS) : %.eps : %.gp %.dat
	@$(do-gnuplot-command)