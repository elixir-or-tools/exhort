
all: nifs

nifs: priv/lib/nif.so

INCLUDES=-I ~/.asdf/installs/erlang/24.1.7/usr/include
CFLAGS=-std=c++17
SOFLAGS=-dynamiclib -undefined dynamic_lookup -fPIC
LIBS=-lortools
SRC=$(wildcard c_src/*.cc)

priv/lib/nif.so: $(SRC)
	clang++ $(INCLUDES) $(CFLAGS) $(SOFLAGS) $(LIBS) -o priv/lib/nif.so $(SRC)

clean:
	rm priv/lib/*.so
