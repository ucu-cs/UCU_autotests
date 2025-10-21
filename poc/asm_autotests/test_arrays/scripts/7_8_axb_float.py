import random
import os


PRESCALER = 2**32

def generate_axb(n: int = 1000, destination_dir: str = '../7_8_axb_float'):
    if not os.path.exists(destination_dir):
        os.mkdir(destination_dir)

    if destination_dir and destination_dir[-1] == '/':
        destination_dir = desination_dir[:-1]

    file_a = open(destination_dir + f'/array_{n}el_a.lst', 'w')
    file_x = open(destination_dir + f'/array_{n}el_x.lst', 'w')
    file_b = open(destination_dir + f'/array_{n}el_b.lst', 'w')

    for i in range(n):
        a = (random.random() - 0.5) * PRESCALER
        if a == 0:
            a = 0.1
        b = (random.random() - 0.5) * PRESCALER
        x = -b / a

        print(a, file=file_a)
        print(b, file=file_b)
        print(x, file=file_x)

    file_a.close()
    file_b.close()
    file_x.close()

if __name__ == '__main__':
    generate_axb()
