#include <cstring>
// #include <string.h>
#include "erl_nif.h"
#include "ortools/sat/cp_model.h"

using operations_research::Domain;
using operations_research::sat::CpModelBuilder;
using operations_research::sat::CpSolverResponse;
using operations_research::sat::IntVar;

extern "C"
{
  // Wrap each underlying model so the underlying model may be allocated
  // using its class constructor. Each underlying model is referenced
  // through the wrapper's `p` member.
  typedef struct
  {
    CpModelBuilder *p;
  } BuilderWrapper;
  ErlNifResourceType *CP_MODEL_BUILDER_WRAPPER;

  typedef struct
  {
    IntVar *p;
  } IntVarWrapper;
  ErlNifResourceType *INT_VAR_WRAPPER;

  typedef struct
  {
    CpSolverResponse *p;
  } CpSolverResponseWrapper;
  ErlNifResourceType *CP_SOLVER_RESPONSE_WRAPPER;

  ERL_NIF_TERM atom_ok;

  // TODO: Do we need to free anything?
  void free_cp_model_builder(ErlNifEnv *env, void *obj)
  {
    // CpModelBuilder *builder = (CpModelBuilder *)obj;
    // delete builder;
  }

  static int init_types(ErlNifEnv *env)
  {
    CP_MODEL_BUILDER_WRAPPER = enif_open_resource_type(env, NULL, "CpModelBuilderWrapper", free_cp_model_builder, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);

    INT_VAR_WRAPPER = enif_open_resource_type(env, NULL, "IntVarWrapper", free_cp_model_builder, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);

    CP_SOLVER_RESPONSE_WRAPPER = enif_open_resource_type(env, NULL, "CpSolverResponse", free_cp_model_builder, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);

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

  static ERL_NIF_TERM add_not_equal_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    BuilderWrapper *builder_wrapper;
    IntVarWrapper *var1;
    IntVarWrapper *var2;

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

    builder_wrapper->p->AddNotEqual(*var1->p, *var2->p);

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

  static ERL_NIF_TERM solution_integer_value_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
  {
    CpSolverResponseWrapper *response;
    IntVarWrapper *var;
    ERL_NIF_TERM term;

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

  static ErlNifFunc nif_funcs[] = {
      {"new_nif", 0, new_builder_nif},
      {"new_int_var_nif", 4, new_int_var_nif},
      {"add_not_equal_nif", 3, add_not_equal_nif},
      {"solve_nif", 1, solve_nif},
      {"solution_integer_value_nif", 2, solution_integer_value_nif}};

  ERL_NIF_INIT(Elixir.CpModelBuilder, nif_funcs, &load, NULL, NULL, NULL)
}
