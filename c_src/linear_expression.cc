#include <cstring>
#include "erl_nif.h"
#include "ortools/sat/cp_model.h"
#include "wrappers.h"

using operations_research::sat::LinearExpr;

extern "C"
{
  ErlNifResourceType *LINEAR_EXPR_WRAPPER;
  ErlNifResourceType *INT_VAR_WRAPPER;

  void free_linear_expr(ErlNifEnv *env, void *obj)
  {
    LinearExprWrapper *w = (LinearExprWrapper *)obj;
    delete w->p;
  }

  void free_int_var(ErlNifEnv *env, void *obj)
  {
    IntVarWrapper *w = (IntVarWrapper *)obj;
    delete w->p;
  }

  static int init_types(ErlNifEnv *env)
  {
    LINEAR_EXPR_WRAPPER = enif_open_resource_type(env, NULL, "LinearExprWrapper", free_linear_expr, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);

    INT_VAR_WRAPPER = enif_open_resource_type(env, NULL, "IntVarWrapper", free_int_var, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);

    return 0;
  }

  static int load(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info)
  {
    if (init_types(env) == -1)
      return -1;
    else
      return 0;
  }

  static ERL_NIF_TERM sum_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    IntVarWrapper *var1;
    IntVarWrapper *var2;
    ERL_NIF_TERM term;

    fprintf(stderr, "about to grab vars\n");

    if (!enif_get_resource(env, argv[0], INT_VAR_WRAPPER, (void **)&var1))
    {
      return enif_make_badarg(env);
    }
    fprintf(stderr, "got first\n");

    if (!enif_get_resource(env, argv[1], INT_VAR_WRAPPER, (void **)&var2))
    {
      return enif_make_badarg(env);
    }
    fprintf(stderr, "got second\n");

    LinearExprWrapper *linear_expr_wrapper = (LinearExprWrapper *)enif_alloc_resource(LINEAR_EXPR_WRAPPER, sizeof(LinearExprWrapper));
    if (linear_expr_wrapper == NULL)
      return enif_make_badarg(env);

    linear_expr_wrapper->p = new LinearExpr(LinearExpr::Sum({*var1->p, *var2->p}));
    term = enif_make_resource(env, linear_expr_wrapper);
    enif_release_resource(linear_expr_wrapper);

    return term;
  }

  static ErlNifFunc nif_funcs[] = {
      {"sum_nif", 2, sum_nif}};

  ERL_NIF_INIT(Elixir.LinearExpression, nif_funcs, &load, NULL, NULL, NULL)
}
