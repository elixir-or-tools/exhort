#include <cstring>
#include <iostream>
#include "erl_nif.h"
#include "ortools/sat/cp_model.h"
#include "absl/types/span.h"
#include "wrappers.h"
#include "linear_expression.h"
#include "bool_var.h"
#include "int_var.h"
#include "interval_var.h"
#include "cp_solver_response.h"
#include "utility.h"

#include "ortools/sat/model.h"
#include "ortools/sat/sat_parameters.pb.h"

using operations_research::Domain;
using operations_research::sat::BoolVar;
using operations_research::sat::Constraint;
using operations_research::sat::CpModelBuilder;
using operations_research::sat::CpSolverResponse;
using operations_research::sat::IntVar;
using operations_research::sat::LinearExpr;

using operations_research::sat::Model;
using operations_research::sat::NewFeasibleSolutionObserver;
using operations_research::sat::SatParameters;

using operations_research::sat::DecisionStrategyProto;
using operations_research::sat::DecisionStrategyProto_DomainReductionStrategy;

using namespace std;

extern "C"
{
  ErlNifResourceType *CP_MODEL_BUILDER_WRAPPER;
  ErlNifResourceType *CONSTRAINT_WRAPPER;

  ERL_NIF_TERM atom_ok;

  static void free_cp_model_builder(ErlNifEnv *env, void *obj)
  {
    BuilderWrapper *w = (BuilderWrapper *)obj;
    delete w->p;
  }

  static void free_constraint(ErlNifEnv *env, void *obj)
  {
    ConstraintWrapper *w = (ConstraintWrapper *)obj;
    delete w->p;
  }

  static int init_types(ErlNifEnv *env)
  {
    CP_MODEL_BUILDER_WRAPPER = enif_open_resource_type(env, NULL, "CpModelBuilderWrapper", free_cp_model_builder, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);

    CONSTRAINT_WRAPPER = enif_open_resource_type(env, NULL, "ConstraintWrapper", free_constraint, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);

    atom_ok = enif_make_atom(env, "ok");

    return 0;
  }

  ERL_NIF_TERM new_builder_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper = (BuilderWrapper *)enif_alloc_resource(CP_MODEL_BUILDER_WRAPPER, sizeof(BuilderWrapper));
    if (builder_wrapper == NULL)
      return enif_make_badarg(env);

    builder_wrapper->p = new CpModelBuilder();
    ERL_NIF_TERM term = enif_make_resource(env, builder_wrapper);
    enif_release_resource(builder_wrapper);

    return term;
  }

  ERL_NIF_TERM new_bool_var_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    ErlNifBinary name;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }
    enif_inspect_iolist_as_binary(env, argv[1], &name);

    BoolVar v = builder_wrapper->p->NewBoolVar().WithName((char *)name.data);

    return make_bool_var(env, v);
  }

  ERL_NIF_TERM new_int_var_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    ErlNifBinary name;
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

    return make_int_var(env, v);
  }

  ERL_NIF_TERM new_constant_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {

    BuilderWrapper *builder_wrapper;
    ErlNifBinary name;
    int value;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    enif_inspect_iolist_as_binary(env, argv[1], &name);

    enif_get_int(env, argv[2], &value);

    IntVar v = builder_wrapper->p->NewConstant(value).WithName((char *)name.data);

    return make_int_var(env, v);
  }

  ERL_NIF_TERM new_interval_var_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    LinearExprWrapper *var1;
    LinearExprWrapper *var2;
    LinearExprWrapper *var3;
    ErlNifBinary name;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    enif_inspect_iolist_as_binary(env, argv[1], &name);

    if (!get_linear_expression(env, argv[2], &var1))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[3], &var2))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[4], &var3))
    {
      return enif_make_badarg(env);
    }

    IntervalVar v = builder_wrapper->p->NewIntervalVar(*var1->p, *var2->p, *var3->p).WithName((char *)name.data);

    return make_interval_var(env, v);
  }

  ERL_NIF_TERM add_abs_equal_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    IntVarWrapper *var1;
    IntVarWrapper *var2;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!get_int_var(env, argv[1], &var1))
    {
      return enif_make_badarg(env);
    }

    if (!get_int_var(env, argv[2], &var2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddAbsEquality(*var1->p, *var2->p);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    ERL_NIF_TERM term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  ERL_NIF_TERM add_abs_equal_constant_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    long int1;
    IntVarWrapper *var2;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_long(env, argv[1], &int1))
    {
      return enif_make_badarg(env);
    }

    if (!get_int_var(env, argv[2], &var2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddAbsEquality(int1, *var2->p);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    ERL_NIF_TERM term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  ERL_NIF_TERM add_equal_expr1_expr2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    LinearExprWrapper *expr1;
    LinearExprWrapper *expr2;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[1], &expr1))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[2], &expr2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddEquality(*expr1->p, *expr2->p);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    ERL_NIF_TERM term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  ERL_NIF_TERM add_equal_expr1_constant2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    LinearExprWrapper *expr1;
    long constant2;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[1], &expr1))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_int64(env, argv[2], &constant2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddEquality(*expr1->p, constant2);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    ERL_NIF_TERM term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  ERL_NIF_TERM add_equal_int_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    IntVarWrapper *var1;
    IntVarWrapper *var2;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!get_int_var(env, argv[1], &var1))
    {
      return enif_make_badarg(env);
    }

    if (!get_int_var(env, argv[2], &var2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddEquality(*var1->p, *var2->p);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    ERL_NIF_TERM term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  ERL_NIF_TERM add_equal_int_var_plus_int_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    IntVarWrapper *var1;
    long constant2;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!get_int_var(env, argv[1], &var1))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_int64(env, argv[2], &constant2))
    {
      return enif_make_badarg(env);
    }

    Domain d(1, 1);
    IntVar var2 = builder_wrapper->p->NewIntVar(d);
    Constraint constraint = builder_wrapper->p->AddEquality(*var1->p, LinearExpr::Sum({*var1->p, var2}));

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    ERL_NIF_TERM term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  ERL_NIF_TERM add_not_equal_expr1_expr2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    LinearExprWrapper *expr1;
    LinearExprWrapper *expr2;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[1], &expr1))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[2], &expr2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddNotEqual(*expr1->p, *expr2->p);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    ERL_NIF_TERM term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  ERL_NIF_TERM add_not_equal_bool_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    BoolVarWrapper *var1;
    BoolVarWrapper *var2;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!get_bool_var(env, argv[1], &var1))
    {
      return enif_make_badarg(env);
    }

    if (!get_bool_var(env, argv[2], &var2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddNotEqual(*var1->p, *var2->p);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    ERL_NIF_TERM term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  ERL_NIF_TERM add_less_than_expr1_expr2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    LinearExprWrapper *expr1;
    LinearExprWrapper *expr2;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[1], &expr1))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[2], &expr2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddLessThan(*expr1->p, *expr2->p);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    ERL_NIF_TERM term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  ERL_NIF_TERM add_less_or_equal_expr1_expr2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    LinearExprWrapper *expr1;
    LinearExprWrapper *expr2;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[1], &expr1))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[2], &expr2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddLessOrEqual(*expr1->p, *expr2->p);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    ERL_NIF_TERM term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  ERL_NIF_TERM add_greater_than_expr1_expr2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    LinearExprWrapper *expr1;
    LinearExprWrapper *expr2;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[1], &expr1))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[2], &expr2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddGreaterThan(*expr1->p, *expr2->p);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    ERL_NIF_TERM term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  ERL_NIF_TERM add_greater_or_equal_expr1_expr2_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    LinearExprWrapper *expr1;
    LinearExprWrapper *expr2;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[1], &expr1))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[2], &expr2))
    {
      return enif_make_badarg(env);
    }

    Constraint constraint = builder_wrapper->p->AddGreaterOrEqual(*expr1->p, *expr2->p);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    ERL_NIF_TERM term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  ERL_NIF_TERM add_all_different_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    unsigned int list_length;
    if (!enif_get_list_length(env, argv[1], &list_length))
    {
      return enif_make_badarg(env);
    }

    std::vector<LinearExpr> vars;
    ERL_NIF_TERM head;
    ERL_NIF_TERM tail;
    ERL_NIF_TERM current = argv[1];
    for (int i = 0; i < list_length; ++i)
    {
      if (!enif_get_list_cell(env, current, &head, &tail))
      {
        return enif_make_badarg(env);
      }

      LinearExprWrapper *var;
      if (!get_linear_expression(env, head, &var))
      {
        return enif_make_badarg(env);
      }

      vars.push_back(*var->p);

      current = tail;
    }

    Constraint constraint = builder_wrapper->p->AddAllDifferent(vars);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    ERL_NIF_TERM term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  ERL_NIF_TERM add_no_overlap_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    unsigned int list_length;
    if (!enif_get_list_length(env, argv[1], &list_length))
    {
      return enif_make_badarg(env);
    }

    std::vector<IntervalVar> vars;
    ERL_NIF_TERM head;
    ERL_NIF_TERM tail;
    ERL_NIF_TERM current = argv[1];
    for (int i = 0; i < list_length; ++i)
    {
      if (!enif_get_list_cell(env, current, &head, &tail))
      {
        return enif_make_badarg(env);
      }

      IntervalVarWrapper *var;
      if (!get_interval_var(env, head, &var))
      {
        return enif_make_badarg(env);
      }

      vars.push_back(*var->p);

      current = tail;
    }

    Constraint constraint = builder_wrapper->p->AddNoOverlap(vars);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    ERL_NIF_TERM term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  ERL_NIF_TERM add_max_equality_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    IntVarWrapper *var1;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!get_int_var(env, argv[1], &var1))
    {
      return enif_make_badarg(env);
    }

    unsigned int list_length;
    if (!enif_get_list_length(env, argv[2], &list_length))
    {
      return enif_make_badarg(env);
    }

    std::vector<IntVar> vars;
    ERL_NIF_TERM head;
    ERL_NIF_TERM tail;
    ERL_NIF_TERM current = argv[2];
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

      vars.push_back(*var->p);

      current = tail;
    }

    Constraint constraint = builder_wrapper->p->AddMaxEquality(*var1->p, vars);

    ConstraintWrapper *constraint_wrapper = (ConstraintWrapper *)enif_alloc_resource(CONSTRAINT_WRAPPER, sizeof(ConstraintWrapper));
    if (constraint_wrapper == NULL)
      return enif_make_badarg(env);

    constraint_wrapper->p = new Constraint(constraint);

    ERL_NIF_TERM term = enif_make_resource(env, constraint_wrapper);
    enif_release_resource(constraint_wrapper);

    return term;
  }

  ERL_NIF_TERM add_minimize_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    IntVarWrapper *var1;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!get_int_var(env, argv[1], &var1))
    {
      return enif_make_badarg(env);
    }

    builder_wrapper->p->Minimize(*var1->p);

    return argv[0];
  }

  ERL_NIF_TERM add_maximize_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    LinearExprWrapper *expr1;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!get_linear_expression(env, argv[1], &expr1))
    {
      return enif_make_badarg(env);
    }

    builder_wrapper->p->Maximize(*expr1->p);

    return argv[0];
  }

  ERL_NIF_TERM only_enforce_if_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    ConstraintWrapper *constraint_wrapper;
    BoolVarWrapper *var;

    if (!enif_get_resource(env, argv[0], CONSTRAINT_WRAPPER, (void **)&constraint_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!get_bool_var(env, argv[1], &var))
    {
      return enif_make_badarg(env);
    }

    constraint_wrapper->p->OnlyEnforceIf(*var->p);

    return argv[0];
  }

  ERL_NIF_TERM bool_not_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BoolVarWrapper *var;

    if (!get_bool_var(env, argv[0], &var))
    {
      return enif_make_badarg(env);
    }

    BoolVar v(var->p->Not());
    return make_bool_var(env, v);
  }

  ERL_NIF_TERM add_decision_strategy_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    vector<IntVar> *vars;
    int variable_selection_strategy;
    int domain_reduction_strategy;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    if (!get_int_var_list(env, argv[1], &vars))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_int(env, argv[2], &variable_selection_strategy))
    {
      return enif_make_badarg(env);
    }

    if (!enif_get_int(env, argv[3], &domain_reduction_strategy))
    {
      return enif_make_badarg(env);
    }

    builder_wrapper->p->AddDecisionStrategy(*vars, static_cast<DecisionStrategyProto::VariableSelectionStrategy>(variable_selection_strategy), static_cast<DecisionStrategyProto::DomainReductionStrategy>(domain_reduction_strategy));

    return argv[0];
  }

  ERL_NIF_TERM solve_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    CpSolverResponse response = Solve(builder_wrapper->p->Build());

    return make_cp_solver_response(env, response);
  }

  ERL_NIF_TERM solve_with_callback_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;

    if (!enif_get_resource(env, argv[0], CP_MODEL_BUILDER_WRAPPER, (void **)&builder_wrapper))
    {
      return enif_make_badarg(env);
    }

    ErlNifPid pid;
    enif_get_local_pid(env, argv[1], &pid);

    Model model;
    SatParameters parameters;
    parameters.set_search_branching(SatParameters::FIXED_SEARCH);
    parameters.set_enumerate_all_solutions(true);
    model.Add(NewSatParameters(parameters));
    model.Add(NewFeasibleSolutionObserver([&](const CpSolverResponse &r)
                                          {
                                            ERL_NIF_TERM term = make_cp_solver_response(env, r);
                                            enif_send(env, &pid, NULL, term);
                                          }));

    CpSolverResponse response = SolveCpModel(builder_wrapper->p->Build(), &model);
    return make_cp_solver_response(env, response);
  }

  ERL_NIF_TERM solution_bool_value_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    CpSolverResponseWrapper *response;
    BoolVarWrapper *var;

    if (!get_cp_solver_response(env, argv[0], &response))
    {
      return enif_make_badarg(env);
    }

    if (!get_bool_var(env, argv[1], &var))
    {
      return enif_make_badarg(env);
    }

    bool value = SolutionBooleanValue(*response->p, *var->p);

    return enif_make_int(env, value);
  }

  ERL_NIF_TERM solution_integer_value_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    CpSolverResponseWrapper *response;
    IntVarWrapper *var;

    if (!get_cp_solver_response(env, argv[0], &response))
    {
      return enif_make_badarg(env);
    }

    if (!get_int_var(env, argv[1], &var))
    {
      return enif_make_badarg(env);
    }

    int64_t value = SolutionIntegerValue(*response->p, *var->p);

    return enif_make_int64(env, value);
  }

  int load_cp_model_builder(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info)
  {
    if (init_types(env) == -1)
      return -1;
    else
      return 0;
  }
}
