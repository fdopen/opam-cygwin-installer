.PHONY: all clean distclean strip

OCAMLFLAGS= -g -bin-annot -safe-string -w A-4-39

SOURCES= run.mli run.ml mmkpasswd.mli mmkpasswd.ml
RESULT= mmkpasswd

PACKS = unix containers

all:: nc

clean::
	@rm -f *.a *.o *.cm* cygwin-install.exe *.dll *.so


SYSTEM:=$(shell $(OCAMLFIND) ocamlc -config | awk '/^system:/ {print $$2}')

ifeq ($(SYSTEM),mingw64)
STRIP=x86_64-w64-mingw32-strip
else

ifeq ($(SYSTEM),mingw)
STRIP=i686-w64-mingw32-strip
else
STRIP=strip
endif

endif

strip:: nc
	$(STRIP) --strip-unneeded $(RESULT)$(EXE)

include OCamlMakefile
