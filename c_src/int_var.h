#ifndef __INT_VAR_H__
#define __INT_VAR_H__

#include "erl_nif.h"

extern "C"
{
  int load_int_var(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info);

  int get_int_var(ErlNifEnv *env, ERL_NIF_TERM term, IntVarWrapper **obj);

  ERL_NIF_TERM make_int_var(ErlNifEnv *env, IntVar &from_int_var);
}

#endif
