// Copyright 2010-2021 Google LLC
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// [START program]
#include "ortools/sat/cp_model.h"

namespace operations_research {
namespace sat {

void SimpleSatProgramBool() {
  // [START model]
  CpModelBuilder cp_model;
  // [END model]

  // [START variables]
  const BoolVar x = cp_model.NewBoolVar().WithName("x");
  const BoolVar y = cp_model.NewBoolVar().WithName("y");
  // [END variables]

  // [START constraints]
  cp_model.AddNotEqual(x, y);
  // [END constraints]

  // Solving part.
  // [START solve]
  const CpSolverResponse response = Solve(cp_model.Build());
  LOG(INFO) << CpSolverResponseStats(response);
  // [END solve]

  if (response.status() == CpSolverStatus::OPTIMAL) {
    // Get the value of x in the solution.
    LOG(INFO) << "x = " << SolutionBooleanValue(response, x);
    LOG(INFO) << "y = " << SolutionBooleanValue(response, y);
  }
}

}  // namespace sat
}  // namespace operations_research

int main() {
  operations_research::sat::SimpleSatProgramBool();

  return EXIT_SUCCESS;
}
// [END program]
