#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>


const double EPSILON = 0.1e3;

void func (double* a, double* b, double* x, size_t size);
//{
  //for (size_t i = 0; i < size; i++) {
    //x[i] = -b[i] / a[i];
  //}
//}


void read_file(double *input_array, const size_t size, const char *filename) {
    FILE *m_file;
    m_file = fopen(filename, "r");

    if (m_file == NULL) {
        exit(9);
    }

    for (size_t i = 0; i < size; ++i) {
        fscanf(m_file, "%lf\n", &input_array[i]);
    }

    fclose(m_file);
}

int main() {
  double a[1000], b[1000], x[1000], a_copy[1000], b_copy[1000], x_right[1000];

  read_file(a, 1000, "../../test_arrays/7_8_axb_float/array_1000el_a.lst");
  read_file(b, 1000, "../../test_arrays/7_8_axb_float/array_1000el_b.lst");
  read_file(x_right, 1000, "../../test_arrays/7_8_axb_float/array_1000el_x.lst");

  memcpy(a_copy, a, 1000 * sizeof(double));
  memcpy(b_copy, b, 1000 * sizeof(double));

  func(a, b, x, 1000);
  for (size_t i = 0; i < 1000; i++) {
    if (abs(x_right[i] - x[i]) > EPSILON) {
      printf("ERROR: for a = %lf, b = %lf the right answer is x = %lf, but %lf returned...\n", a_copy[i], b_copy[i], x_right[i], x[i]);
      exit(1);
    }
  }
  printf("All tests passed successfully\n");
  return 0;
}




