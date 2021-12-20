#ifndef __INTERVAL_VAR_H__
#define __INTERVAL_VAR_H__

#include "erl_nif.h"
#include "wrappers.h"

extern "C"
{
  int load_interval_var(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info);

  int get_interval_var(ErlNifEnv *env, ERL_NIF_TERM term, IntervalVarWrapper **obj);

  ERL_NIF_TERM make_interval_var(ErlNifEnv *env, IntervalVar &from_var);
}

#endif
