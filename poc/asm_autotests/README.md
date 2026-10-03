# UCU x86 assembly lab autotests

This directory contains functional tests for the x86 assembly laboratory work.
The tests call the student's function `func` through the platform C ABI and
compare its result with the expected result.

The current project template is:
https://github.com/ucu-poc-acs-os-cpp/template_asm

## Scope

The autotest harness tests the assembly function itself. It intentionally does
**not** invoke the student's `makefile`: correctness of the project build files,
C/assembly/Python demonstrations, and other submission requirements should be
checked separately.

`FUNC_PATH` must point to one of the student's function directories, for example
`func_1`. The expected layout is:

```text
func_1/
└── src/
    ├── func.s
    ├── main_a.s
    └── ... optional helper .s files ...
```

The harness assembles `src/func.s` and every additional `src/*.s` file except
`src/main_a.s`. This allows a solution to be split into helper assembly files
without linking the student's demonstration program into the test executable.

Each test directory contains `src/test.c`. The sorting tests (1-4) use
fixture files stored under `test_arrays/`. Tests 5-15 are self-contained and
compute their expected results directly in the test program.

## Checking a student's lab

From `poc/asm_autotests`, run the test directory that corresponds to the
student's assigned variant:

```shell
make FUNC_PATH=/absolute/path/to/student/repository/func_1 \
     TEST_DIR=5_axb_32_int \
     run
```

- `FUNC_PATH` points to the student's `func_1`, `func_2`, or `func_3`
  directory.
- `TEST_DIR` is the autotest directory for the corresponding assigned
  variant.
- Repeat the command for all three functions in the student's lab.

For example, if `func_1` is variant 5, `func_2` is variant 9, and `func_3`
is variant 15:

```shell
make FUNC_PATH=/path/to/student/repository/func_1 TEST_DIR=5_axb_32_int run
make FUNC_PATH=/path/to/student/repository/func_2 TEST_DIR=9_mean_32_uint run
make FUNC_PATH=/path/to/student/repository/func_3 TEST_DIR=15_sum_digits_32_uint run
```

The harness compiles the student's assembly sources directly. Passing these
tests therefore does not verify the student's own `makefile` or the required
C, assembly, and Python demonstration programs; check those separately.

## Building and running a test

Run `make` from this `asm_autotests` directory. Both `FUNC_PATH` and `TEST_DIR`
are required for building or running a test.

Build only:

```shell
make FUNC_PATH=/path/to/student/func_1 TEST_DIR=1_sort_32_uint all
```

Build and run:

```shell
make FUNC_PATH=/path/to/student/func_1 TEST_DIR=1_sort_32_uint run
```

The `run` target starts the executable with `TEST_DIR/bin` as its current
working directory. This preserves the relative paths used by the sorting tests
to access `test_arrays/`.

Remove generated files for one test:

```shell
make TEST_DIR=1_sort_32_uint clean
```

Validate paths without compiling:

```shell
make FUNC_PATH=/path/to/student/func_1 TEST_DIR=1_sort_32_uint check
```

By default the harness uses `gcc` as the compiler driver for both C and GAS
`.s` files. Toolchain options can be overridden on the command line, for
example with `CC`, `CFLAGS`, `ASMFLAGS`, `LDFLAGS`, and `LDLIBS`.

The tests must be built with a toolchain matching the ABI targeted by the
student implementation. For example, a Windows implementation should be tested
with the corresponding Windows/MSYS2 MINGW64 toolchain, while a Linux
implementation should be tested with a Linux toolchain.

The harness invokes `func` through the target C ABI, but passing the functional
tests is not an exhaustive ABI-conformance check. In particular, the harness
does not deliberately verify preservation of every callee-saved register, stack
alignment, or stack discipline. Check these requirements separately when
reviewing a submission.

## Test directories

The directories `1_sort_32_uint` through `15_sum_digits_32_uint` correspond to
the main task variants. The root `makefile` is the single build harness for all
of them; per-test makefiles are not used.

## Contributing

1. Check what is already covered.
2. Create an issue describing what should be added or fixed.
3. Assign the issue to yourself.
4. Add or improve the test and its test data.
