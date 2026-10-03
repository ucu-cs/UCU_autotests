#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void func(int32_t *input_array, size_t size);

static const int32_t LEFT_GUARD = INT32_C(0x13579BDF);
static const int32_t RIGHT_GUARD = -INT32_C(0x1234567);

static int read_file(int32_t *array, size_t size, const char *filename)
{
    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        fprintf(stderr, "FAIL: cannot open %s\n", filename);
        return 0;
    }

    for (size_t i = 0; i < size; ++i) {
        if (fscanf(file, "%" SCNd32, &array[i]) != 1) {
            fprintf(stderr, "FAIL: cannot read element %zu from %s\n", i, filename);
            fclose(file);
            return 0;
        }
    }

    fclose(file);
    return 1;
}

static int run_case(const char *name, const int32_t *input,
                    const int32_t *expected, size_t size)
{
    int32_t *storage = malloc((size + 2) * sizeof(*storage));
    if (storage == NULL) {
        fprintf(stderr, "FAIL [%s]: allocation failed\n", name);
        return 0;
    }

    storage[0] = LEFT_GUARD;
    storage[size + 1] = RIGHT_GUARD;
    if (size != 0) {
        memcpy(storage + 1, input, size * sizeof(*input));
    }

    func(storage + 1, size);

    if (storage[0] != LEFT_GUARD || storage[size + 1] != RIGHT_GUARD) {
        fprintf(stderr, "FAIL [%s]: wrote outside the array bounds\n", name);
        free(storage);
        return 0;
    }

    for (size_t i = 0; i < size; ++i) {
        if (storage[i + 1] != expected[i]) {
            fprintf(stderr, "FAIL [%s] at index %zu: got %" PRId32 ", expected %" PRId32 "\n",
                    name, i, storage[i + 1], expected[i]);
            free(storage);
            return 0;
        }
    }

    free(storage);
    return 1;
}

static int run_file_case(const char *name, size_t size,
                         const char *input_filename,
                         const char *expected_filename)
{
    int32_t *input = malloc(size * sizeof(*input));
    int32_t *expected = malloc(size * sizeof(*expected));
    if (input == NULL || expected == NULL) {
        fprintf(stderr, "FAIL [%s]: allocation failed\n", name);
        free(input);
        free(expected);
        return 0;
    }

    int ok = read_file(input, size, input_filename) &&
             read_file(expected, size, expected_filename);
    if (ok) {
        ok = run_case(name, input, expected, size);
    }

    free(input);
    free(expected);
    return ok;
}

int main(void)
{
    const int32_t case_1_input[] = { -INT32_C(1) };
    const int32_t case_1_expected[] = { -INT32_C(1) };
    const int32_t case_2_input[] = { INT32_MIN, -INT32_C(100), INT32_C(0), INT32_C(100), INT32_MAX };
    const int32_t case_2_expected[] = { INT32_MIN, -INT32_C(100), INT32_C(0), INT32_C(100), INT32_MAX };
    const int32_t case_3_input[] = { INT32_MAX, INT32_C(100), INT32_C(0), -INT32_C(100), INT32_MIN };
    const int32_t case_3_expected[] = { INT32_MIN, -INT32_C(100), INT32_C(0), INT32_C(100), INT32_MAX };
    const int32_t case_4_input[] = { INT32_C(0), -INT32_C(1), INT32_C(0), INT32_MIN, INT32_MAX, -INT32_C(1) };
    const int32_t case_4_expected[] = { INT32_MIN, -INT32_C(1), -INT32_C(1), INT32_C(0), INT32_C(0), INT32_MAX };

    int ok = 1;
    ok &= run_case("size 0", NULL, NULL, 0);
    ok &= run_case("single", case_1_input, case_1_expected,
                   sizeof(case_1_input) / sizeof(case_1_input[0]));
    ok &= run_case("already sorted", case_2_input, case_2_expected,
                   sizeof(case_2_input) / sizeof(case_2_input[0]));
    ok &= run_case("reverse", case_3_input, case_3_expected,
                   sizeof(case_3_input) / sizeof(case_3_input[0]));
    ok &= run_case("duplicates", case_4_input, case_4_expected,
                   sizeof(case_4_input) / sizeof(case_4_input[0]));
    ok &= run_file_case("fixture 10", 10,
                        "../../test_arrays/2_sort_32_int/array_10el_int32_t.txt",
                        "../../test_arrays/2_sort_32_int/array_sorted_10el_int32_t.txt");
    ok &= run_file_case("fixture 100", 100,
                        "../../test_arrays/2_sort_32_int/array_100el_int32_t.txt",
                        "../../test_arrays/2_sort_32_int/array_sorted_100el_int32_t.txt");
    ok &= run_file_case("fixture 1000", 1000,
                        "../../test_arrays/2_sort_32_int/array_1000el_int32_t.txt",
                        "../../test_arrays/2_sort_32_int/array_sorted_1000el_int32_t.txt");

    if (!ok) {
        return EXIT_FAILURE;
    }

    puts("All tests passed successfully.");
    return EXIT_SUCCESS;
}
