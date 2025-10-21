import random
import os

MIN_VALUE = -2**31 + 1
MAX_VALUE = 2**31 - 1


def generate_a_b_ans(n: int = 1000, destination_dir: str = '../6_axb_check_32_char'):
    if not os.path.exists(destination_dir):
        os.mkdir(destination_dir)

    if destination_dir and destination_dir[-1] == '/':
        destination_dir = destination_dir[:-1]

    file_a = open(destination_dir + f'/array_{n}el_a.lst', 'w')
    file_b = open(destination_dir + f'/array_{n}el_b.lst', 'w')
    file_ans = open(destination_dir + f'/array_{n}el_ans.lst', 'w')

    for i in range(n - 2):
        a = random.randint(-2**31 + 1, 2**31 - 1)
        if a == 0:
            a = 1

        if i % 2 == 0:
            # Generate values for answer "Yes"
            x = random.randint(1, MAX_VALUE // abs(a))
            b = -a * x
            ans = True
        else:
            # Generate values for a random answer
            b = random.randint(1, MAX_VALUE)
            ans = b % a == 0
        print(a, file=file_a)
        print(b, file=file_b)
        print('1' if ans else '0', file=file_ans)

    # Some edge cases
    print(0, file=file_a)
    print(0, file=file_b)
    print(1, file=file_ans)

    print(0, file=file_a)
    print(1, file=file_b)
    print(0, file=file_ans)

    file_a.close()
    file_b.close()
    file_ans.close()

if __name__ == "__main__":
    generate_a_b_ans()
