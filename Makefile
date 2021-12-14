
all: nif comparisons

nif: priv/lib/cp_model_builder.so

comparisons: priv/lib/simple_sat_program_bool

priv/lib/cp_model_builder.so: c_src/cp_model_builder.cc
	clang++ \
		-I ~/.asdf/installs/erlang/24.1.7/usr/include \
		-std=c++17 \
		-dynamiclib -undefined dynamic_lookup \
		-lortools \
		-o priv/lib/cp_model_builder.so -fPIC c_src/cp_model_builder.cc

priv/lib/simple_sat_program_bool: c_src/simple_sat_program_bool.cc
	clang++ \
		-I ~/.asdf/installs/erlang/24.1.7/usr/include \
		-std=c++17 \
		-lortools \
		-o priv/lib/simple_sat_program_bool c_src/simple_sat_program_bool.cc

clean:
	rm priv/lib/cp_model_builder.so
