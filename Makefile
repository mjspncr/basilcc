## to build must have these vars set (to build from any src dir set these vars in your env)

# this directory
export ROOT ?= $(PWD)
# maketools directory, make.include is in here
export MAKETOOLS ?= $(ROOT)/maketools
# target build, must have make.$CONFIG in maketools, gcc or i386-mingw32
export CONFIG ?= gcc
# need lzz to build lzz
export LZZ ?= lzz

SUBDIRS=src
include $(MAKETOOLS)/make.include

# for install under /usr/local, must BUILD=OPT first and run as su
LUADIR := $(ROOT)/lua
LUAFILES := $(wildcard $(LUADIR)/basilcc/*.lua)
INSTALL_LUADIR := /usr/local/share/lua/5.3
INSTALL_LUAFILES := $(LUAFILES:$(LUADIR)/%=$(INSTALL_LUADIR)/%)
BINFILE := $(ROOT)/build.gcc/bin/basilcc_opt
INSTALL_BINFILE := /usr/local/bin/basilcc
LIBFILE := $(ROOT)/build.gcc/lib/libbasil_opt.a
INSTALL_LIBFILE := /usr/local/lib/libbasil.a

## todo : copy basil include files to /usr/local/include/basil (first add basil_ prefix) 

install: $(INSTALL_LUAFILES) $(INSTALL_BINFILE) $(INSTALL_LIBFILE)

$(INSTALL_LUADIR)/%: $(LUADIR)/%
	luac -o $@ $<

$(INSTALL_BINFILE): $(BINFILE)
	strip -o $@ $<

$(INSTALL_LIBFILE): $(LIBFILE)
	cp $< $@
