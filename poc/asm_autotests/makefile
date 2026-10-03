CC = gcc
CPPFLAGS ?=
CFLAGS ?= -Wall -Wextra
ASMFLAGS ?=
LDFLAGS ?=
LDLIBS ?=

SRC_D := src
OBJ_D := obj
BIN_D := bin
RUNNER := test

TEST_DIR ?=
FUNC_PATH ?=

# Safe placeholder roots keep an accidental plain `make` from constructing
# absolute paths such as /bin/test before the validation target can fail.
TEST_ROOT := $(if $(strip $(TEST_DIR)),$(TEST_DIR),.missing-test-dir)
FUNC_ROOT := $(if $(strip $(FUNC_PATH)),$(FUNC_PATH),.missing-func-path)

TEST_SOURCE := $(TEST_ROOT)/$(SRC_D)/test.c
FUNC_SOURCE := $(FUNC_ROOT)/$(SRC_D)/func.s
TEST_OBJ_DIR := $(TEST_ROOT)/$(OBJ_D)
TEST_BIN_DIR := $(TEST_ROOT)/$(BIN_D)
TEST_OBJECT := $(TEST_OBJ_DIR)/test.o
RUNNER_PATH := $(TEST_BIN_DIR)/$(RUNNER)

ASM_SOURCES := $(filter-out $(FUNC_ROOT)/$(SRC_D)/main_a.s,               $(wildcard $(FUNC_ROOT)/$(SRC_D)/*.s))
ASM_OBJECTS := $(patsubst $(FUNC_ROOT)/$(SRC_D)/%.s,               $(TEST_OBJ_DIR)/student_%.o,$(ASM_SOURCES))

.PHONY: all check run clean help

all: $(RUNNER_PATH)

check:
	@if [ -z "$(strip $(FUNC_PATH))" ]; then 		echo "ERROR: FUNC_PATH is required" >&2; exit 2; 	fi
	@if [ -z "$(strip $(TEST_DIR))" ]; then 		echo "ERROR: TEST_DIR is required" >&2; exit 2; 	fi
	@if [ ! -f "$(FUNC_SOURCE)" ]; then 		echo "ERROR: missing $(FUNC_SOURCE)" >&2; exit 2; 	fi
	@if [ ! -f "$(TEST_SOURCE)" ]; then 		echo "ERROR: missing $(TEST_SOURCE)" >&2; exit 2; 	fi

$(TEST_OBJ_DIR) $(TEST_BIN_DIR): | check
	mkdir -p "$@"

$(TEST_OBJ_DIR)/student_%.o: $(FUNC_ROOT)/$(SRC_D)/%.s | $(TEST_OBJ_DIR)
	$(CC) $(CPPFLAGS) $(ASMFLAGS) -c "$<" -o "$@"

$(TEST_OBJECT): $(TEST_SOURCE) | $(TEST_OBJ_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c "$<" -o "$@"

$(RUNNER_PATH): $(TEST_OBJECT) $(ASM_OBJECTS) | $(TEST_BIN_DIR)
	$(CC) $(LDFLAGS) $(TEST_OBJECT) $(ASM_OBJECTS) $(LDLIBS) -o "$@"

run: $(RUNNER_PATH)
	cd "$(TEST_BIN_DIR)" && ./$(RUNNER)

clean:
	@if [ -z "$(strip $(TEST_DIR))" ]; then 		echo "ERROR: TEST_DIR is required" >&2; exit 2; 	fi
	rm -rf "$(TEST_ROOT)/$(OBJ_D)" "$(TEST_ROOT)/$(BIN_D)"

help:
	@printf '%s\n' 	  'Build: make FUNC_PATH=/path/to/func_1 TEST_DIR=1_sort_32_uint all' 	  'Run:   make FUNC_PATH=/path/to/func_1 TEST_DIR=1_sort_32_uint run' 	  'Check: make FUNC_PATH=/path/to/func_1 TEST_DIR=1_sort_32_uint check' 	  'Clean: make TEST_DIR=1_sort_32_uint clean'
