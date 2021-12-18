#ifndef __CP_SOLVER_RESPONSE_H__
#define __CP_SOLVER_RESPONSE_H__

#include "erl_nif.h"
#include "wrappers.h"

extern "C"
{
  int load_cp_solver_response(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info);

  int get_cp_solver_response(ErlNifEnv *env, ERL_NIF_TERM term, CpSolverResponseWrapper **obj);

  ERL_NIF_TERM make_cp_solver_response(ErlNifEnv *env, const CpSolverResponse &from_int_var);
}

#endif
