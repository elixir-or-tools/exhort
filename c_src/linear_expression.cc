#include <cstring>
#include "erl_nif.h"
#include "ortools/sat/cp_model.h"
#include "wrappers.h"
#include "bool_var.h"
#include "int_var.h"

using operations_research::Domain;
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

  ERL_NIF_TERM expr_from_int_var_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    IntVarWrapper *var1;

    if (!get_int_var(env, argv[0], &var1))
    {
      return enif_make_badarg(env);
    }

    LinearExprWrapper *linear_expr_wrapper = (LinearExprWrapper *)enif_alloc_resource(LINEAR_EXPR_WRAPPER, sizeof(LinearExprWrapper));
    if (linear_expr_wrapper == NULL)
      return enif_make_badarg(env);

    linear_expr_wrapper->p = new LinearExpr(*var1->p);
    ERL_NIF_TERM term = enif_make_resource(env, linear_expr_wrapper);
    enif_release_resource(linear_expr_wrapper);

    return term;
  }

  ERL_NIF_TERM expr_from_bool_var_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BoolVarWrapper *var1;

    if (!get_bool_var(env, argv[0], &var1))
    {
      return enif_make_badarg(env);
    }

    LinearExprWrapper *linear_expr_wrapper = (LinearExprWrapper *)enif_alloc_resource(LINEAR_EXPR_WRAPPER, sizeof(LinearExprWrapper));
    if (linear_expr_wrapper == NULL)
      return enif_make_badarg(env);

    linear_expr_wrapper->p = new LinearExpr(*var1->p);
    ERL_NIF_TERM term = enif_make_resource(env, linear_expr_wrapper);
    enif_release_resource(linear_expr_wrapper);

    return term;
  }

  ERL_NIF_TERM expr_from_constant_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    long var1;

    if (!enif_get_int64(env, argv[0], &var1))
    {
      return enif_make_badarg(env);
    }

    LinearExprWrapper *linear_expr_wrapper = (LinearExprWrapper *)enif_alloc_resource(LINEAR_EXPR_WRAPPER, sizeof(LinearExprWrapper));
    if (linear_expr_wrapper == NULL)
      return enif_make_badarg(env);

    linear_expr_wrapper->p = new LinearExpr(var1);
    ERL_NIF_TERM term = enif_make_resource(env, linear_expr_wrapper);
    enif_release_resource(linear_expr_wrapper);

    return term;
  }

  ERL_NIF_TERM sum_expr1_expr2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    LinearExprWrapper *expr1;
    LinearExprWrapper *expr2;

    if (!get_linear_expression(env, argv[0], &expr1))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[1], &expr2))
    {
      return enif_make_badarg(env);
    }

    LinearExprWrapper *linear_expr_wrapper = (LinearExprWrapper *)enif_alloc_resource(LINEAR_EXPR_WRAPPER, sizeof(LinearExprWrapper));
    if (linear_expr_wrapper == NULL)
      return enif_make_badarg(env);

    linear_expr_wrapper->p = new LinearExpr(*expr1->p + *expr2->p);
    ERL_NIF_TERM term = enif_make_resource(env, linear_expr_wrapper);
    enif_release_resource(linear_expr_wrapper);

    return term;
  }

  ERL_NIF_TERM sum_exprs_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    const ERL_NIF_TERM *vars;
    int arity;

    if (!enif_get_tuple(env, argv[0], &arity, &vars))
    {
      return enif_make_badarg(env);
    }

    std::vector<BoolVar> bool_vars(arity);
    for (int i = 0; i < arity; i++)
    {
      BoolVarWrapper *bvw;
      get_bool_var(env, vars[i], &bvw);
      BoolVar bv = *bvw->p;
      bool_vars.push_back(bv);
    }

    LinearExprWrapper *linear_expr_wrapper = (LinearExprWrapper *)enif_alloc_resource(LINEAR_EXPR_WRAPPER, sizeof(LinearExprWrapper));
    if (linear_expr_wrapper == NULL)
      return enif_make_badarg(env);

    linear_expr_wrapper->p = new LinearExpr(LinearExpr::Sum(absl::Span<const BoolVar> (bool_vars)));
    ERL_NIF_TERM term = enif_make_resource(env, linear_expr_wrapper);
    enif_release_resource(linear_expr_wrapper);

    return term;
  }

  ERL_NIF_TERM minus_expr1_expr2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    LinearExprWrapper *expr1;
    LinearExprWrapper *expr2;

    if (!get_linear_expression(env, argv[0], &expr1))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[1], &expr2))
    {
      return enif_make_badarg(env);
    }

    LinearExprWrapper *linear_expr_wrapper = (LinearExprWrapper *)enif_alloc_resource(LINEAR_EXPR_WRAPPER, sizeof(LinearExprWrapper));
    if (linear_expr_wrapper == NULL)
      return enif_make_badarg(env);

    linear_expr_wrapper->p = new LinearExpr(*expr1->p - *expr2->p);
    ERL_NIF_TERM term = enif_make_resource(env, linear_expr_wrapper);
    enif_release_resource(linear_expr_wrapper);

    return term;
  }

  ERL_NIF_TERM prod_int_var1_constant2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    IntVarWrapper *var1;
    int int2;
    ERL_NIF_TERM term;

    if (!get_int_var(env, argv[0], &var1))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_int(env, argv[1], &int2))
    {
      return enif_make_badarg(env);
    }

    LinearExprWrapper *linear_expr_wrapper = (LinearExprWrapper *)enif_alloc_resource(LINEAR_EXPR_WRAPPER, sizeof(LinearExprWrapper));
    if (linear_expr_wrapper == NULL)
      return enif_make_badarg(env);

    linear_expr_wrapper->p = new LinearExpr(LinearExpr::ScalProd({*var1->p}, {int2}));
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
