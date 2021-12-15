
all: nifs

nifs: priv/lib/nif.so

INCLUDES=-I ~/.asdf/installs/erlang/24.1.7/usr/include
CFLAGS=-std=c++17
SOFLAGS=-dynamiclib -undefined dynamic_lookup -fPIC
LIBS=-lortools

priv/lib/nif.so: c_src/nif.cc c_src/cp_model_builder.cc c_src/linear_expression.cc c_src/int_var.cc
	clang++ $(INCLUDES) $(CFLAGS) $(SOFLAGS) $(LIBS) -o priv/lib/nif.so c_src/nif.cc c_src/cp_model_builder.cc c_src/linear_expression.cc c_src/int_var.cc

clean:
	rm priv/lib/*.so
