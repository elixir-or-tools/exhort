#include <cstring>
#include <string.h>
#include "erl_nif.h"
#include "ortools/sat/cp_model.h"
#include "wrappers.h"

using namespace std;

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

  ERL_NIF_TERM make_cp_solver_response(ErlNifEnv *env, const CpSolverResponse &from)
  {
    CpSolverResponseWrapper *cp_solver_response_wrapper = (CpSolverResponseWrapper *)enif_alloc_resource(CP_SOLVER_RESPONSE_WRAPPER, sizeof(CpSolverResponseWrapper));
    if (cp_solver_response_wrapper == NULL)
      return enif_make_badarg(env);

    cp_solver_response_wrapper->p = new CpSolverResponse(from);
    ERL_NIF_TERM term = enif_make_resource(env, cp_solver_response_wrapper);
    enif_release_resource(cp_solver_response_wrapper);

    vector<ERL_NIF_TERM> keys;
    vector<ERL_NIF_TERM> values;

    const char *res_key = "res";
    ErlNifBinary res = {.size = strlen(res_key), .data = (unsigned char *)res_key};
    keys.push_back(enif_make_binary(env, &res));
    values.push_back(term);

    const char *status_key = "status";
    ErlNifBinary status = {.size = strlen(status_key), .data = (unsigned char *)status_key};
    keys.push_back(enif_make_binary(env, &status));
    values.push_back(enif_make_int(env, from.status()));

    const char *objective_key = "objective";
    ErlNifBinary objective = {.size = strlen(objective_key), .data = (unsigned char *)objective_key};
    keys.push_back(enif_make_binary(env, &objective));
    values.push_back(enif_make_double(env, from.objective_value()));

    const char *walltime_key = "walltime";
    ErlNifBinary walltime = {.size = strlen(walltime_key), .data = (unsigned char *)walltime_key};
    keys.push_back(enif_make_binary(env, &walltime));
    values.push_back(enif_make_double(env, from.wall_time()));

    const char *usertime_key = "usertime";
    ErlNifBinary usertime = {.size = strlen(usertime_key), .data = (unsigned char *)usertime_key};
    keys.push_back(enif_make_binary(env, &usertime));
    values.push_back(enif_make_double(env, from.user_time()));

    ERL_NIF_TERM key_array[keys.size()];
    std::copy(keys.begin(), keys.end(), key_array);

    ERL_NIF_TERM value_array[values.size()];
    std::copy(values.begin(), values.end(), value_array);

    ERL_NIF_TERM result;

    enif_make_map_from_arrays(env, key_array, value_array, keys.size(), &result);

    return result;
  }

  int load_cp_solver_response(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info)
  {
    if (init_types(env) == -1)
      return -1;
    else
      return 0;
  }
}
