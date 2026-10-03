#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define GENERATED_COUNT 1000
#define GUARD_BEFORE INT32_C(0x13579bdf)
#define GUARD_AFTER  INT32_C(0x2468ace0)
#define OUTPUT_FILL  INT32_C(0x5a5a5a5a)

extern void func(int32_t *a, int32_t *b, int32_t *x, size_t size);

static uint32_t next_u32(uint32_t *state)
{
    *state = *state * UINT32_C(1664525) + UINT32_C(1013904223);
    return *state;
}

static int32_t expected_solution(int32_t a, int32_t b)
{
    int64_t numerator = -(int64_t)b;
    int64_t result = numerator / (int64_t)a;
    return (int32_t)result;
}

int main(void)
{
    static const int32_t fixed_a[] = {
        3, 3, -3, -3, 1, -1, INT32_MAX, INT32_MIN,
        INT32_MAX, INT32_MIN, 2, -2
    };
    static const int32_t fixed_b[] = {
        8, -8, 8, -8, INT32_MAX, INT32_MIN, INT32_MIN, INT32_MAX,
        INT32_MAX, INT32_MIN, INT32_MIN, INT32_MIN
    };

    enum { FIXED_COUNT = sizeof(fixed_a) / sizeof(fixed_a[0]) };
    enum { COUNT = FIXED_COUNT + GENERATED_COUNT };

    int32_t a_storage[COUNT + 2];
    int32_t b_storage[COUNT + 2];
    int32_t x_storage[COUNT + 2];
    int32_t a_copy[COUNT];
    int32_t b_copy[COUNT];

    int32_t *a = &a_storage[1];
    int32_t *b = &b_storage[1];
    int32_t *x = &x_storage[1];

    a_storage[0] = b_storage[0] = x_storage[0] = GUARD_BEFORE;
    a_storage[COUNT + 1] = b_storage[COUNT + 1] =
        x_storage[COUNT + 1] = GUARD_AFTER;

    memcpy(a, fixed_a, sizeof(fixed_a));
    memcpy(b, fixed_b, sizeof(fixed_b));

    uint32_t state = UINT32_C(0x6d2b79f5);
    for (size_t i = FIXED_COUNT; i < COUNT; ++i) {
        int32_t av = (int32_t)(next_u32(&state) % UINT32_C(2000000001))
                   - INT32_C(1000000000);
        int32_t bv = (int32_t)(next_u32(&state) % UINT32_C(2000000001))
                   - INT32_C(1000000000);

        if (av == 0) {
            av = 1;
        }

        a[i] = av;
        b[i] = bv;
    }

    memcpy(a_copy, a, sizeof(a_copy));
    memcpy(b_copy, b, sizeof(b_copy));

    for (size_t i = 0; i < COUNT; ++i) {
        x[i] = OUTPUT_FILL;
    }

    func(a, b, x, COUNT);

    if (a_storage[0] != GUARD_BEFORE ||
        b_storage[0] != GUARD_BEFORE ||
        x_storage[0] != GUARD_BEFORE ||
        a_storage[COUNT + 1] != GUARD_AFTER ||
        b_storage[COUNT + 1] != GUARD_AFTER ||
        x_storage[COUNT + 1] != GUARD_AFTER) {
        fprintf(stderr, "ERROR: function wrote outside an array boundary\n");
        return 1;
    }

    if (memcmp(a, a_copy, sizeof(a_copy)) != 0 ||
        memcmp(b, b_copy, sizeof(b_copy)) != 0) {
        fprintf(stderr, "ERROR: function modified an input array\n");
        return 1;
    }

    for (size_t i = 0; i < COUNT; ++i) {
        int32_t expected = expected_solution(a_copy[i], b_copy[i]);

        if (x[i] != expected) {
            fprintf(stderr,
                    "ERROR: case %zu: a=%" PRId32 ", b=%" PRId32
                    ", expected x=%" PRId32 ", got %" PRId32 "\n",
                    i, a_copy[i], b_copy[i], expected, x[i]);
            return 1;
        }
    }

    printf("All tests passed successfully.\n");
    return 0;
}
