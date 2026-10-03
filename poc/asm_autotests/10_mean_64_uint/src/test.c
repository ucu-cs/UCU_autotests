#include <float.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define STRICT_FACTOR 16.0L
#define COARSE_RELATIVE 1.0e-6L
#define GUARD_U64 UINT64_C(0x13579bdf2468ace0)
#define GUARD_DOUBLE 123456789.25
#define OUTPUT_FILL 765432109.5

extern void func(uint64_t *input_array, size_t size,
                 double *harmonic_mean, double *arithmetic_mean);

static uint32_t next_u32(uint32_t *state)
{
    *state = *state * UINT32_C(1664525) + UINT32_C(1013904223);
    return *state;
}

static uint64_t next_u64(uint32_t *state)
{
    return ((uint64_t)next_u32(state) << 32) |
           (uint64_t)next_u32(state);
}

static uint64_t double_bits(double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static int double_is_finite(double value)
{
    return (double_bits(value) & UINT64_C(0x7ff0000000000000)) !=
           UINT64_C(0x7ff0000000000000);
}

static uint64_t ulp_distance(double a, double b)
{
    if (a == b) {
        return 0;
    }

    uint64_t ua = double_bits(a);
    uint64_t ub = double_bits(b);

    if ((ua ^ ub) & UINT64_C(0x8000000000000000)) {
        return UINT64_MAX;
    }

    return ua > ub ? ua - ub : ub - ua;
}

static long double abs_ld(long double value)
{
    return value < 0.0L ? -value : value;
}

static void reference_means(const uint64_t *input, size_t size,
                            long double *harmonic_mean,
                            long double *arithmetic_mean)
{
    long double sum = 0.0L;
    long double reciprocal_sum = 0.0L;

    for (size_t i = 0; i < size; ++i) {
        long double value = (long double)input[i];
        sum += value;
        reciprocal_sum += 1.0L / value;
    }

    *arithmetic_mean = sum / (long double)size;
    *harmonic_mean = (long double)size / reciprocal_sum;
}

static int check_result(const char *case_name, const char *quantity,
                        double actual, long double expected, size_t size)
{
    if (!double_is_finite(actual)) {
        fprintf(stderr,
                "ERROR: case \"%s\", %s: student result is NaN or infinity\n",
                case_name, quantity);
        return 1;
    }

    long double relative_error =
        abs_ld((long double)actual - expected) / expected;
    long double strict_limit =
        STRICT_FACTOR * (long double)(size + 4) * (long double)DBL_EPSILON;

    if (relative_error <= strict_limit) {
        return 0;
    }

    double expected_double = (double)expected;
    uint64_t ulps = ulp_distance(actual, expected_double);

    fprintf(stderr,
            "ERROR: case \"%s\", %s\n"
            "  expected         = %.21Lg\n"
            "  expected(double) = %a\n"
            "  actual           = %a\n",
            case_name, quantity, expected, expected_double, actual);

    if (ulps == UINT64_MAX) {
        fprintf(stderr, "  ULP diff         = opposite signs\n");
    } else {
        fprintf(stderr, "  ULP diff         = %" PRIu64 "\n", ulps);
    }

    fprintf(stderr,
            "  relative error   = %.3Le\n"
            "  strict limit     = %.3Le\n",
            relative_error, strict_limit);

    if (relative_error <= COARSE_RELATIVE) {
        fprintf(stderr,
                "  Result is numerically close, but exceeds the required accuracy.\n");
    } else {
        fprintf(stderr,
                "  Result is not sufficiently close to the expected mean.\n");
    }

    return 1;
}

static int run_case(const char *name, const uint64_t *values, size_t size)
{
    uint64_t input_storage[size + 2];
    uint64_t input_copy[size];
    double harmonic_storage[3] = { GUARD_DOUBLE, OUTPUT_FILL, GUARD_DOUBLE };
    double arithmetic_storage[3] = { GUARD_DOUBLE, OUTPUT_FILL, GUARD_DOUBLE };

    input_storage[0] = GUARD_U64;
    memcpy(&input_storage[1], values, size * sizeof(values[0]));
    input_storage[size + 1] = GUARD_U64;
    memcpy(input_copy, values, size * sizeof(values[0]));

    long double harmonic_expected;
    long double arithmetic_expected;
    reference_means(input_copy, size, &harmonic_expected, &arithmetic_expected);

    func(&input_storage[1], size,
         &harmonic_storage[1], &arithmetic_storage[1]);

    if (input_storage[0] != GUARD_U64 ||
        input_storage[size + 1] != GUARD_U64 ||
        harmonic_storage[0] != GUARD_DOUBLE ||
        harmonic_storage[2] != GUARD_DOUBLE ||
        arithmetic_storage[0] != GUARD_DOUBLE ||
        arithmetic_storage[2] != GUARD_DOUBLE) {
        fprintf(stderr,
                "ERROR: case \"%s\": function wrote outside an array or output\n",
                name);
        return 1;
    }

    if (memcmp(&input_storage[1], input_copy,
               size * sizeof(input_copy[0])) != 0) {
        fprintf(stderr,
                "ERROR: case \"%s\": function modified the input array\n",
                name);
        return 1;
    }

    if (check_result(name, "harmonic mean",
                     harmonic_storage[1], harmonic_expected, size) != 0) {
        return 1;
    }

    if (check_result(name, "arithmetic mean",
                     arithmetic_storage[1], arithmetic_expected, size) != 0) {
        return 1;
    }

    return 0;
}

int main(void)
{
    static const uint64_t singleton[] = { UINT64_MAX };
    static const uint64_t pair[] = { UINT64_C(1), UINT64_MAX };
    static const uint64_t equal_high_bit[] = {
        UINT64_C(0x8000000000000000),
        UINT64_C(0x8000000000000000),
        UINT64_C(0x8000000000000000),
        UINT64_C(0x8000000000000000),
        UINT64_C(0x8000000000000000)
    };
    static const uint64_t near_max[] = {
        UINT64_MAX,
        UINT64_MAX - UINT64_C(1),
        UINT64_MAX - UINT64_C(2),
        UINT64_MAX - UINT64_C(15),
        UINT64_MAX - UINT64_C(255),
        UINT64_MAX - UINT64_C(65535)
    };

    uint64_t powers[64];
    for (size_t i = 0; i < 64; ++i) {
        powers[i] = UINT64_C(1) << i;
    }

    uint64_t generated[257];
    uint32_t state = UINT32_C(0x6a09e667);
    for (size_t i = 0; i < 257; ++i) {
        generated[i] = next_u64(&state);
        if (generated[i] == 0) {
            generated[i] = 1;
        }
    }

    if (run_case("singleton UINT64_MAX", singleton,
                 sizeof(singleton) / sizeof(singleton[0])) != 0 ||
        run_case("mixed small and UINT64_MAX", pair,
                 sizeof(pair) / sizeof(pair[0])) != 0 ||
        run_case("equal values with high bit set", equal_high_bit,
                 sizeof(equal_high_bit) / sizeof(equal_high_bit[0])) != 0 ||
        run_case("powers of two", powers,
                 sizeof(powers) / sizeof(powers[0])) != 0 ||
        run_case("near UINT64_MAX", near_max,
                 sizeof(near_max) / sizeof(near_max[0])) != 0 ||
        run_case("deterministic generated", generated,
                 sizeof(generated) / sizeof(generated[0])) != 0) {
        return 1;
    }

    printf("All tests passed successfully.\n");
    return 0;
}
