#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define MAX_COUNT 257
#define INPUT_GUARD UINT32_C(0xa5c39e17)
#define OUTPUT_GUARD UINT8_C(0xa5)
#define OUTPUT_FILL UINT8_C(0xcc)

extern void func(uint32_t *input_array, uint8_t *is_prime_array, size_t size);

static uint32_t next_u32(uint32_t *state)
{
    *state = *state * UINT32_C(1664525) + UINT32_C(1013904223);
    return *state;
}

static uint8_t is_prime_u64(uint64_t n)
{
    if (n < 2) {
        return 0;
    }
    if (n <= 3) {
        return 1;
    }
    if ((n & UINT64_C(1)) == 0) {
        return 0;
    }

    for (uint64_t d = 3; d <= n / d; d += 2) {
        if (n % d == 0) {
            return 0;
        }
    }

    return 1;
}

static int run_case(const char *name, const uint32_t *values, size_t size)
{
    uint32_t input_storage[MAX_COUNT + 2];
    uint32_t input_copy[MAX_COUNT];
    uint8_t output_storage[MAX_COUNT + 2];

    if (size == 0 || size > MAX_COUNT) {
        fprintf(stderr, "INTERNAL TEST ERROR: invalid size in %s\n", name);
        return 2;
    }

    input_storage[0] = INPUT_GUARD;
    input_storage[size + 1] = INPUT_GUARD;
    memcpy(&input_storage[1], values, size * sizeof(values[0]));
    memcpy(input_copy, values, size * sizeof(values[0]));

    output_storage[0] = OUTPUT_GUARD;
    output_storage[size + 1] = OUTPUT_GUARD;
    memset(&output_storage[1], OUTPUT_FILL, size);

    func(&input_storage[1], &output_storage[1], size);

    if (input_storage[0] != INPUT_GUARD ||
        input_storage[size + 1] != INPUT_GUARD) {
        fprintf(stderr, "ERROR: %s: function wrote outside the input array\n", name);
        return 1;
    }

    if (memcmp(&input_storage[1], input_copy,
               size * sizeof(input_copy[0])) != 0) {
        fprintf(stderr, "ERROR: %s: function modified the input array\n", name);
        return 1;
    }

    if (output_storage[0] != OUTPUT_GUARD ||
        output_storage[size + 1] != OUTPUT_GUARD) {
        fprintf(stderr, "ERROR: %s: function wrote outside the output array\n", name);
        return 1;
    }

    for (size_t i = 0; i < size; ++i) {
        uint8_t expected = is_prime_u64(input_copy[i]);
        uint8_t actual = output_storage[i + 1];

        if (actual != expected) {
            fprintf(stderr,
                    "ERROR: %s: input[%zu] = %" PRIu32
                    ", expected %u, got %u\n",
                    name, i, input_copy[i],
                    (unsigned)expected, (unsigned)actual);
            return 1;
        }
    }

    return 0;
}

int main(void)
{
    static const uint32_t old_values[] = {
        0, 1, 2, 3, 4, 5, 6, 7,
        8, 9, 10, 11, 12, 13, 14, 15,
        16, 17, 18, 19, 20, 21, 22, 23,
        24, 25, 26, 27, 28, 29, 30, 31
    };

    static const uint32_t edge_values[] = {
        37, 41, 49, 97, 121, 127, 169, 221,
        341, 561, 1105, 1729, 2465, 2821, 6601,
        65521, 65537, 104729,
        UINT32_C(2147483646),
        UINT32_C(2147483647),
        UINT32_C(3215031751),
        UINT32_C(4000000007),
        UINT32_C(4293001441),
        UINT32_C(4294967290),
        UINT32_MAX
    };

    uint32_t generated[MAX_COUNT];
    uint32_t state = UINT32_C(0x6ac690c5);
    for (size_t i = 0; i < MAX_COUNT; ++i) {
        generated[i] = next_u32(&state) % UINT32_C(2000001);
    }

    if (run_case("old 0..31 values", old_values,
                 sizeof(old_values) / sizeof(old_values[0])) != 0 ||
        run_case("edge values", edge_values,
                 sizeof(edge_values) / sizeof(edge_values[0])) != 0 ||
        run_case("generated values", generated, MAX_COUNT) != 0) {
        return 1;
    }

    printf("All tests passed successfully.\n");
    return 0;
}
