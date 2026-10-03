#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

#define GENERATED_COUNT 1000

extern uint32_t func(uint32_t number);

static uint32_t next_u32(uint32_t *state)
{
    *state = *state * UINT32_C(1664525) + UINT32_C(1013904223);
    return *state;
}

static uint32_t digit_sum(uint32_t number)
{
    uint32_t sum = 0;

    do {
        sum += number % UINT32_C(10);
        number /= UINT32_C(10);
    } while (number != 0);

    return sum;
}

static int check_value(const char *group, size_t index, uint32_t value)
{
    uint32_t expected = digit_sum(value);
    uint32_t actual = func(value);

    if (actual != expected) {
        fprintf(stderr,
                "ERROR: %s[%zu]: input=%" PRIu32
                ", expected=%" PRIu32 ", got=%" PRIu32 "\n",
                group, index, value, expected, actual);
        return 1;
    }

    return 0;
}

int main(void)
{
    static const uint32_t fixed_values[] = {
        0,
        1,
        5,
        9,
        10,
        19,
        99,
        100,
        101,
        999,
        1000,
        12345,
        99999,
        UINT32_C(1000000000),
        UINT32_C(1111111111),
        UINT32_C(2000000000),
        UINT32_C(2147483647),
        UINT32_C(4000000000),
        UINT32_C(4040404040),
        UINT32_C(987654321),
        UINT32_C(4294967290),
        UINT32_MAX
    };

    for (size_t i = 0;
         i < sizeof(fixed_values) / sizeof(fixed_values[0]);
         ++i) {
        if (check_value("fixed", i, fixed_values[i]) != 0) {
            return 1;
        }
    }

    uint32_t state = UINT32_C(0xd1b54a35);

    for (size_t i = 0; i < GENERATED_COUNT; ++i) {
        uint32_t value = next_u32(&state);

        if (check_value("generated", i, value) != 0) {
            return 1;
        }
    }

    printf("All tests passed successfully.\n");
    return 0;
}
