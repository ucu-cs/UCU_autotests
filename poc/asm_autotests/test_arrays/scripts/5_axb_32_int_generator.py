import random
import os


def generate_axb(n: int = 1000, destination_dir: str = '../5_axb_32_int'):
    if not os.path.exists(destination_dir):
        os.mkdir(destination_dir)

    if destination_dir and destination_dir[-1] == '/':
        destination_dir = destination_dir[:-1]

    file_a = open(destination_dir + f'/array_{n}el_a.lst', 'w')
    file_x = open(destination_dir + f'/array_{n}el_x.lst', 'w')
    file_b = open(destination_dir + f'/array_{n}el_b.lst', 'w')

    for i in range(n):
        a = random.randint(-2**31 + 1, 2**31 - 1)
        if a == 0:
            a = 1
        b = random.randint(-2**31 + 1, 2**31 - 1)

       
        x = -(abs(b) // abs(a))
        

        if abs(abs(a) * x + abs(b)) > abs(abs(a) * (x - 1) + abs(b)):
            x = x - 1
        if a * b < 0:
            x = -x

        print(a, file=file_a)
        print(b, file=file_b)
        print(x, file=file_x)

    file_a.close()
    file_b.close()
    file_x.close()

if __name__ == '__main__':
    generate_axb()
