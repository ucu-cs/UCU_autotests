import random

uint32_t_r = (0, 4294967295)
uint64_t_r = (0, 18446744073709551615)
int32_t_r = (-2147483648, 2147483647)
int64_t_r = (-9223372036854775808, 9223372036854775807)


if __name__ == "__main__":
    filenames = (   "1_sort_32_uint/array_{}el_uint32_t.txt",
                    "2_sort_32_int/array_{}el_int32_t.txt",
                    "3_sort_64_uint/array_{}el_uint64_t.txt",
                    "4_sort_64_int/array_{}el_int64_t.txt")
    types = (uint32_t_r, int32_t_r, uint64_t_r, int64_t_r)
    for file_index in range(4):
        a_10, a_100, a_1000, a_10_sorted, a_100_sorted, a_1000_sorted = [], [], [], [], [], []
        for i in range(10):
            a = random.randint(types[file_index][0], 
                               types[file_index][1])
            a_10.append(a)
        for i in range(100):
            a = random.randint(types[file_index][0], 
                               types[file_index][1])
            a_100.append(a)

        for i in range(1000):
            a = random.randint(types[file_index][0], 
                               types[file_index][1])
            a_1000.append(a)
        a_10_sorted = sorted(a_10)
        a_100_sorted = sorted(a_100)
        a_1000_sorted = sorted(a_1000)

        # print arrays unsorted
        with open(filenames[file_index].format("10"), "w") as f:
            for a in a_10:
                print(a, file=f, end="\n")
        with open(filenames[file_index].format("100"), "w") as f:
            for a in a_100:
                print(a, file=f, end="\n")
        with open(filenames[file_index].format("1000"), "w") as f:
            for a in a_1000:
                print(a, file=f, end="\n")

        # print arrays sorted
        with open(filenames[file_index].format("sorted_10"), "w") as f:
            for a in a_10_sorted:
                print(a, file=f, end="\n")
        with open(filenames[file_index].format("sorted_100"), "w") as f:
            for a in a_100_sorted:
                print(a, file=f, end="\n")
        with open(filenames[file_index].format("sorted_1000"), "w") as f:
            for a in a_1000_sorted:
                print(a, file=f, end="\n")


