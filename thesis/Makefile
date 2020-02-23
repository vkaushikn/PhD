TOPDIR := $(shell pwd)


EPSTOPDF := epstopdf
PDFVIEWER := evince

TEXSUFFIXES := .pdf .aux .log .bbl .blg .out .spl .lof .lot .toc

PAPER_SRC  := thesis.tex
PAPER      := $(basename $(PAPER_SRC))
PAPER_PDF  := $(addsuffix .pdf, $(PAPER))
PAPER_AUX  := $(addsuffix .aux, $(PAPER))
PAPER_XBIB := $(addsuffix .xbib, $(PAPER))
PAPER_MISC := $(addprefix $(PAPER), $(TEXSUFFIXES))
TEX_MISC   := notation.tex prelude.tex
AUX_MISC   := notation.aux prelude.aux
## Directories of figures

EXTERNAL := \
	scheduling\
	mpc\
	sc\
	esc\


## This ugly mess searches the main paper file for a \bibliography
## command and extracts the names of the .bib files.

BIB_SRC := $(foreach f, $(addsuffix .bib, $(shell sed -n '/^\\bibliography{/ { s/\\bibliography{\([^}]*\)}/\1/; s/,/ /g; p; q }' $(PAPER_SRC))), $(shell kpsewhich $f))

## The list of all the files that should go in the tar file.

DISTFILES := bibextract latex2pdf Makefile \
  $(PAPER_SRC) $(PAPER_XBIB) \
  $(FIG_SRC) $(GNUPLOT_SRC) $(OCTAVE_SRC) $(OCTAVE_GP) $(TABLE_SRC)\
  $(CUSTOM_OCT) $(CUSTOM_GP) $(EXTRA_EPS) $(EXTRA_JPG)

## The name of the collection of files we will distribute.

PACKAGE := subramanian_thesis

## The version number for the tar file.

VERSION := 0.1

## The first target is the one that will be made by default (by typing
## "make" with no target arguments).  The traditional name for the default
## target is "all".

all: $(PAPER_PDF)
.PHONY: all

$(PAPER_PDF) $(PAPER_AUX): figures \
	$(PAPER_SRC) $(BIB_SRC)
	./latex2pdf $(PAPER_SRC)

view: $(PAPER_PDF)
	$(PDFVIEWER) $(PAPER_PDF) &
.PHONY: view

clean:
	rm -f $(PAPER_MISC)
	rm -f $(AUX_MISC)
	## Clean up external directories
	for dir in $(EXTERNAL); do \
	$(MAKE)	-C $$dir clean; \
	rm -f $$dir/*.aux; \
	done
.PHONY: clean

realclean: clean
	rm -f $(OCTAVE_DAT) $(PAPER_XBIB) $(CUSTOM_DAT) $(EXTRA_OCT)
	rm -f *~
	## Clean up external directories
	for dir in $(EXTERNAL); do \
	$(MAKE)	-C $$dir realclean; \
	done
.PHONY: realclean



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

## Make external figure directories
figures: $(EXTERNAL)

$(EXTERNAL):	
	$(MAKE) -C $@
.PHONY: figures $(EXTERNAL)


