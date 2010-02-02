##########################################################################
#                                                                        #
#  Copyright (C) Johannes Kanig, Stephane Lescuyer                       #
#  Jean-Christophe Filliatre, Romain Bardou and Francois Bobot           #
#                                                                        #
#  This software is free software; you can redistribute it and/or        #
#  modify it under the terms of the GNU Library General Public           #
#  License version 2.1, with the special exception on linking            #
#  described in file LICENSE.                                            #
#                                                                        #
#  This software is distributed in the hope that it will be useful,      #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                  #
#                                                                        #
##########################################################################


TESTS = handbookgraphs.cmx othergraphs.cmx tests.cmx
TOOL = tool.$(OCAMLBEST)

all: byte $(OCAMLBEST) $(TOOL)

check: byte $(OCAMLBEST) $(TOOL) $(TESTS) check-examples

# bytecode and native-code compilation
######################################

CMO := misc.cmo name.cmo compiled_types.cmo hashcons.cmo types.cmo \
	print.cmo num.cmo point.cmo duplicate.cmo compile.cmo \
       transform.cmo color.cmo metaPath.cmo path.cmo picture.cmo \
       dash.cmo pen.cmo brush.cmo command.cmo shapes.cmo \
	box.cmo arrow.cmo helpers.cmo diag.cmo tree.cmo tree_adv.cmo \
	radar.cmo plot.cmo hist.cmo legend.cmo \
       scan_prelude.cmo metapost_tool.cmo metapost.cmo generate.cmo cairost.cmo concrete.cmo
CMX := $(CMO:.cmo=.cmx)

CMA := mlpost.cma
CMXA := mlpost.cmxa

HANDBOOKCMO := handbookgraphs.cmo
OTHERCMO := othergraphs.cmo
TESTSCMO := tests.cmo
HANDBOOKCMX := $(HANDBOOKCMO:.cmo=.cmx)
OTHERCMX := $(OTHERCMO:.cmo=.cmx)

$(HANDBOOKCMX) $(OTHERCMX): $(CMXA)

GENERATED = scan_prelude.ml gui/glexer.ml concrete.ml cairost.ml

byte: $(CMA)
opt: $(CMXA)

$(CMA): mlpost.cmo
	$(OCAMLC) -a $(BFLAGS) -o $@ $^

$(CMXA): mlpost.cmx
	$(OCAMLOPT) -a $(OFLAGS) -o $@ $^

mlpost.cmo: mlpost.cmi
mlpost.cmo: $(CMO)
	$(OCAMLC) $(INCLUDES) -pack -o $@ $(CMO)

mlpost.cmx: mlpost.cmi
mlpost.cmx: $(CMX)
	$(OCAMLOPT) $(INCLUDES) -pack -o $@ $(CMX)

TOOLCMO= version.cmo scan_prelude.cmo metapost_tool.cmo misc.cmo tool.cmo
TOOLCMX := $(TOOLCMO:.cmo=.cmx)

tool.byte: $(TOOLCMO)
	$(OCAMLC) -o $@ unix.cma $^

tool.opt: $(TOOLCMX)
	$(OCAMLOPT) -o $@ unix.cmxa $^

cairost.ml : cairost_no.ml
	cp -f $^ $@

concrete.ml : concrete_no.ml
	cp -f $^ $@

tests: $(CMXA) tests.ml
	$(OCAMLOPT) -o tests.exe unix.cmxa $(CMXA) tests.ml
	./tests.exe
	make -C test tests
	$(PSVIEWER) test/tests.ps

testbox: $(CMXA) testbox.ml
	$(OCAMLOPT) -o testbox.exe unix.cmxa $(CMXA) testbox.ml
	./testbox.exe
	make -C test testbox
	$(PSVIEWER) test/testbox.ps

tests.pdf: $(CMXA) tests.ml
	$(OCAMLOPT) -o tests.exe unix.cmxa $(CMXA) tests.ml
	./tests.exe
	make -C test tests.pdf
	$(PDFVIEWER) test/tests.pdf


tests.byte: $(CMA) tests.ml
	ocaml unix.cma $(CMA) tests.ml
	make -C test tests
	$(PSVIEWER) test/tests.ps

handbook: $(CMXA) handbookgraphs.ml
	$(OCAMLOPT) -o handbook.exe unix.cmxa $(CMXA) handbookgraphs.ml
	./handbook.exe
	make -C test manual
	make -C test/manual mpost
	$(PDFVIEWER) test/testmanual.pdf

handbook.byte: $(CMA) handbookgraphs.ml
	ocaml unix.cma $(CMA) handbookgraphs.ml
	make -C test manual
	make -C test/manual mpost
	$(PDFVIEWER) test/testmanual.pdf

other: $(CMXA) othergraphs.ml
	$(OCAMLOPT) -o othergraphs.exe unix.cmxa $(CMXA) othergraphs.ml
	./othergraphs.exe
	make -C test other
	make -C test/othergraphs mpost
	$(PSVIEWER) test/othergraphs.ps

other.byte: $(CMA) othergraphs.ml
	ocaml unix.cma $(CMA) othergraphs.ml
	make -C test other
	make -C test/othergraphs mpost
	$(PSVIEWER) test/othergraphs.ps

.PHONY: check-examples examples
SUBDIRMLPOST:=../tool.opt -ccopt "-I ../ " -v -ps
MAKEEXAMPLES=make -C examples MLPOST='$(SUBDIRMLPOST)'

check-examples: mlpost.cma tool.opt
	$(MAKEEXAMPLES) boxes.dummy
	$(MAKEEXAMPLES) paths.dummy
	$(MAKEEXAMPLES) tree.dummy
	$(MAKEEXAMPLES) label.dummy
	make -C multi-examples

examples:
	$(MAKEEXAMPLES)

examples-html:
	$(MAKEEXAMPLES) html

# GUI

.PHONY: gui doc

gui: gui/gmlpost.opt

GUICMO = gui/glexer.cmo gui/gmlpost.cmo
GUICMX := $(GUICMO:.cmo=.cmx)

gui/gmlpost.opt: $(GUICMX)
	$(OCAMLOPT) $(OFLAGS) -o $@ unix.cmxa threads.cmxa lablgtk.cmxa gtkThread.cmx lablgnomecanvas.cmxa $^

gui/gmlpost.byte: $(GUICMO)
	$(OCAMLC) $(BFLAGS) -o $@ unix.cma lablgtk.cma threads.cma gtkThread.cmo $^

doc:
	@echo "The doc can be generated only with ocamlbuild (ocaml >=3.10.2)"

# generic rules
###############

.SUFFIXES: .mli .ml .cmi .cmo .cmx .mll .mly .tex .dvi .ps .html

.mli.cmi:
	$(OCAMLC) -c $(BFLAGS) $<

.ml.cmo:
	$(OCAMLC) -c $(BFLAGS) $<

.ml.o:
	$(OCAMLOPT) -c $(OFLAGS) $<

.ml.cmx:
	$(OCAMLOPT) -c $(OFLAGS) $<

.mll.ml:
	$(OCAMLLEX) $<

.mly.ml:
	$(OCAMLYACC) -v $<

.mly.mli:
	$(OCAMLYACC) -v $<

.tex.dvi:
	latex $< && latex $<

.dvi.ps:
	dvips $< -o $@ 

.tex.html:
	hevea $<


# clean
#######

clean::
	rm -f *.cm[iox] *.o *~ *.annot
	rm -f $(GENERATED) parser.output
	rm -f $(NAME).cma $(NAME).cmxa $(NAME).a
	rm -f *.aux *.log $(NAME).tex $(NAME).dvi $(NAME).ps
	rm -f *.opt *.byte test.dvi test.ps *.exe

cleaner:: clean
	make -C test clean
	make -C multi-examples clean
	make -C www clean
	rm -rf doc
	make -C examples clean

dist-clean distclean:: clean
	rm -f Makefile config.cache config.log config.status META version.ml

# depend
########

.depend depend:: $(GENERATED)
	rm -f .depend
	$(OCAMLDEP) $(INCLUDES) *.ml *.mli gui/*.mli gui/*.ml > .depend

include .depend