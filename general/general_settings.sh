#!/bin/env bash
# Use to print each step: #!/bin/bash -x
#


######
# Color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
#####

PREFIX="$MAGENTA==> [APPS testing compilation] ${NC}"
ERROR="$RED => [ERROR] $NC"
WARNING="$YELLOW => [WARN] $NC"

