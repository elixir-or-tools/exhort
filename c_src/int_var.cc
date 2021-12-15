#include <cstring>
#include "erl_nif.h"
#include "ortools/sat/cp_model.h"
#include "wrappers.h"

extern "C"
{
  ErlNifResourceType *INT_VAR_WRAPPER;

  static void free_int_var(ErlNifEnv *env, void *obj)
  {
    IntVarWrapper *w = (IntVarWrapper *)obj;
    delete w->p;
  }

  static int init_types(ErlNifEnv *env)
  {
    INT_VAR_WRAPPER = enif_open_resource_type(env, NULL, "IntVarWrapper", free_int_var, (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);
    return 0;
  }

  int get_int_var(ErlNifEnv *env, ERL_NIF_TERM term, IntVarWrapper **obj)
  {
    return enif_get_resource(env, term, INT_VAR_WRAPPER, (void **)obj);
  }

  ERL_NIF_TERM make_int_var(ErlNifEnv *env, IntVar &from_int_var)
  {
    IntVarWrapper *int_var_wrapper = (IntVarWrapper *)enif_alloc_resource(INT_VAR_WRAPPER, sizeof(IntVarWrapper));
    if (int_var_wrapper == NULL)
      return enif_make_badarg(env);

    int_var_wrapper->p = new IntVar(from_int_var);
    ERL_NIF_TERM term = enif_make_resource(env, int_var_wrapper);
    enif_release_resource(int_var_wrapper);

    return term;
  }

  int load_int_var(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info)
  {
    if (init_types(env) == -1)
      return -1;
    else
      return 0;
  }
}
