OCAMLBUILD := ocamlbuild -cflag "-dtypes"
all:
	$(OCAMLBUILD) dev_save.cmx

clean:
	$(OCAMLBUILD) -clean

doc:
	$(OCAMLBUILD) dvi.docdir/index.html
