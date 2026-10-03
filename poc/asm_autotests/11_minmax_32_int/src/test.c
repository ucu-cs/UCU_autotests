#include <float.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define MAX_COUNT 257
#define MEAN_FACTOR 32.0L
#define VARIANCE_FACTOR 128.0L
#define COARSE_RELATIVE 1.0e-6L
#define GUARD_I32 INT32_C(0x13579bdf)
#define OUTPUT_I32 INT32_C(0x2468ace)
#define GUARD_DOUBLE 123456789.25
#define OUTPUT_DOUBLE 765432109.5

extern void func(int32_t *input_array, size_t size,
                 int32_t *min, int32_t *max,
                 double *mean, double *variance);

static uint32_t next_u32(uint32_t *state)
{
    *state = *state * UINT32_C(1664525) + UINT32_C(1013904223);
    return *state;
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

static int check_double(const char *case_name, const char *quantity,
                        double actual, long double expected,
                        long double scale, long double factor,
                        size_t size)
{
    if (!double_is_finite(actual)) {
        fprintf(stderr,
                "ERROR: %s: %s is NaN or infinity\n",
                case_name, quantity);
        return 1;
    }

    long double error = abs_ld((long double)actual - expected);
    if (scale < 1.0L) {
        scale = 1.0L;
    }

    long double tolerance =
        factor * ((long double)size + 8.0L) * (long double)DBL_EPSILON * scale;

    if (error <= tolerance) {
        return 0;
    }

    double expected_double = (double)expected;
    uint64_t ulps = ulp_distance(actual, expected_double);
    long double coarse_tolerance = COARSE_RELATIVE * scale;

    fprintf(stderr,
            "ERROR: %s: %s mismatch\n"
            "  expected      = %.17Lg\n"
            "  actual        = %.17g\n"
            "  absolute err  = %.3Le\n"
            "  allowed err   = %.3Le\n",
            case_name, quantity, expected, actual, error, tolerance);

    if (ulps == UINT64_MAX) {
        fprintf(stderr, "  ULP diff      = opposite signs\n");
    } else {
        fprintf(stderr, "  ULP diff      = %" PRIu64 "\n", ulps);
    }

    if (error <= coarse_tolerance) {
        fprintf(stderr,
                "  Result is numerically close, but does not meet the "
                "required double-precision accuracy.\n");
    } else {
        fprintf(stderr, "  Result is not sufficiently close to the expected value.\n");
    }

    return 1;
}

static int run_case(const char *name, const int32_t *values, size_t size)
{
    int32_t input_storage[MAX_COUNT + 2];
    int32_t input_copy[MAX_COUNT];

    int32_t min_storage[3] = { GUARD_I32, OUTPUT_I32, GUARD_I32 };
    int32_t max_storage[3] = { GUARD_I32, OUTPUT_I32, GUARD_I32 };
    double mean_storage[3] = {
        GUARD_DOUBLE, OUTPUT_DOUBLE, GUARD_DOUBLE
    };
    double variance_storage[3] = {
        GUARD_DOUBLE, OUTPUT_DOUBLE, GUARD_DOUBLE
    };

    if (size == 0 || size > MAX_COUNT) {
        fprintf(stderr, "INTERNAL TEST ERROR: invalid size in %s\n", name);
        return 2;
    }

    input_storage[0] = GUARD_I32;
    input_storage[size + 1] = GUARD_I32;
    memcpy(&input_storage[1], values, size * sizeof(values[0]));
    memcpy(input_copy, values, size * sizeof(values[0]));

    int32_t expected_min = values[0];
    int32_t expected_max = values[0];
    long double sum = 0.0L;
    long double abs_sum = 0.0L;

    for (size_t i = 0; i < size; ++i) {
        if (values[i] < expected_min) {
            expected_min = values[i];
        }
        if (values[i] > expected_max) {
            expected_max = values[i];
        }

        long double value = (long double)values[i];
        sum += value;
        abs_sum += abs_ld(value);
    }

    long double expected_mean = sum / (long double)size;
    long double variance_sum = 0.0L;

    for (size_t i = 0; i < size; ++i) {
        long double diff = (long double)values[i] - expected_mean;
        variance_sum += diff * diff;
    }

    long double expected_variance = variance_sum / (long double)size;
    long double mean_scale = abs_sum / (long double)size;
    long double variance_scale = abs_ld(expected_variance);

    func(&input_storage[1], size,
         &min_storage[1], &max_storage[1],
         &mean_storage[1], &variance_storage[1]);

    if (input_storage[0] != GUARD_I32 ||
        input_storage[size + 1] != GUARD_I32) {
        fprintf(stderr, "ERROR: %s: function wrote outside the input array\n", name);
        return 1;
    }

    if (memcmp(&input_storage[1], input_copy,
               size * sizeof(input_copy[0])) != 0) {
        fprintf(stderr, "ERROR: %s: function modified the input array\n", name);
        return 1;
    }

    if (min_storage[0] != GUARD_I32 || min_storage[2] != GUARD_I32 ||
        max_storage[0] != GUARD_I32 || max_storage[2] != GUARD_I32 ||
        mean_storage[0] != GUARD_DOUBLE || mean_storage[2] != GUARD_DOUBLE ||
        variance_storage[0] != GUARD_DOUBLE ||
        variance_storage[2] != GUARD_DOUBLE) {
        fprintf(stderr, "ERROR: %s: function wrote outside an output object\n", name);
        return 1;
    }

    if (min_storage[1] != expected_min) {
        fprintf(stderr,
                "ERROR: %s: min mismatch: expected %" PRId32
                ", got %" PRId32 "\n",
                name, expected_min, min_storage[1]);
        return 1;
    }

    if (max_storage[1] != expected_max) {
        fprintf(stderr,
                "ERROR: %s: max mismatch: expected %" PRId32
                ", got %" PRId32 "\n",
                name, expected_max, max_storage[1]);
        return 1;
    }

    if (check_double(name, "mean", mean_storage[1], expected_mean,
                     mean_scale, MEAN_FACTOR, size) != 0) {
        return 1;
    }

    if (check_double(name, "variance", variance_storage[1],
                     expected_variance, variance_scale,
                     VARIANCE_FACTOR, size) != 0) {
        return 1;
    }

    return 0;
}

int main(void)
{
    static const int32_t singleton[] = { 42 };
    static const int32_t pair[] = { -1, 1 };
    static const int32_t equal_values[] = {
        123456789, 123456789, 123456789, 123456789
    };
    static const int32_t mixed_extremes[] = {
        INT32_MIN, INT32_MAX, -1000000000, -1, 0, 1, 1000000000
    };

    int32_t progression[32];
    for (size_t i = 0; i < 32; ++i) {
        progression[i] = -10 + (int32_t)(5 * i);
    }

    int32_t generated[MAX_COUNT];
    uint32_t state = UINT32_C(0x91e10da5);
    for (size_t i = 0; i < MAX_COUNT; ++i) {
        generated[i] =
            (int32_t)(next_u32(&state) % UINT32_C(2000000001))
            - INT32_C(1000000000);
    }

    if (run_case("singleton", singleton,
                 sizeof(singleton) / sizeof(singleton[0])) != 0 ||
        run_case("pair", pair, sizeof(pair) / sizeof(pair[0])) != 0 ||
        run_case("equal values", equal_values,
                 sizeof(equal_values) / sizeof(equal_values[0])) != 0 ||
        run_case("old progression", progression,
                 sizeof(progression) / sizeof(progression[0])) != 0 ||
        run_case("mixed extremes", mixed_extremes,
                 sizeof(mixed_extremes) / sizeof(mixed_extremes[0])) != 0 ||
        run_case("generated", generated, MAX_COUNT) != 0) {
        return 1;
    }

    printf("All tests passed successfully.\n");
    return 0;
}
