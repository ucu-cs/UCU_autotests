//
// Created by rediskajunior on 10/22/25.
//

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

uint32_t func(uint32_t number);
// test function
{
//     uint32_t sum = 0;
//     while (number > 0) {
//         sum += number % 10;
//         number /= 10;
//     }
//     return sum;
// }

void read_file_uint32(uint32_t *array, const size_t size, const char *filename) {
    FILE *file = fopen(filename, "r");
    if (!file) {
        perror("Cannot open input file");
        exit(1);
    }

    for (size_t i = 0; i < size; ++i) {
        if (fscanf(file, "%u", &array[i]) != 1) {
            fprintf(stderr, "Error reading element %zu from %s\n", i, filename);
            fclose(file);
            exit(2);
        }
    }

    fclose(file);
}

int main() {
    const size_t SIZE = 16;
    uint32_t input[SIZE];
    uint32_t expected[SIZE];

    read_file_uint32(input, SIZE, "../../test_arrays/15_sum_digits_32uint/input_32uint.lst");
    read_file_uint32(expected, SIZE, "../../test_arrays/15_sum_digits_32uint/output_sum.lst");

    for (size_t i = 0; i < SIZE; ++i) {
        uint32_t result = func(input[i]);
        if (result != expected[i]) {
            printf("ERROR: for input %u expected %u but got %u\n", input[i], expected[i], result);
            exit(1);
        }
    }

    printf("All tests passed successfully.\n");
    return 0;
}
