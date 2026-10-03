#include <float.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define GENERATED_COUNT 1000
#define MAX_ULP UINT64_C(4)
#define COARSE_RESIDUAL 1.0e-12L
#define GUARD_VALUE 123456789.25
#define OUTPUT_FILL 765432109.5

extern void func(double *a, double *b, double *x, size_t size);

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

static long double normalized_residual(double a, double b, double x)
{
    long double ax = (long double)a * (long double)x;
    long double numerator = abs_ld(ax + (long double)b);
    long double denominator = abs_ld(ax) + abs_ld((long double)b);

    if (denominator == 0.0L) {
        return numerator == 0.0L ? 0.0L : 1.0L;
    }

    return numerator / denominator;
}

int main(void)
{
    static const double fixed_a[] = {
        3.0, 3.0, -3.0, -3.0,
        1.0, -1.0, 10.0, 0.1,
        DBL_MIN, DBL_MAX, DBL_MAX, DBL_MIN,
        1.0e100, 1.0e300,
        9007199254740992.0, 9007199254740991.0
    };
    static const double fixed_b[] = {
        8.0, -8.0, 8.0, -8.0,
        0.0, 0.0, 1.0, 1.0,
        DBL_MIN, DBL_MAX, -DBL_MAX, -DBL_MIN,
        1.0e300, 1.0e100,
        9007199254740991.0, 9007199254740992.0
    };
    static const double scales[] = {
        1.0e-200, 1.0e-100, 1.0, 1.0e100, 1.0e200
    };

    enum { FIXED_COUNT = sizeof(fixed_a) / sizeof(fixed_a[0]) };
    enum { SCALE_COUNT = sizeof(scales) / sizeof(scales[0]) };
    enum { COUNT = FIXED_COUNT + GENERATED_COUNT };

    double a_storage[COUNT + 2];
    double b_storage[COUNT + 2];
    double x_storage[COUNT + 2];
    double a_copy[COUNT];
    double b_copy[COUNT];

    double *a = &a_storage[1];
    double *b = &b_storage[1];
    double *x = &x_storage[1];

    a_storage[0] = b_storage[0] = x_storage[0] = GUARD_VALUE;
    a_storage[COUNT + 1] = b_storage[COUNT + 1] =
        x_storage[COUNT + 1] = GUARD_VALUE;

    memcpy(a, fixed_a, sizeof(fixed_a));
    memcpy(b, fixed_b, sizeof(fixed_b));

    uint32_t state = UINT32_C(0xb5297a4d);
    for (size_t i = FIXED_COUNT; i < COUNT; ++i) {
        int32_t av = (int32_t)(next_u32(&state) % UINT32_C(2000001))
                   - INT32_C(1000000);
        int32_t bv = (int32_t)(next_u32(&state) % UINT32_C(2000001))
                   - INT32_C(1000000);

        if (av == 0) {
            av = 1;
        }
        if (i % 23 == 0) {
            bv = 0;
        }

        double scale = scales[(i - FIXED_COUNT) % SCALE_COUNT];
        a[i] = (double)av * scale;
        b[i] = (double)bv * scale;
    }

    memcpy(a_copy, a, sizeof(a_copy));
    memcpy(b_copy, b, sizeof(b_copy));

    for (size_t i = 0; i < COUNT; ++i) {
        x[i] = OUTPUT_FILL;
    }

    func(a, b, x, COUNT);

    if (a_storage[0] != GUARD_VALUE ||
        b_storage[0] != GUARD_VALUE ||
        x_storage[0] != GUARD_VALUE ||
        a_storage[COUNT + 1] != GUARD_VALUE ||
        b_storage[COUNT + 1] != GUARD_VALUE ||
        x_storage[COUNT + 1] != GUARD_VALUE) {
        fprintf(stderr, "ERROR: function wrote outside an array boundary\n");
        return 1;
    }

    if (memcmp(a, a_copy, sizeof(a_copy)) != 0 ||
        memcmp(b, b_copy, sizeof(b_copy)) != 0) {
        fprintf(stderr, "ERROR: function modified an input array\n");
        return 1;
    }

    for (size_t i = 0; i < COUNT; ++i) {
        double expected = -b_copy[i] / a_copy[i];
        double actual = x[i];

        if (!double_is_finite(expected)) {
            fprintf(stderr,
                    "INTERNAL TEST ERROR: case %zu produced non-finite expected value\n",
                    i);
            return 2;
        }

        if (!double_is_finite(actual)) {
            fprintf(stderr,
                    "ERROR: case %zu: a=%a, b=%a, expected=%a, actual=%a; "
                    "student result is NaN or infinity\n",
                    i, a_copy[i], b_copy[i], expected, actual);
            return 1;
        }

        uint64_t ulps = ulp_distance(actual, expected);
        if (ulps <= MAX_ULP) {
            continue;
        }

        long double residual =
            normalized_residual(a_copy[i], b_copy[i], actual);

        fprintf(stderr,
                "ERROR: case %zu\n"
                "  a        = %a\n"
                "  b        = %a\n"
                "  expected = %a (0x%016" PRIx64 ")\n"
                "  actual   = %a (0x%016" PRIx64 ")\n",
                i,
                a_copy[i],
                b_copy[i],
                expected, double_bits(expected),
                actual, double_bits(actual));

        if (ulps == UINT64_MAX) {
            fprintf(stderr, "  ULP diff = opposite signs\n");
        } else {
            fprintf(stderr, "  ULP diff = %" PRIu64 "\n", ulps);
        }

        fprintf(stderr, "  residual = %.3Le\n", residual);

        if (residual <= COARSE_RESIDUAL) {
            fprintf(stderr,
                    "  Result is numerically close, but exceeds the allowed "
                    "%" PRIu64 " ULP.\n",
                    MAX_ULP);
        } else {
            fprintf(stderr, "  Result is not sufficiently close to a solution.\n");
        }

        return 1;
    }

    printf("All tests passed successfully.\n");
    return 0;
}
