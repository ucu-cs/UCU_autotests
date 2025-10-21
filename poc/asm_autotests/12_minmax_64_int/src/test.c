//
// Created by rediskajunior on 10/15/25.
//

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

const double EPSILON = 1e-6;

void func(int64_t *input_array, size_t size, int64_t *min, int64_t *max, double *mean, double *variance);
// { test function
//     int64_t local_min = input_array[0];
//     int64_t local_max = input_array[0];
//     double sum = 0.0;
//
//     for (size_t i = 0; i < size; ++i) {
//         if (input_array[i] < local_min) local_min = input_array[i];
//         if (input_array[i] > local_max) local_max = input_array[i];
//         sum += (double)input_array[i];
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

void read_file_int64(int64_t *array, const size_t size, const char *filename) {
  FILE *file = fopen(filename, "r");
  if (file == NULL) {
    perror("Cannot open file");
    exit(9);
  }

  for (size_t i = 0; i < size; ++i) {
    if (fscanf(file, "%lld", &array[i]) != 1) { // use %lld for int64_t
      fprintf(stderr, "Error reading element %zu from %s\n", i, filename);
      fclose(file);
      exit(10);
    }
  }
  fclose(file);
}

void read_file_int64_single(int64_t *value, const char *filename) {
  FILE *file = fopen(filename, "r");
  if (file == NULL) {
    perror("Cannot open file");
    exit(9);
  }

  if (fscanf(file, "%lld", value) != 1) {
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
  const size_t SIZE = 64;
  int64_t input[SIZE], input_copy[SIZE];
  int64_t min = 0, max = 0, min_right = 0, max_right = 0;
  double mean = 0.0, variance = 0.0;
  double mean_right = 0.0, variance_right = 0.0;

  read_file_int64(input, SIZE,
                  "../../test_arrays/12_minmax_64int/input_64int.lst");
  read_file_int64_single(&min_right,
                  "../../test_arrays/12_minmax_64int/min_64int.lst");
  read_file_int64_single(&max_right,
                  "../../test_arrays/12_minmax_64int/max_64int.lst");
  read_file_double(&mean_right,
                  "../../test_arrays/12_minmax_64int/mean_64int.lst");
  read_file_double(&variance_right,
                  "../../test_arrays/12_minmax_64int/var_64int.lst");

  memcpy(input_copy, input, SIZE * sizeof(int64_t));

  // Run tested function
  func(input, SIZE, &min, &max, &mean, &variance);

  // Validate
  if (min != min_right) {
    printf("ERROR: expected min = %lld, got %lld\n", min_right, min);
    exit(1);
  }
  if (max != max_right) {
    printf("ERROR: expected max = %lld, got %lld\n", max_right, max);
    exit(1);
  }
  if (fabs(mean - mean_right) > EPSILON) {
    printf("ERROR: expected mean = %lf, got %lf\n", mean_right, mean);
    exit(1);
  }
  if (fabs(variance - variance_right) > EPSILON) {
    printf("ERROR: expected variance = %lf, got %lf\n", variance_right,
           variance);
    exit(1);
  }

  printf("All tests passed successfully.\n");
  return 0;
}