#include <cstring>
// #include <string.h>
#include "erl_nif.h"
#include "ortools/sat/cp_model.h"
#include "wrappers.h"

using operations_research::Domain;
using operations_research::sat::BoolVar;
using operations_research::sat::Constraint;
using operations_research::sat::CpModelBuilder;
using operations_research::sat::CpSolverResponse;
using operations_research::sat::IntVar;
using operations_research::sat::LinearExpr;

extern "C"
{
  ErlNifResourceType *CP_MODEL_BUILDER_WRAPPER;
  ErlNifResourceType *BOOL_VAR_WRAPPER;
  ErlNifResourceType *INT_VAR_WRAPPER;
  ErlNifResourceType *CONSTRAINT_WRAPPER;
  ErlNifResourceType *CP_SOLVER_RESPONSE_WRAPPER;
  ErlNifResourceType *LINEAR_EXPR_WRAPPER;

  ERL_NIF_TERM atom_ok;

  void free_cp_model_builder(ErlNifEnv *env, void *obj)
  {
    BuilderWrapper *w = (BuilderWrapper *)obj;
    delete w->p;
  }

  void free_bool_var(ErlNifEnv *env, void *obj)
  {
    BoolVarWrapper *w = (BoolVarWrapper *)obj;
    delete w->p;
  }

  void free_int_var(ErlNifEnv *env, void *obj)
  {
    IntVarWrapper *w = (IntVarWrapper *)obj;
    delete w->p;
  }

  void free_constraint(ErlNifEnv *env, void *obj)
  {
    ConstraintWrapper *w = (ConstraintWrapper *)obj;
    delete w->p;
  }

  void free_solver_response(ErlNifEnv *env, void *obj)
  {
    CpSolverResponseWrapper *w = (CpSolverResponseWrapper *)obj;
    delete w->p;
  }

  void free_linear_expr(ErlNifEnv *env, void *obj)
  {
    LinearExprWrapper *w = (LinearExprWrapper *)obj;
    delete w->p;
  }

  static int init_types(ErlNifEnv *env)
  {
    CP_MODEL_BUILDER_WRAPPER = enif_open_resource_type(env, NULL, "CpModelBuilderWrapper", free_cp_model_builder, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);

    LINEAR_EXPR_WRAPPER = enif_open_resource_type(env, NULL, "LinearExprWrapper", free_linear_expr, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);

    BOOL_VAR_WRAPPER = enif_open_resource_type(env, NULL, "BoolVarWrapper", free_bool_var, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);

    INT_VAR_WRAPPER = enif_open_resource_type(env, NULL, "IntVarWrapper", free_int_var, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);

    CONSTRAINT_WRAPPER = enif_open_resource_type(env, NULL, "ConstraintWrapper", free_constraint, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);

    CP_SOLVER_RESPONSE_WRAPPER = enif_open_resource_type(env, NULL, "CpSolverResponse", free_solver_response, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);

    LINEAR_EXPR_WRAPPER = enif_open_resource_type(env, NULL, "LinearExprWrapper", free_linear_expr, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);

    atom_ok = enif_make_atom(env, "ok");

    return 0;
  }

  static int load(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info)
  {
    if (init_types(env) == -1)
      return -1;
    else
      return 0;
  }

  static ERL_NIF_TERM new_builder_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    ERL_NIF_TERM term;

    BuilderWrapper *builder_wrapper = (BuilderWrapper *)enif_alloc_resource(CP_MODEL_BUILDER_WRAPPER, sizeof(BuilderWrapper));
    if (builder_wrapper == NULL)
      return enif_make_badarg(env);

    builder_wrapper->p = new CpModelBuilder();
    term = enif_make_resource(env, builder_wrapper);
    enif_release_resource(builder_wrapper);

    return enif_make_tuple2(env, atom_ok, term);
  }

  static ERL_NIF_TERM new_bool_var_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    ErlNifBinary name;
    ERL_NIF_TERM term;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }
    enif_inspect_iolist_as_binary(env, argv[1], &name);

    BoolVar v = builder_wrapper->p->NewBoolVar().WithName((char *)name.data);

    BoolVarWrapper *bool_var_wrapper = (BoolVarWrapper *)enif_alloc_resource(BOOL_VAR_WRAPPER, sizeof(BoolVarWrapper));
    if (bool_var_wrapper == NULL)
      return enif_make_badarg(env);

    bool_var_wrapper->p = new BoolVar(v);
    term = enif_make_resource(env, bool_var_wrapper);
    enif_release_resource(bool_var_wrapper);

    return term;
  }

  static ERL_NIF_TERM new_int_var_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    ErlNifBinary name;
    ERL_NIF_TERM term;
    int upper_bound, lower_bound;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }
    enif_get_int(env, argv[1], &lower_bound);
    enif_get_int(env, argv[2], &upper_bound);
    enif_inspect_iolist_as_binary(env, argv[3], &name);

    Domain domain(lower_bound, upper_bound);
    IntVar v = builder_wrapper->p->NewIntVar(domain).WithName((char *)name.data);

    IntVarWrapper *int_var_wrapper = (IntVarWrapper *)enif_alloc_resource(INT_VAR_WRAPPER, sizeof(IntVarWrapper));
    if (int_var_wrapper == NULL)
      return enif_make_badarg(env);

    int_var_wrapper->p = new IntVar(v);
    term = enif_make_resource(env, int_var_wrapper);
    enif_release_resource(int_var_wrapper);

    return term;
  }

  static ERL_NIF_TERM add_equal_expr_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    LinearExprWrapper *expr1;
    long constant2;
    ERL_NIF_TERM term;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, argv[1], LINEAR_EXPR_WRAPPER, (void **)&expr1))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_int64(env, argv[2], &constant2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddEquality(*expr1->p, constant2);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(INT_VAR_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  static ERL_NIF_TERM add_equal_int_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    IntVarWrapper *var1;
    IntVarWrapper *var2;
    ERL_NIF_TERM term;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, argv[1], INT_VAR_WRAPPER, (void **)&var1))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, argv[2], INT_VAR_WRAPPER, (void **)&var2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddEquality(*var1->p, *var2->p);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(INT_VAR_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  static ERL_NIF_TERM add_equal_int_constant_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    IntVarWrapper *var1;
    long constant2;
    ERL_NIF_TERM term;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, argv[1], INT_VAR_WRAPPER, (void **)&var1))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_int64(env, argv[2], &constant2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddEquality(*var1->p, constant2);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(INT_VAR_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  static ERL_NIF_TERM add_equal_bool_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    BoolVarWrapper *var1;
    BoolVarWrapper *var2;
    ERL_NIF_TERM term;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, argv[1], BOOL_VAR_WRAPPER, (void **)&var1))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, argv[2], BOOL_VAR_WRAPPER, (void **)&var2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddEquality(*var1->p, *var2->p);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(INT_VAR_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  static ERL_NIF_TERM add_not_equal_int_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    IntVarWrapper *var1;
    IntVarWrapper *var2;
    ERL_NIF_TERM term;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, argv[1], INT_VAR_WRAPPER, (void **)&var1))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, argv[2], INT_VAR_WRAPPER, (void **)&var2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddNotEqual(*var1->p, *var2->p);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(INT_VAR_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  static ERL_NIF_TERM add_not_equal_bool_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    BoolVarWrapper *var1;
    BoolVarWrapper *var2;
    ERL_NIF_TERM term;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, argv[1], BOOL_VAR_WRAPPER, (void **)&var1))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, argv[2], BOOL_VAR_WRAPPER, (void **)&var2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddNotEqual(*var1->p, *var2->p);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  static ERL_NIF_TERM add_greater_or_equal_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    IntVarWrapper *var1;
    long constant2;
    ERL_NIF_TERM term;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, argv[1], INT_VAR_WRAPPER, (void **)&var1))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_int64(env, argv[2], &constant2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddGreaterOrEqual(*var1->p, constant2);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  static ERL_NIF_TERM add_less_or_equal_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    IntVarWrapper *var1;
    long constant2;
    ERL_NIF_TERM term;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, argv[1], INT_VAR_WRAPPER, (void **)&var1))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_int64(env, argv[2], &constant2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddLessOrEqual(*var1->p, constant2);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  static ERL_NIF_TERM only_enforce_if_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    ConstraintWrapper *constraint_wrapper;
    BoolVarWrapper *var;
    ERL_NIF_TERM term;

    if (!enif_get_resource(env, argv[0], CONSTRAINT_WRAPPER, (void **)&constraint_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, argv[1], BOOL_VAR_WRAPPER, (void **)&var))
    {
      return enif_make_badarg(env);
    }

    constraint_wrapper->p->OnlyEnforceIf(*var->p);

    return argv[0];
  }

  static ERL_NIF_TERM bool_not_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BoolVarWrapper *var;
    ERL_NIF_TERM term;

    if (!enif_get_resource(env, argv[0], BOOL_VAR_WRAPPER, (void **)&var))
    {
      return enif_make_badarg(env);
    }

    var->p->Not();

    return argv[0];
  }

  static ERL_NIF_TERM solve_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    ERL_NIF_TERM term;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    CpSolverResponse response = Solve(builder_wrapper->p->Build());

    CpSolverResponseWrapper *response_wrapper = (CpSolverResponseWrapper *)enif_alloc_resource(CP_SOLVER_RESPONSE_WRAPPER, sizeof(CpSolverResponseWrapper));
    if (response_wrapper == NULL)
      return enif_make_badarg(env);

    response_wrapper->p = new CpSolverResponse(response);
    term = enif_make_resource(env, response_wrapper);
    enif_release_resource(response_wrapper);

    return term;
  }

  static ERL_NIF_TERM solution_bool_value_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    CpSolverResponseWrapper *response;
    BoolVarWrapper *var;

    if (!enif_get_resource(env, argv[0], CP_SOLVER_RESPONSE_WRAPPER, (void **)&response))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, argv[1], BOOL_VAR_WRAPPER, (void **)&var))
    {
      return enif_make_badarg(env);
    }

    bool value = SolutionBooleanValue(*response->p, *var->p);

    return enif_make_int(env, value);
  }

  static ERL_NIF_TERM solution_integer_value_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    CpSolverResponseWrapper *response;
    IntVarWrapper *var;

    if (!enif_get_resource(env, argv[0], CP_SOLVER_RESPONSE_WRAPPER, (void **)&response))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, argv[1], INT_VAR_WRAPPER, (void **)&var))
    {
      return enif_make_badarg(env);
    }

    int64_t value = SolutionIntegerValue(*response->p, *var->p);

    return enif_make_int64(env, value);
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
      {"add_equal_expr_nif", 3, add_equal_expr_nif},
      {"add_equal_int_nif", 3, add_equal_int_nif},
      {"add_not_equal_int_nif", 3, add_not_equal_int_nif},
      {"add_equal_int_constant_nif", 3, add_equal_int_constant_nif},
      {"add_equal_bool_nif", 3, add_equal_bool_nif},
      {"add_not_equal_bool_nif", 3, add_not_equal_bool_nif},
      {"add_greater_or_equal_nif", 3, add_greater_or_equal_nif},
      {"add_less_or_equal_nif", 3, add_less_or_equal_nif},
      {"new_bool_var_nif", 2, new_bool_var_nif},
      {"new_int_var_nif", 4, new_int_var_nif},
      {"new_nif", 0, new_builder_nif},
      {"bool_not_nif", 1, bool_not_nif},
      {"solution_integer_value_nif", 2, solution_integer_value_nif},
      {"solution_bool_value_nif", 2, solution_bool_value_nif},
      {"solve_nif", 1, solve_nif},
      {"sum_nif", 2, sum_nif}};

  ERL_NIF_INIT(Elixir.CpModelBuilder, nif_funcs, &load, NULL, NULL, NULL)
}
