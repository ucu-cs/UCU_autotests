#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define SIZE 1000

void func_c(int32_t *a, int32_t *b, int32_t *x, size_t size) 
{
  for (uint32_t i = 0; i < size; i++)
  {
    // Calculate x considering that a and b have the same sign
    x[i] = -(abs(b[i]) / abs(a[i]));

    // Check which value (floor of -b/a  or ceiling of -b/a) is better
    if (abs(abs(a[i]) * x[i] + abs(b[i])) > abs(abs(a[i]) * (x[i] - 1) + abs(b[i])))
    {
      x[i]--;
    }

    // Multiply x by -1 if a and b have different signs
    if ((a[i] < 0 && b[i] > 0) || (a[i] > 0 && b[i] < 0))
    {
      x[i] *= -1;
    }
  }
}

extern void func(int32_t* a, int32_t* b, int32_t* x, size_t size);

int read_file(int32_t *input_array, size_t size, char *filename) {
	FILE *m_file;
	m_file = fopen(filename, "r");

	if (m_file == NULL) {
		return -1;
	}

	for (size_t i = 0; i < size; ++i) {
		fscanf(m_file, "%d\n", &input_array[i]);
	}

	fclose(m_file);
  return 0;
}

int main()
{
  // Read files to arrays
  int32_t a[SIZE], b[SIZE], x_right[SIZE], x_returned[SIZE];

  char *data_dir = getenv("DATA_DIR");
  if (strlen(data_dir) == 0) {
    data_dir = ".";
  }

  char name_buf[1000];

  sprintf(name_buf, "%s/%s", data_dir, "5_axb_32_int/array_1000el_a.lst");
  if (read_file(a, SIZE, name_buf) != 0) {
    fprintf(stderr, "Error opening file %s...", name_buf);
    return -1;
  }

  sprintf(name_buf, "%s/%s", data_dir, "5_axb_32_int/array_1000el_b.lst");
  if (read_file(b, SIZE, name_buf) != 0) {
    fprintf(stderr, "Error opening file %s...", name_buf);
    return -1;
  }

  sprintf(name_buf, "%s/%s", data_dir, "5_axb_32_int/array_1000el_x.lst");
  if (read_file(x_right, SIZE, name_buf) != 0) {
    fprintf(stderr, "Error opening file %s...", name_buf);
    return -1;
  }


  // Make copies of arrays in case the function somehow modifies input arrays
  int32_t a_copy[SIZE], b_copy[SIZE];
  memcpy(a_copy, a, sizeof(int32_t) * SIZE);
  memcpy(b_copy, b, sizeof(int32_t) * SIZE);
  
  // Call the assembler function
  func_c(a, b, x_returned, SIZE);

  // Check the results
  for (size_t i = 0; i < SIZE; i++)
  {
    // Check if returned value is correct or one of two esactly correct solutions
    if (x_right[i] != x_returned[i] && (abs(a[i] * x_right[i] + b[i]) != abs(a[i] * x_returned[i] + b[i]))) 
    {
      printf("ERROR: for a = %d, b = %d expected output is %d, but %d was retuned...", a_copy[i], b_copy[i], x_right[i], x_returned[i]);
      exit(1);
    }
  }
  printf("All tests passed succesfully\n");
  return 0;
}
