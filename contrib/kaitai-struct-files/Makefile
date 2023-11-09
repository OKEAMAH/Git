KSYS:=$(shell find . -name \*.ksy -print)
HTMLS:=$(patsubst %.ksy,doc/%.html,$(KSYS))
RSS:=$(patsubst %.ksy,rust/src/%.rs,$(KSYS))
JSS:=$(patsubst %.ksy,javascript/src/%.js,$(KSYS))
CPPS:=$(patsubst %.ksy,cpp/src/%.cpp,$(KSYS))

all: $(HTMLS) $(RSS) $(JSS) $(CPPS)

doc/:
	mkdir -p doc/

doc/%.html: %.ksy doc/
	kaitai-struct-compiler -t html $< --outdir=doc/

rust/src/%.rs: %.ksy
	kaitai-struct-compiler -t rust $< --outdir=rust/src/

javascript/src/%.js: %.ksy
	kaitai-struct-compiler -t javascript $< --outdir=javascript/src/

cpp/src/%.cpp: %.ksy
	kaitai-struct-compiler -t cpp_stl $< --outdir=cpp/src/
