//
// Created by rediskajunior on 10/15/25.
//

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

const double EPSILON = 1e-6;

void func(int32_t* input_array, size_t size, int32_t* min, int32_t* max, double* mean, double* variance);
// {
//     int32_t local_min = input_array[0];
//     int32_t local_max = input_array[0];
//     double sum = 0.0;
//
//     for (size_t i = 0; i < size; ++i) {
//         if (input_array[i] < local_min) local_min = input_array[i];
//         if (input_array[i] > local_max) local_max = input_array[i];
//         sum += input_array[i];
//     }
//
//     double mean_val = sum / size;
//     double var_sum = 0.0;
//     for (size_t i = 0; i < size; ++i) {
//         double diff = input_array[i] - mean_val;
//         var_sum += diff * diff;
//     }
//
//     *min = local_min;
//     *max = local_max;
//     *mean = mean_val;
//     *variance = var_sum / size;
// }

void read_file_int32(int32_t *array, const size_t size, const char *filename) {
    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        perror("Cannot open file");
        exit(9);
    }

    for (size_t i = 0; i < size; ++i) {
        if (fscanf(file, "%d", &array[i]) != 1) {
            fprintf(stderr, "Error reading element %zu from %s\n", i, filename);
            fclose(file);
            exit(10);
        }
    }

    fclose(file);
}

void read_file_int32_single(int32_t *value, const char *filename) {
    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        perror("Cannot open file");
        exit(9);
    }

    if (fscanf(file, "%d", value) != 1) {
        fprintf(stderr, "Error reading value from %s\n", filename);
        fclose(file);
        exit(10);
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
    const size_t SIZE = 32;
    int32_t input[SIZE], input_copy[SIZE];
    int32_t min = 0, max = 0, min_right = 0, max_right = 0;
    double mean = 0.0, variance = 0.0;
    double mean_right = 0.0, variance_right = 0.0;

    read_file_int32(input, SIZE, "../../test_arrays/11_minmax_32int/input_32int.lst");
    read_file_int32_single(&min_right, "../../test_arrays/11_minmax_32int/min_32int.lst");
    read_file_int32_single(&max_right, "../../test_arrays/11_minmax_32int/max_32int.lst");
    read_file_double(&mean_right, "../../test_arrays/11_minmax_32int/mean_32int.lst");
    read_file_double(&variance_right, "../../test_arrays/11_minmax_32int/var_32int.lst");

    memcpy(input_copy, input, SIZE * sizeof(int32_t));

    func(input, SIZE, &min, &max, &mean, &variance);

    if (min != min_right) {
        printf("ERROR: expected min = %d, got %d\n", min_right, min);
        exit(1);
    }
    if (max != max_right) {
        printf("ERROR: expected max = %d, got %d\n", max_right, max);
        exit(1);
    }
    if (fabs(mean - mean_right) > EPSILON) {
        printf("ERROR: expected mean = %lf, got %lf\n", mean_right, mean);
        exit(1);
    }
    if (fabs(variance - variance_right) > EPSILON) {
        printf("ERROR: expected variance = %lf, got %lf\n", variance_right, variance);
        exit(1);
    }

    printf("All tests passed successfully.\n");
    return 0;
}