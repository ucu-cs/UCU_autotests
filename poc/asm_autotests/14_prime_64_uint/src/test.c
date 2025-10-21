//
// Created by rediskajunior on 10/15/25.
//

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

void func(uint64_t* input_array, uint8_t* is_prime_array, size_t size);
// { test function
//     for (size_t i = 0; i < size; ++i) {
//         uint64_t n = input_array[i];
//         if (n < 2) {
//             is_prime_array[i] = 0;
//             continue;
//         }
//         uint8_t prime = 1;
//         for (uint64_t d = 2; d * d <= n; ++d) {
//             if (n % d == 0) {
//                 prime = 0;
//                 break;
//             }
//         }
//         is_prime_array[i] = prime;
//     }
// }

void read_file_uint64(uint64_t *array, const size_t size, const char *filename) {
    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        perror("Cannot open input file");
        exit(9);
    }

    for (size_t i = 0; i < size; ++i) {
        if (fscanf(file, "%llu", &array[i]) != 1) {
            fprintf(stderr, "Error reading element %zu from %s\n", i, filename);
            fclose(file);
            exit(10);
        }
    }
    fclose(file);
}

void read_file_uint8(uint8_t *array, const size_t size, const char *filename) {
    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        perror("Cannot open expected file");
        exit(9);
    }

    for (size_t i = 0; i < size; ++i) {
        unsigned int temp;
        if (fscanf(file, "%u", &temp) != 1) {
            fprintf(stderr, "Error reading element %zu from %s\n", i, filename);
            fclose(file);
            exit(10);
        }
        array[i] = (uint8_t)temp;
    }
    fclose(file);
}

int main() {
    const size_t SIZE = 32;
    uint64_t input[SIZE];
    uint8_t is_prime[SIZE];
    uint8_t expected[SIZE];

    read_file_uint64(input, SIZE, "../../test_arrays/14_prime_64uint/input_64uint.lst");
    read_file_uint8(expected, SIZE, "../../test_arrays/14_prime_64uint/prime.lst");

    func(input, is_prime, SIZE);

    for (size_t i = 0; i < SIZE; ++i) {
        if (is_prime[i] != expected[i]) {
            printf("ERROR: for input[%zu] = %llu expected %u but got %u\n",
                   i, input[i], expected[i], is_prime[i]);
            exit(1);
        }
    }
    printf("All tests passed successfully.\n");
    return 0;
}
