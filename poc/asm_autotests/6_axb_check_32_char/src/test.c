#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

void func_c (int32_t* a, int32_t* b, uint8_t* result, size_t size) {
  for (size_t i = 0; i < size; i++) {
    if (a[i] == 0) {
      if (b[i] == 0) {
        result[i] = 1;
      } else {
        result[i] = 0;
      }
    } else {
      result[i] = b[i] % a[i] == 0 ? 1 : 0;
    }
  }
}


void read_file(int32_t* input_array, size_t size, char* filename) {
	FILE *m_file;
	m_file = fopen(filename, "r");

	if (m_file == NULL) {
		exit(9);
	}

	for (size_t i = 0; i < size; ++i) {
		fscanf(m_file, "%d\n", &input_array[i]);
	}

	fclose(m_file);
}


int main() {
  int32_t a[1000], b[1000], right_answer[1000], a_copy[1000], b_copy[1000];

  read_file(a, 1000, "../../test_arrays/6_axb_check_32_char/array_1000el_a.lst");
  read_file(b, 1000, "../../test_arrays/6_axb_check_32_char/array_1000el_b.lst");
  read_file(right_answer, 1000, "../../test_arrays/6_axb_check_32_char/array_1000el_ans.lst");

  uint8_t calculated_answer[1000];
  memcpy(a_copy, a, 1000 * sizeof(int32_t));
  memcpy(b_copy, b, 1000 * sizeof(int32_t));
  
  func_c(a, b, calculated_answer, 1000);

  for (size_t i = 0; i < 1000; i++) {
    if (calculated_answer[i] != (uint8_t)right_answer[i]) {
      printf("ERROR: for a = %d and b = %d, the right answer is %d, but %d was returned\n", a_copy[i], b_copy[i], right_answer[i], calculated_answer[i]);
      exit(1);
    }
  }
  printf("All tests passed successfully\n");
  return 0;
}
