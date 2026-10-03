#include <float.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define GENERATED_COUNT 1000
#define MAX_ULP UINT32_C(4)
#define COARSE_RESIDUAL 1.0e-5L
#define GUARD_VALUE 1234567.25f
#define OUTPUT_FILL 7654321.5f

extern void func(float *a, float *b, float *x, size_t size);

static uint32_t next_u32(uint32_t *state)
{
    *state = *state * UINT32_C(1664525) + UINT32_C(1013904223);
    return *state;
}

static uint32_t float_bits(float value)
{
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static int float_is_finite(float value)
{
    return (float_bits(value) & UINT32_C(0x7f800000)) !=
           UINT32_C(0x7f800000);
}

static uint32_t ulp_distance(float a, float b)
{
    if (a == b) {
        return 0;
    }

    uint32_t ua = float_bits(a);
    uint32_t ub = float_bits(b);

    if ((ua ^ ub) & UINT32_C(0x80000000)) {
        return UINT32_MAX;
    }

    return ua > ub ? ua - ub : ub - ua;
}

static long double abs_ld(long double value)
{
    return value < 0.0L ? -value : value;
}

static long double normalized_residual(float a, float b, float x)
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
    static const float fixed_a[] = {
        3.0f, 3.0f, -3.0f, -3.0f,
        1.0f, -1.0f, 10.0f, 0.1f,
        FLT_MIN, FLT_MAX, FLT_MAX, FLT_MIN,
        1.0e10f, 1.0e30f,
        16777216.0f, 16777215.0f
    };
    static const float fixed_b[] = {
        8.0f, -8.0f, 8.0f, -8.0f,
        0.0f, 0.0f, 1.0f, 1.0f,
        FLT_MIN, FLT_MAX, -FLT_MAX, -FLT_MIN,
        1.0e30f, 1.0e10f,
        16777215.0f, 16777216.0f
    };
    static const float scales[] = {
        1.0e-20f, 1.0e-10f, 1.0f, 1.0e10f, 1.0e20f
    };

    enum { FIXED_COUNT = sizeof(fixed_a) / sizeof(fixed_a[0]) };
    enum { SCALE_COUNT = sizeof(scales) / sizeof(scales[0]) };
    enum { COUNT = FIXED_COUNT + GENERATED_COUNT };

    float a_storage[COUNT + 2];
    float b_storage[COUNT + 2];
    float x_storage[COUNT + 2];
    float a_copy[COUNT];
    float b_copy[COUNT];

    float *a = &a_storage[1];
    float *b = &b_storage[1];
    float *x = &x_storage[1];

    a_storage[0] = b_storage[0] = x_storage[0] = GUARD_VALUE;
    a_storage[COUNT + 1] = b_storage[COUNT + 1] =
        x_storage[COUNT + 1] = GUARD_VALUE;

    memcpy(a, fixed_a, sizeof(fixed_a));
    memcpy(b, fixed_b, sizeof(fixed_b));

    uint32_t state = UINT32_C(0x4f1bbcdc);
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

        float scale = scales[(i - FIXED_COUNT) % SCALE_COUNT];
        a[i] = (float)av * scale;
        b[i] = (float)bv * scale;
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
        float expected = -b_copy[i] / a_copy[i];
        float actual = x[i];

        if (!float_is_finite(expected)) {
            fprintf(stderr,
                    "INTERNAL TEST ERROR: case %zu produced non-finite expected value\n",
                    i);
            return 2;
        }

        if (!float_is_finite(actual)) {
            fprintf(stderr,
                    "ERROR: case %zu: a=%a, b=%a, expected=%a, actual=%a; "
                    "student result is NaN or infinity\n",
                    i, (double)a_copy[i], (double)b_copy[i],
                    (double)expected, (double)actual);
            return 1;
        }

        uint32_t ulps = ulp_distance(actual, expected);
        if (ulps <= MAX_ULP) {
            continue;
        }

        long double residual =
            normalized_residual(a_copy[i], b_copy[i], actual);

        fprintf(stderr,
                "ERROR: case %zu\n"
                "  a        = %a\n"
                "  b        = %a\n"
                "  expected = %a (0x%08" PRIx32 ")\n"
                "  actual   = %a (0x%08" PRIx32 ")\n",
                i,
                (double)a_copy[i],
                (double)b_copy[i],
                (double)expected, float_bits(expected),
                (double)actual, float_bits(actual));

        if (ulps == UINT32_MAX) {
            fprintf(stderr, "  ULP diff = opposite signs\n");
        } else {
            fprintf(stderr, "  ULP diff = %" PRIu32 "\n", ulps);
        }

        fprintf(stderr, "  residual = %.3Le\n", residual);

        if (residual <= COARSE_RESIDUAL) {
            fprintf(stderr,
                    "  Result is numerically close, but exceeds the allowed "
                    "%" PRIu32 " ULP.\n",
                    MAX_ULP);
        } else {
            fprintf(stderr, "  Result is not sufficiently close to a solution.\n");
        }

        return 1;
    }

    printf("All tests passed successfully.\n");
    return 0;
}
