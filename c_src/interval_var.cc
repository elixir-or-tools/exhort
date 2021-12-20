#include <cstring>
#include "erl_nif.h"
#include "ortools/sat/cp_model.h"
#include "wrappers.h"

extern "C"
{
  ErlNifResourceType *INTERVAL_VAR_WRAPPER;

  static void free_interval_var(ErlNifEnv *env, void *obj)
  {
    IntervalVarWrapper *w = (IntervalVarWrapper *)obj;
    delete w->p;
  }

  static int init_types(ErlNifEnv *env)
  {
    INTERVAL_VAR_WRAPPER = enif_open_resource_type(env, NULL, "IntervalVarWrapper", free_interval_var, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);
    return 0;
  }

  int get_interval_var(ErlNifEnv *env, ERL_NIF_TERM term, IntervalVarWrapper **obj)
  {
    return enif_get_resource(env, term, INTERVAL_VAR_WRAPPER, (void **)obj);
  }

  ERL_NIF_TERM make_interval_var(ErlNifEnv *env, IntervalVar &from_var)
  {
    IntervalVarWrapper *interval_var_wrapper = (IntervalVarWrapper *)enif_alloc_resource(INTERVAL_VAR_WRAPPER, sizeof(IntervalVarWrapper));
    if (interval_var_wrapper == NULL)
      return enif_make_badarg(env);

    interval_var_wrapper->p = new IntervalVar(from_var);
    ERL_NIF_TERM term = enif_make_resource(env, interval_var_wrapper);
    enif_release_resource(interval_var_wrapper);

    return term;
  }

  int load_interval_var(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info)
  {
    if (init_types(env) == -1)
      return -1;
    else
      return 0;
  }
}
