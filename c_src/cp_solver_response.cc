#include <cstring>
#include "erl_nif.h"
#include "ortools/sat/cp_model.h"
#include "wrappers.h"

using operations_research::sat::CpSolverResponse;

extern "C"
{
  ErlNifResourceType *CP_SOLVER_RESPONSE_WRAPPER;

  static void free_solver_response(ErlNifEnv *env, void *obj)
  {
    CpSolverResponseWrapper *w = (CpSolverResponseWrapper *)obj;
    delete w->p;
  }

  static int init_types(ErlNifEnv *env)
  {
    CP_SOLVER_RESPONSE_WRAPPER = enif_open_resource_type(env, NULL, "CpSolverResponse", free_solver_response, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);
    return 0;
  }

  int get_cp_solver_response(ErlNifEnv *env, ERL_NIF_TERM term, CpSolverResponseWrapper **obj)
  {
    return enif_get_resource(env, term, CP_SOLVER_RESPONSE_WRAPPER, (void **)obj);
  }

  ERL_NIF_TERM make_cp_solver_response(ErlNifEnv *env, CpSolverResponse &from_cp_solver_response)
  {
    CpSolverResponseWrapper *cp_solver_response_wrapper = (CpSolverResponseWrapper *)enif_alloc_resource(CP_SOLVER_RESPONSE_WRAPPER, sizeof(CpSolverResponseWrapper));
    if (cp_solver_response_wrapper == NULL)
      return enif_make_badarg(env);

    cp_solver_response_wrapper->p = new CpSolverResponse(from_cp_solver_response);
    ERL_NIF_TERM term = enif_make_resource(env, cp_solver_response_wrapper);
    enif_release_resource(cp_solver_response_wrapper);

    return term;
  }

  int load_cp_solver_response(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info)
  {
    if (init_types(env) == -1)
      return -1;
    else
      return 0;
  }
}
