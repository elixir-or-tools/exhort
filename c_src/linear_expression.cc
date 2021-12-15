#include <cstring>
#include "erl_nif.h"
#include "ortools/sat/cp_model.h"
#include "wrappers.h"
#include "int_var.h"

using operations_research::sat::LinearExpr;

extern "C"
{
  ErlNifResourceType *LINEAR_EXPR_WRAPPER;

  static void free_linear_expr(ErlNifEnv *env, void *obj)
  {
    LinearExprWrapper *w = (LinearExprWrapper *)obj;
    delete w->p;
  }

  static int init_types(ErlNifEnv *env)
  {
    LINEAR_EXPR_WRAPPER = enif_open_resource_type(env, NULL, "LinearExprWrapper", free_linear_expr, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);

    return 0;
  }

  int get_linear_expression(ErlNifEnv *env, ERL_NIF_TERM term, LinearExprWrapper **obj)
  {
    return enif_get_resource(env, term, LINEAR_EXPR_WRAPPER, (void **)obj);
  }

  ERL_NIF_TERM sum_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    IntVarWrapper *var1;
    IntVarWrapper *var2;
    ERL_NIF_TERM term;

    if (!get_int_var(env, argv[0], &var1))
    {
      return enif_make_badarg(env);
    }

    if (!get_int_var(env, argv[1], &var2))
    {
      return enif_make_badarg(env);
    }

    LinearExprWrapper *linear_expr_wrapper = (LinearExprWrapper *)enif_alloc_resource(LINEAR_EXPR_WRAPPER, sizeof(LinearExprWrapper));
    if (linear_expr_wrapper == NULL)
      return enif_make_badarg(env);

    linear_expr_wrapper->p = new LinearExpr(LinearExpr::Sum({*var1->p, *var2->p}));
    term = enif_make_resource(env, linear_expr_wrapper);
    enif_release_resource(linear_expr_wrapper);

    return term;
  }

  int load_linear_expression(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info)
  {
    if (init_types(env) == -1)
      return -1;
    else
      return 0;
  }
}
