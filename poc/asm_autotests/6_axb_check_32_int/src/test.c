#include <inttypes.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define GENERATED_COUNT 1000
#define GUARD_BEFORE INT32_C(0x13579bdf)
#define GUARD_AFTER  INT32_C(0x2468ace0)
#define OUTPUT_FILL  INT32_C(0x5a5a5a5a)

extern void func(int32_t *a, int32_t *b, int32_t *result, size_t size);

static uint32_t next_u32(uint32_t *state)
{
    *state = *state * UINT32_C(1664525) + UINT32_C(1013904223);
    return *state;
}

static int32_t expected_result(int32_t a, int32_t b)
{
    if (a == 0) {
        return b == 0 ? 1 : 0;
    }

    int64_t aa = (int64_t)a;
    int64_t bb = (int64_t)b;

    if (bb % aa != 0) {
        return 0;
    }

    int64_t x = -bb / aa;
    if (x < INT32_MIN || x > INT32_MAX) {
        fprintf(stderr,
                "INTERNAL TEST ERROR: exact solution is outside int32_t\n");
        return -1;
    }

    return 1;
}

int main(void)
{
    static const int32_t fixed_a[] = {
        0, 0, 0, 1, -1, 3, 3, -3, -3,
        INT32_MIN, -1, INT32_MAX, INT32_MAX, 2, 2
    };
    static const int32_t fixed_b[] = {
        0, 1, -1, 0, 0, 9, 8, 9, 8,
        INT32_MIN, INT32_MIN, INT32_MIN, INT32_MAX, INT32_MAX, INT32_MIN
    };

    enum { FIXED_COUNT = sizeof(fixed_a) / sizeof(fixed_a[0]) };
    enum { COUNT = FIXED_COUNT + GENERATED_COUNT };

    int32_t a_storage[COUNT + 2];
    int32_t b_storage[COUNT + 2];
    int32_t result_storage[COUNT + 2];
    int32_t a_copy[COUNT];
    int32_t b_copy[COUNT];

    int32_t *a = &a_storage[1];
    int32_t *b = &b_storage[1];
    int32_t *result = &result_storage[1];

    a_storage[0] = b_storage[0] = result_storage[0] = GUARD_BEFORE;
    a_storage[COUNT + 1] = b_storage[COUNT + 1] =
        result_storage[COUNT + 1] = GUARD_AFTER;

    memcpy(a, fixed_a, sizeof(fixed_a));
    memcpy(b, fixed_b, sizeof(fixed_b));

    uint32_t state = UINT32_C(0xa5a5f00d);
    for (size_t i = FIXED_COUNT; i < COUNT; ++i) {
        int32_t av;
        int32_t bv;

        if (i % 19 == 0) {
            av = 0;
            bv = (i % 38 == 0) ? 0 : 1;
        } else {
            av = (int32_t)(next_u32(&state) % UINT32_C(2000000001))
               - INT32_C(1000000000);
            if (av == 0) {
                av = 1;
            }

            if (i % 2 == 0) {
                int32_t q = (int32_t)(next_u32(&state) % UINT32_C(1001))
                          - INT32_C(500);
                int64_t generated_b = -(int64_t)av * (int64_t)q;

                if (generated_b >= INT32_MIN && generated_b <= INT32_MAX) {
                    bv = (int32_t)generated_b;
                } else {
                    bv = (int32_t)(next_u32(&state) % UINT32_C(2000000001))
                       - INT32_C(1000000000);
                }
            } else {
                bv = (int32_t)(next_u32(&state) % UINT32_C(2000000001))
                   - INT32_C(1000000000);
            }
        }

        a[i] = av;
        b[i] = bv;
    }

    memcpy(a_copy, a, sizeof(a_copy));
    memcpy(b_copy, b, sizeof(b_copy));

    for (size_t i = 0; i < COUNT; ++i) {
        result[i] = OUTPUT_FILL;
    }

    func(a, b, result, COUNT);

    if (a_storage[0] != GUARD_BEFORE ||
        b_storage[0] != GUARD_BEFORE ||
        result_storage[0] != GUARD_BEFORE ||
        a_storage[COUNT + 1] != GUARD_AFTER ||
        b_storage[COUNT + 1] != GUARD_AFTER ||
        result_storage[COUNT + 1] != GUARD_AFTER) {
        fprintf(stderr, "ERROR: function wrote outside an array boundary\n");
        return 1;
    }

    if (memcmp(a, a_copy, sizeof(a_copy)) != 0 ||
        memcmp(b, b_copy, sizeof(b_copy)) != 0) {
        fprintf(stderr, "ERROR: function modified an input array\n");
        return 1;
    }

    for (size_t i = 0; i < COUNT; ++i) {
        int32_t expected = expected_result(a_copy[i], b_copy[i]);
        if (expected < 0) {
            return 2;
        }

        if (result[i] != expected) {
            fprintf(stderr,
                    "ERROR: case %zu: a=%" PRId32 ", b=%" PRId32
                    ", expected %" PRId32 ", got %" PRId32 "\n",
                    i, a_copy[i], b_copy[i], expected, result[i]);
            return 1;
        }
    }

    printf("All tests passed successfully.\n");
    return 0;
}
