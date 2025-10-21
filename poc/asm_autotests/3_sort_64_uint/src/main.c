#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

// exit 8 - null ptr in sorting
// exit 9 - opening file error
// exit 10 - function is not working properly

int cmpfunc(const void *a, const void *b) {
    const uint64_t *pa = a;
    const uint64_t *pb = b;
    if (*pa < *pb) { return -1; }
    else if (*pa == *pb) { return 0; }
    else { return 1; }
}

void func(uint64_t *input_array, size_t array_size);
//{
  //  qsort(input_array, array_size, sizeof(uint64_t), cmpfunc);
//}

void read_file(uint64_t *input_array, const size_t size, const char *filename) {
    FILE *m_file;
    m_file = fopen(filename, "r");

    if (m_file == NULL) {
        exit(9);
    }

    for (size_t i = 0; i < size; ++i) {
        fscanf(m_file, "%zu\n", &input_array[i]);
    }

    fclose(m_file);
}


int main() {

    uint64_t m_empty[0] = {};
    uint64_t m_array_1[1] = {255};
    uint64_t m_array_10[10];
    uint64_t m_array_100[100];
    uint64_t m_array_1000[1000];

    uint64_t m_sorted_array_1[1] = {255};
    uint64_t m_sorted_array_10[10];
    uint64_t m_sorted_array_100[100];
    uint64_t m_sorted_array_1000[1000];

    read_file(m_array_10, 10, "../../test_arrays/3_sort_64_uint/array_10el_uint64_t.txt");
    read_file(m_array_100, 100, "../../test_arrays/3_sort_64_uint/array_100el_uint64_t.txt");
    read_file(m_array_1000, 1000, "../../test_arrays/3_sort_64_uint/array_1000el_uint64_t.txt");
    read_file(m_sorted_array_10, 10, "../../test_arrays/3_sort_64_uint/array_sorted_10el_uint64_t.txt");
    read_file(m_sorted_array_100, 100, "../../test_arrays/3_sort_64_uint/array_sorted_100el_uint64_t.txt");
    read_file(m_sorted_array_1000, 1000, "../../test_arrays/3_sort_64_uint/array_sorted_1000el_uint64_t.txt");

//	func(m_empty, 0);
    func(m_array_1, 1);
    func(m_array_10, 10);
    func(m_array_100, 100);
    func(m_array_1000, 1000);

    if (m_array_1[0] != m_sorted_array_1[0]) { exit(10); }

    for (int i = 0; i < 10; ++i) {
        if (m_array_10[i] != m_sorted_array_10[i]) {
            exit(10);
        }
    }
    for (int i = 0; i < 100; ++i) {
        if (m_array_100[i] != m_sorted_array_100[i]) {
            exit(10);
        }
    }
    for (int i = 0; i < 1000; ++i) {
        if (m_array_1000[i] != m_sorted_array_1000[i]) {
            printf("%u != %u\n", *m_array_1000, *m_sorted_array_1000);
            exit(10);
        }
    }
    printf("All tests passed succesfully\n");
    return 0;
}

