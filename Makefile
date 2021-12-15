
all: nifs comparisons

nifs: priv/lib/cp_model_builder.so priv/lib/linear_expression.so

comparisons: priv/lib/simple_sat_program_bool

INCLUDES=-I ~/.asdf/installs/erlang/24.1.7/usr/include
CFLAGS=-std=c++17
SOFLAGS=-dynamiclib -undefined dynamic_lookup -fPIC
LIBS=-lortools

priv/lib/cp_model_builder.so: c_src/cp_model_builder.cc
	clang++ $(INCLUDES) $(CFLAGS) $(SOFLAGS) $(LIBS) -o priv/lib/cp_model_builder.so c_src/cp_model_builder.cc

priv/lib/linear_expression.so: c_src/linear_expression.cc
	clang++ $(INCLUDES) $(CFLAGS) $(SOFLAGS) $(LIBS) -o priv/lib/linear_expression.so c_src/linear_expression.cc

priv/lib/simple_sat_program_bool: c_src/simple_sat_program_bool.cc
	clang++ $(INCLUDES) $(CFLAGS) $(LIBS) -o priv/lib/simple_sat_program_bool c_src/simple_sat_program_bool.cc

clean:
	rm priv/lib/*.so
