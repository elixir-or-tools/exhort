#include <cstring>
#include "erl_nif.h"
#include "ortools/sat/cp_model.h"
#include "absl/types/span.h"
#include "wrappers.h"
#include "bool_var.h"
#include "int_var.h"

using absl::MakeSpan;
using absl::Span;
using operations_research::Domain;
using operations_research::sat::LinearExpr;

using namespace std;

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

  int get_int_list(ErlNifEnv *env, ERL_NIF_TERM term, vector<int64_t> **vars)
  {
    unsigned int list_length;
    if (!enif_get_list_length(env, term, &list_length))
    {
      return enif_make_badarg(env);
    }

    vector<int64_t> *list = new std::vector<int64_t>();

    ERL_NIF_TERM head;
    ERL_NIF_TERM tail;
    ERL_NIF_TERM current = term;
    for (int i = 0; i < list_length; ++i)
    {
      if (!enif_get_list_cell(env, current, &head, &tail))
      {
        return enif_make_badarg(env);
      }

      long var;
      if (!enif_get_long(env, head, &var))
      {
        return enif_make_badarg(env);
      }

      list->push_back(var);

      current = tail;
    }

    *vars = list;

    return 1;
  }

  int get_int_var_list(ErlNifEnv *env, ERL_NIF_TERM term, vector<IntVar> **vars)
  {
    unsigned int list_length;
    if (!enif_get_list_length(env, term, &list_length))
    {
      return enif_make_badarg(env);
    }

    vector<IntVar> *list = new vector<IntVar>();

    ERL_NIF_TERM head;
    ERL_NIF_TERM tail;
    ERL_NIF_TERM current = term;
    for (int i = 0; i < list_length; ++i)
    {
      if (!enif_get_list_cell(env, current, &head, &tail))
      {
        return enif_make_badarg(env);
      }

      IntVarWrapper *var;
      if (!get_int_var(env, head, &var))
      {
        return enif_make_badarg(env);
      }

      list->push_back(*var->p);

      current = tail;
    }

    *vars = list;

    return 1;
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

    std::vector<BoolVar> bool_vars;
    for (int i = 0; i < arity; i++)
    {
      BoolVarWrapper *bool_var_wrapper;
      if (!get_bool_var(env, vars[i], &bool_var_wrapper))
      {
        return enif_make_badarg(env);
      }
      bool_vars.push_back(*bool_var_wrapper->p);
    }

    LinearExprWrapper *linear_expr_wrapper = (LinearExprWrapper *)enif_alloc_resource(LINEAR_EXPR_WRAPPER, sizeof(LinearExprWrapper));
    if (linear_expr_wrapper == NULL)
      return enif_make_badarg(env);

    linear_expr_wrapper->p = new LinearExpr(LinearExpr::Sum(bool_vars));
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

  ERL_NIF_TERM prod_list1_list2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    vector<IntVar> *var1;
    vector<int64_t> *var2;

    if (!get_int_var_list(env, argv[0], &var1))
    {
      return enif_make_badarg(env);
    }

    if (!get_int_list(env, argv[1], &var2))
    {
      return enif_make_badarg(env);
    }

    LinearExprWrapper *linear_expr_wrapper = (LinearExprWrapper *)enif_alloc_resource(LINEAR_EXPR_WRAPPER, sizeof(LinearExprWrapper));
    if (linear_expr_wrapper == NULL)
      return enif_make_badarg(env);

    linear_expr_wrapper->p = new LinearExpr(LinearExpr::ScalProd(*var1, *var2));
    ERL_NIF_TERM term = enif_make_resource(env, linear_expr_wrapper);
    enif_release_resource(linear_expr_wrapper);

    delete var1;
    delete var2;

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
