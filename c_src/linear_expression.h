#ifndef __LINEAR_EXPRESSION_H__
#define __LINEAR_EXPRESSION_H__

#include "erl_nif.h"
#include "wrappers.h"

extern "C"
{
  int load_linear_expression(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info);

  ERL_NIF_TERM prod_expr1_constant2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM prod_bool_var1_constant2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM prod_int_var1_constant2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM sum_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM minus_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  int get_linear_expression(ErlNifEnv *env, ERL_NIF_TERM term, LinearExprWrapper **obj);

  ERL_NIF_TERM expr_from_int_var_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM expr_from_bool_var_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM expr_from_constant_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);
}

#endif
