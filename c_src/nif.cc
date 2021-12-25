#include <cstring>
#include "erl_nif.h"
#include "ortools/sat/cp_model.h"
#include "wrappers.h"
#include "cp_model_builder.h"
#include "linear_expression.h"
#include "bool_var.h"
#include "int_var.h"
#include "interval_var.h"
#include "cp_solver_response.h"

extern "C"
{
  static int load(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info)
  {
    load_cp_model_builder(env, priv, load_info);
    load_linear_expression(env, priv, load_info);
    load_bool_var(env, priv, load_info);
    load_int_var(env, priv, load_info);
    load_interval_var(env, priv, load_info);
    load_cp_solver_response(env, priv, load_info);

    return 0;
  }

  static ErlNifFunc nif_funcs[] = {
      {"add_abs_equal_nif", 3, add_abs_equal_nif},
      {"add_abs_equal_constant_nif", 3, add_abs_equal_constant_nif},
      {"add_all_different_nif", 2, add_all_different_nif},
      {"add_no_overlap_nif", 2, add_no_overlap_nif},
      {"add_equal_expr1_expr2_nif", 3, add_equal_expr1_expr2_nif},
      {"add_equal_expr1_constant2_nif", 3, add_equal_expr1_constant2_nif},
      {"add_equal_int_nif", 3, add_equal_int_nif},
      {"add_greater_or_equal_expr1_expr2_nif", 3, add_greater_or_equal_expr1_expr2_nif},
      {"add_greater_than_expr1_expr2_nif", 3, add_greater_than_expr1_expr2_nif},
      {"add_max_equality_nif", 3, add_max_equality_nif},
      {"add_minimize_nif", 2, add_minimize_nif},
      {"add_less_than_expr1_expr2_nif", 3, add_less_than_expr1_expr2_nif},
      {"add_less_or_equal_expr1_expr2_nif", 3, add_less_or_equal_expr1_expr2_nif},
      {"add_not_equal_expr1_expr2_nif", 3, add_not_equal_expr1_expr2_nif},
      {"add_not_equal_bool_nif", 3, add_not_equal_bool_nif},
      {"bool_not_nif", 1, bool_not_nif},
      {"new_bool_var_nif", 2, new_bool_var_nif},
      {"new_builder_nif", 0, new_builder_nif},
      {"new_int_var_nif", 4, new_int_var_nif},
      {"new_interval_var_nif", 5, new_interval_var_nif},
      {"only_enforce_if_nif", 2, only_enforce_if_nif},
      {"solution_bool_value_nif", 2, solution_bool_value_nif},
      {"solution_integer_value_nif", 2, solution_integer_value_nif},
      {"solve_nif", 1, solve_nif, ERL_NIF_DIRTY_JOB_CPU_BOUND},
      {"solve_with_callback_nif", 2, solve_with_callback_nif, ERL_NIF_DIRTY_JOB_CPU_BOUND},
      {"prod_int_var1_constant2_nif", 2, prod_int_var1_constant2_nif},
      {"prod_list1_list2_nif", 2, prod_list1_list2_nif},
      {"sum_expr1_expr2_nif", 2, sum_expr1_expr2_nif},
      {"sum_exprs_nif", 1, sum_exprs_nif},
      {"minus_expr1_expr2_nif", 2, minus_expr1_expr2_nif},
      {"expr_from_int_var_nif", 1, expr_from_int_var_nif},
      {"expr_from_bool_var_nif", 1, expr_from_bool_var_nif},
      {"expr_from_constant_nif", 1, expr_from_constant_nif}};

  ERL_NIF_INIT(Elixir.Exhort.NIF.Nif, nif_funcs, &load, NULL, NULL, NULL)
}
