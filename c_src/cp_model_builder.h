#ifndef __CP_MODEL_BUILDER_H__
#define __CP_MODEL_BUILDER_H__

#include "erl_nif.h"

extern "C"
{
  int load_cp_model_builder(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info);

  ERL_NIF_TERM new_builder_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM new_bool_var_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM new_int_var_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM new_constant_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM new_interval_var_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM new_optional_interval_var_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_abs_equal_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_abs_equal_constant_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_all_different_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_decision_strategy_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_implication_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_bool_and_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_bool_or_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_no_overlap_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_equal_int_var_plus_int_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_equal_expr1_expr2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_equal_expr1_constant2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_equal_int_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_not_equal_expr1_expr2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_not_equal_bool_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_greater_or_equal_expr1_expr2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_greater_than_expr1_expr2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_less_than_expr1_expr2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_less_or_equal_expr1_expr2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM only_enforce_if_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM solve_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM solve_with_callback_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM solution_bool_value_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM solution_integer_value_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_max_equality_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_minimize_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

  ERL_NIF_TERM add_maximize_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);
}

#endif
