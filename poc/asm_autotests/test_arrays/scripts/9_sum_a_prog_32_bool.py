import random
import os


MAX_INT32 = 2**31 - 1
MIN_INT32 = -2**31

def generate_progressions(n: int = 1000, destination_dir: str = '../9_sum_a_prog_32_bool'):
    if destination_dir.endswith('/'):
        destination_dir = destination_dir[:-1]

    if not os.path.exists(destination_dir):
        os.mkdir(destination_dir)

    file_a1 = open(destination_dir + f'/list_{n}el_a1.lst', 'w')
    file_d = open(destination_dir + f'/list_{n}el_d.lst', 'w')
    file_n = open(destination_dir + f'/list_{n}el_n.lst', 'w')
    file_bool_ans = open(destination_dir + f'/list_{n}el_bool_ans.lst', 'w')
    file_res = open(destination_dir + f'/list_{n}el_res.lst', 'w')

    for i in range(n):
        a1 = random.randint(-2**15, 2**15)
        d = random.randint(-2**16, 2**16)
        n = random.randint(0, 2**10) 

        res = n * (2 * a1 + (n - 1) * d) / 2
        ans = MIN_INT32 <= res <= MAX_INT32

        print(a1, file=file_a1)
        print(d, file=file_d)
        print(n, file = file_n)
        print('1' if ans else '0', file=file_bool_ans)
        print(res if ans else 0, file=file_res)

    file_a1.close()
    file_d.close()
    file_n.close()
    file_bool_ans.close()
    file_res.close()
                




if __name__ == '__main__':
    generate_progressions()
