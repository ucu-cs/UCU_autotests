//
// Created by rediskajunior on 10/15/25.
//
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

const double EPSILON = 1e-6;

void func(uint64_t* input_array, size_t size, double* harmonic_mean, double* arithmetic_mean);
// {
//     double sum = 0.0;
//     double inv_sum = 0.0;
//     for (size_t i = 0; i < size; ++i) {
//         sum += (double)input_array[i];
//         inv_sum += 1.0 / (double)input_array[i];
//     }
//     *arithmetic_mean = sum / size;
//     *harmonic_mean = size / inv_sum;
// }

void read_file_uint64(uint64_t *array, const size_t size, const char *filename) {
    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        perror("Cannot open file");
        exit(9);
    }

    for (size_t i = 0; i < size; ++i) {
        if (fscanf(file, "%llu", &array[i]) != 1) {  // use %llu for uint64_t
            fprintf(stderr, "Error reading element %zu from %s\n", i, filename);
            fclose(file);
            exit(10);
        }
    }
    fclose(file);
}

void read_file_double(double *value, const char *filename) {
    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        perror("Cannot open file");
        exit(9);
    }

    if (fscanf(file, "%lf", value) != 1) {
        fprintf(stderr, "Error reading value from %s\n", filename);
        fclose(file);
        exit(10);
    }

    fclose(file);
}

int main() {
    const size_t SIZE = 64;
    uint64_t input[SIZE], input_copy[SIZE];
    double harmonic_mean = 0.0, arithmetic_mean = 0.0;
    double harmonic_right = 0.0, arithmetic_right = 0.0;

    read_file_uint64(input, SIZE, "../../test_arrays/10_mean_64_uint/input_64uint.lst");
    read_file_double(&harmonic_right, "../../test_arrays/10_mean_64_uint/hm_64uint.lst");
    read_file_double(&arithmetic_right, "../../test_arrays/10_mean_64_uint/am_64uint.lst");

    memcpy(input_copy, input, SIZE * sizeof(uint64_t));

    func(input, SIZE, &harmonic_mean, &arithmetic_mean);

    if (fabs(harmonic_mean - harmonic_right) > EPSILON) {
        printf("ERROR: harmonic mean mismatch: expected %lf, got %lf\n",
               harmonic_right, harmonic_mean);
        exit(1);
    }

    if (fabs(arithmetic_mean - arithmetic_right) > EPSILON) {
        printf("ERROR: arithmetic mean mismatch: expected %lf, got %lf\n",
               arithmetic_right, arithmetic_mean);
        exit(1);
    }

    printf("All tests passed successfully.\n");
    return 0;
}