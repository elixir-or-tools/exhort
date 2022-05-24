
all: nifs

nifs: priv/lib/nif.so

ORTOOLS ?= /usr/local
ERLANG_HOME ?= /usr/local

INCLUDES=-I$(ERLANG_HOME)/usr/include -I$(ORTOOLS)/include
LIBPATH=-L$(ERLANG_HOME)/usr/lib -L$(ORTOOLS)/lib
CFLAGS=-std=c++17
LIBS=-lortools
SRC=$(wildcard c_src/*.cc)

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	SOFLAGS=-fPIC -shared -Wl,-rpath=$(ORTOOLS)/lib -Wl,-rpath=$(ERLANG_HOME)/usr/lib
endif
ifeq ($(UNAME_S),Darwin)
	SOFLAGS=-dynamiclib -undefined dynamic_lookup -fPIC
endif

priv/lib/nif.so: $(SRC)
	@mkdir -p $(@D)
	$(CC) $(INCLUDES) $(CFLAGS) $(SOFLAGS) -o priv/lib/nif.so $(SRC) $(LIBPATH) $(LIBS)

clean:
	rm -f priv/lib/*.so