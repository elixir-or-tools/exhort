#include "ortools/sat/cp_model.h"

// Wrap each underlying model so the underlying model may be allocated
// using its class constructor. Each underlying model is referenced
// through the wrapper's `p` member.

using operations_research::sat::BoolVar;
using operations_research::sat::Constraint;
using operations_research::sat::CpModelBuilder;
using operations_research::sat::CpSolverResponse;
using operations_research::sat::IntVar;
using operations_research::sat::LinearExpr;

extern "C"
{
  typedef struct
  {
    CpModelBuilder *p;
  } BuilderWrapper;

  typedef struct
  {
    BoolVar *p;
  } BoolVarWrapper;

  typedef struct
  {
    IntVar *p;
  } IntVarWrapper;

  typedef struct
  {
    Constraint *p;
  } ConstraintWrapper;

  typedef struct
  {
    CpSolverResponse *p;
  } CpSolverResponseWrapper;

  typedef struct
  {
    LinearExpr *p;
  } LinearExprWrapper;
}
