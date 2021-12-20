#ifndef __BOOL_VAR_H__
#define __BOOL_VAR_H__

#include "erl_nif.h"
#include "wrappers.h"

extern "C"
{
  int load_bool_var(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info);

  int get_bool_var(ErlNifEnv *env, ERL_NIF_TERM term, BoolVarWrapper **obj);

  ERL_NIF_TERM make_bool_var(ErlNifEnv *env, BoolVar &from_bool_var);
}

#endif
