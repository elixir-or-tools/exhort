#include <cstring>
#include <iostream>
#include "erl_nif.h"
#include "wrappers.h"
#include "int_var.h"

using namespace std;

extern "C"
{
  int get_int_list(ErlNifEnv *env, ERL_NIF_TERM term, vector<int64_t> **vars)
  {
    unsigned int list_length;
    if (!enif_get_list_length(env, term, &list_length))
    {
      return enif_make_badarg(env);
    }

    vector<int64_t> *list = new vector<int64_t>();

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
}
