#!/bin/bash

source $(dirname "$(readlink -f /usr/local/bin/test_compilation)")/general_settings.sh

result=$(
  python - <<END
correct = CORRECT
result = $1
epsilon = EPSILON
if abs(correct - result) < epsilon:
  print("${GREEN} => Correct! results are equal (within epsilon); Expected value: " + str(correct) + "; Received value: " + str(result) + "; Epsilon: " + str(epsilon) + ".${NC}")
elif abs(correct - result) >= epsilon:
  print("${ERROR}NOT EQUAL (within epsilon); Expected value: " + str(correct) + "; Received value: " + str(result) + "; Epsilon: " + str(epsilon) + ".${NC}")
END
)
echo -e $result
