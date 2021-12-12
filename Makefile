
all: nif

nif: priv/lib/cp_model_builder.so

priv/lib/cp_model_builder.so: c_src/cp_model_builder.cc
	clang++ \
		-I ~/.asdf/installs/erlang/24.1.7/usr/include \
		-std=c++17 \
		-dynamiclib -undefined dynamic_lookup \
		-lortools \
		-o priv/lib/cp_model_builder.so -fPIC c_src/cp_model_builder.cc

clean:
	rm priv/lib/cp_model_builder.so
