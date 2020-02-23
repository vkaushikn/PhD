ßTOPDIR := $(shell pwd)

GNUPLOT_TERMINAL := epslatex color 
GNUPLOT := gnuplot  
FIG2DEV := fig2dev
MKOCTFILE := mkoctfile
OCTAVE := octave
OCTAVE_FLAGS := --silent
EPSTOPDF := epstopdf
PDFVIEWER := evince

TEXSUFFIXES := .pdf .aux .log .bbl .blg .nav .out .snm .toc

#PAPER_SRC  := talk.tex scheduling.tex
PAPER_SRC  := talk.tex
PAPER      := $(basename $(PAPER_SRC))
PAPER_PDF  := $(addsuffix .pdf, $(PAPER))
PAPER_AUX  := $(addsuffix .aux, $(PAPER))
PAPER_XBIB := $(addsuffix .xbib, $(PAPER))
#PAPER_MISC := $(addprefix $(PAPER), $(TEXSUFFIXES))
PAPER_MISC := $(foreach ext, $(TEXSUFFIXES), $(addsuffix $(ext), $(PAPER)))

## User defines a list of files for FIG_SRC, GNUPLOT_SRC, OCTAVE_SRC,
## EXTRA_EPS, and EXTRA_JPG.  Other file names are constructed
## automatically from those lists.

## FIG_SRC.  These are figures that can be described completely using fig
## commands and that require no external data.

FIG_SRC := mpc.fig mpc1.fig mpc2.fig \
	nodes1_color.fig \
	model.fig \
        2node.fig \
	ABexample.fig \
	ABgantt.fig \
	ABlift0.fig \
	ABlift1.fig \
	ABdelay.fig \
	lssc.fig \
        suboptimal-0.fig suboptimal-1.fig suboptimal-2.fig \
	#control-0.fig control-1.fig \
        converge.fig boundary.fig\
	twosubsystems.fig \
	suboptimal.fig \
	2node.fig 



## GNUPLOT_SRC. These are figures that can be described completely
## using gnuplot commands and that require no external data.

GNUPLOT_SRC := unstable_SC.gp stable_SC.gp CL4.gp bullwhip.gp R3.gp sS_demand1.gp sS_demand.gp CL1.gp CL2.gp BOprofile.gp

CUSTOM_PDF := gantt_NT.pdf gantt_Periodic.pdf gantt_24.pdf gantt_NT_disturbance.pdf NTS_gantt.pdf TS_gantt.pdf education.pdf experience.pdf

CUSTOM_JPG := supply_chain.jpg amazon.jpeg







## End of user specified files.


FIG_TEX := $(FIG_SRC:.fig=.tex)
FIG_EPS := $(FIG_SRC:.fig=.eps)
FIG_PDF := $(FIG_SRC:.fig=.pdf)

GNUPLOT_DAT := $(GNUPLOT_SRC:.gp=.dat)
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



EXTRA_O   := $(EXTRA_CC:.cc=.o)
EXTRA_OCT := $(EXTRA_CC:.cc=.oct)

## The parts of the figures we create.  The PDF parts will be
## generated automatically by the rules in epstopdf.sty.  They are
## listed here so we can use them in the clean rules.

TEX_PARTS := $(FIG_TEX) $(GNUPLOT_TEX) $(OCTAVE_TEX) $(CUSTOM_TEX) $(TABLE_TEX) 
EPS_PARTS := $(FIG_EPS) $(GNUPLOT_EPS) $(OCTAVE_EPS) $(CUSTOM_EPS) 
PDF_PARTS := $(FIG_PDF) $(GNUPLOT_PDF) $(OCTAVE_PDF) $(EXTRA_PDF) 

## This ugly mess searches the main paper file for a \bibliography
## command and extracts the names of the .bib files.

BIB_SRC := $(foreach f, $(addsuffix .bib, $(shell sed -n '/^\\bibliography{/ { s/\\bibliography{\([^}]*\)}/\1/; s/,/ /g; p; q }' $(PAPER_SRC))), $(shell kpsewhich $f))

## The list of all the files that should go in the tar file.

DISTFILES := bibextract latex2pdf Makefile \
  $(PAPER_SRC) $(PAPER_XBIB) \
  $(FIG_SRC) $(GNUPLOT_SRC) $(OCTAVE_SRC) $(OCTAVE_GP) \
  $(CUSTOM_OCT) $(CUSTOM_GP) $(EXTRA_EPS) $(EXTRA_JPG) $(DIST_DAT)

## The name of the collection of files we will distribute.

PACKAGE := sample-docs

## The version number for the tar file.

VERSION := 0.1

## The first target is the one that will be made by default (by typing
## "make" with no target arguments).  The traditional name for the default
## target is "all".



all: $(PAPER_PDF)
.PHONY: all




$(PAPER_PDF) $(PAPER_AUX): $(PAPER_SRC) $(TEX_PARTS) $(PDF_PARTS) $(EXTRA_JPG) $(BIB_SRC) presentationLooks.tex $(CUSTOM_PDF) $(GNUPLOT_DAT) $(CUSTOM.JPEG) IP_dem.dat
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


## A way to extract entries from the shared BibTeX data bases and
## create a local database just for this document.

$(PAPER_XBIB): $(PAPER_AUX) $(BIB_SRC)
	-./bibextract $(PAPER_AUX) > $(PAPER_XBIB)






