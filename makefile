## to build must have these vars set (to build from any src dir set these vars in your env)

# this directory
export ROOT ?= $(PWD)
# maketools directory, make.include is in here
export MAKETOOLS ?= $(ROOT)/maketools
# target build, must have make.$CONFIG in maketools, gcc or i386-mingw32
export CONFIG ?= gcc
# need lzz to build lzz
export LZZ ?= lzz

#export INCDIRS=$(HOME)/local/lua-5.3.5/include
#export MORELIBDIRS=$(HOME)/local/lua-5.3.5/lib

SUBDIRS=src
include $(MAKETOOLS)/make.include
