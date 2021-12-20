#include <cstring>
#include "erl_nif.h"
#include "ortools/sat/cp_model.h"
#include "wrappers.h"

extern "C"
{
  ErlNifResourceType *BOOL_VAR_WRAPPER;

  static void free_bool_var(ErlNifEnv *env, void *obj)
  {
    BoolVarWrapper *w = (BoolVarWrapper *)obj;
    delete w->p;
  }

  static int init_types(ErlNifEnv *env)
  {
    BOOL_VAR_WRAPPER = enif_open_resource_type(env, NULL, "BoolVarWrapper", free_bool_var, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);
    return 0;
  }

  int get_bool_var(ErlNifEnv *env, ERL_NIF_TERM term, BoolVarWrapper **obj)
  {
    return enif_get_resource(env, term, BOOL_VAR_WRAPPER, (void **)obj);
  }

  ERL_NIF_TERM make_bool_var(ErlNifEnv *env, BoolVar &from_bool_var)
  {
    BoolVarWrapper *bool_var_wrapper = (BoolVarWrapper *)enif_alloc_resource(BOOL_VAR_WRAPPER, sizeof(BoolVarWrapper));
    if (bool_var_wrapper == NULL)
      return enif_make_badarg(env);

    bool_var_wrapper->p = new BoolVar(from_bool_var);
    ERL_NIF_TERM term = enif_make_resource(env, bool_var_wrapper);
    enif_release_resource(bool_var_wrapper);

    return term;
  }

  int load_bool_var(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info)
  {
    if (init_types(env) == -1)
      return -1;
    else
      return 0;
  }
}
