#include <cstring>
#include "erl_nif.h"
#include "ortools/sat/cp_model.h"
#include "wrappers.h"
#include "cp_model_builder.h"
#include "linear_expression.h"
#include "int_var.h"
#include "cp_solver_response.h"

extern "C"
{
  static int load(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info)
  {
    load_cp_model_builder(env, priv, load_info);
    load_linear_expression(env, priv, load_info);
    load_int_var(env, priv, load_info);
    load_cp_solver_response(env, priv, load_info);

    return 0;
  }

  static ErlNifFunc nif_funcs[] = {
      {"add_equal_expr_nif", 3, add_equal_expr_nif},
      {"add_equal_int_nif", 3, add_equal_int_nif},
      {"add_not_equal_int_nif", 3, add_not_equal_int_nif},
      {"add_equal_int_constant_nif", 3, add_equal_int_constant_nif},
      {"add_equal_bool_nif", 3, add_equal_bool_nif},
      {"add_not_equal_bool_nif", 3, add_not_equal_bool_nif},
      {"add_greater_or_equal_nif", 3, add_greater_or_equal_nif},
      {"add_less_nif", 3, add_less_nif},
      {"add_less_or_equal_nif", 3, add_less_or_equal_nif},
      {"new_bool_var_nif", 2, new_bool_var_nif},
      {"new_int_var_nif", 4, new_int_var_nif},
      {"new_builder_nif", 0, new_builder_nif},
      {"bool_not_nif", 1, bool_not_nif},
      {"solution_integer_value_nif", 2, solution_integer_value_nif},
      {"solution_bool_value_nif", 2, solution_bool_value_nif},
      {"solve_nif", 1, solve_nif},
      {"solve_with_callback_nif", 2, solve_with_callback_nif},
      {"sum_nif", 2, sum_nif}};

  ERL_NIF_INIT(Elixir.Exhort.NIF.Nif, nif_funcs, &load, NULL, NULL, NULL)
}
