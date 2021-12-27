#ifndef __UTILITY_H__
#define __UTILITY_H__

#include <vector>
#include "erl_nif.h"

using namespace std;

extern "C"
{
  int get_int_list(ErlNifEnv *env, ERL_NIF_TERM term, vector<int64_t> **vars);

  int get_int_var_list(ErlNifEnv *env, ERL_NIF_TERM term, vector<IntVar> **vars);
}

#endif
