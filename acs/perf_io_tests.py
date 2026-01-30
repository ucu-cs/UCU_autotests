#!/usr/bin/env python3

import os
import subprocess
import sys
import unittest
import argparse
from random import randrange

def parse_arguments():
    parser = argparse.ArgumentParser(description="Lab1: 'IO Performance comparison' tests.")
    parser.add_argument("directory", help="Path to the project directory")
    parser.add_argument("-c", "--compiler", default="gcc", help="Specify compiler(default: gcc, e.g., clang, clang-11).")
    parser.add_argument("-cl", "--clean", action="store_true", help="Clean the build directory before building")
    return parser.parse_args()

def build_project(build_dir, clean=False, compiler="gcc"):
    if clean and os.path.exists(build_dir):
        print("Cleaning build directory...")
        subprocess.call(['rm', '-rf', build_dir])
        os.makedirs(build_dir, exist_ok=True)

    env = os.environ.copy()
    if compiler == "clang":
        env["CC"] = "clang"
        env["CXX"] = "clang++"
    elif compiler.startswith("clang-"):
        env["CC"] = compiler
        env["CXX"] = compiler + "++"

    try:
        subprocess.check_call(['cmake', '..'], cwd=build_dir, env=env)
        subprocess.check_call(['cmake', '--build', '.'], cwd=build_dir)
        print(f"Project built successfully using {compiler}.")
    except subprocess.CalledProcessError as e:
        print(f"Error building project: {e}")
        sys.exit(1)

def create_file(file_path, size=10**7, rrange=10**8):
    with open(file_path, "w") as file:
        for _ in range(size):
            file.write(str(randrange(rrange)) + "\n")

def count_characters(file_path):
    with open(file_path, 'r') as file:
        content = file.read()
        return sum(1 for char in content if char != '\n')

def count_sum(file_path):
    with open(file_path, 'r') as file:
        content = (int(num) for num in file.read().split("\n")[:-1])
        return sum(content)%64

def run_test(executable, file_path, method):
    result = subprocess.check_output([executable, file_path, method], text=True)
    res = int(result.split()[1])
    return res

class TestCxxPerfIo(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        args = parse_arguments()

        cls.directory = args.directory
        cls.build_dir = os.path.join(cls.directory, 'build')
        os.makedirs(cls.build_dir, exist_ok=True)

        build_project(cls.build_dir, clean=args.clean, compiler=args.compiler)

        cls.executable_io = os.path.join(cls.build_dir, 'cxx_perf_io')
        cls.executable_conv = os.path.join(cls.build_dir, 'cxx_perf_conv')

        cls.files = ["./data_xs.md", "./data_s.md", "./data_m.md", "./data_l.md"]

        file_rrange = [64, 10**8, 10**8, 10**8]
        file_sizes = [1, 1, 1**3, 10**7]
        for i, file in enumerate(cls.files):
            create_file(file, file_sizes[i], file_rrange[i])

    def test_returns_int_io(self):
        for method in range(1, 6):
            with self.subTest(method=method):
                result = subprocess.check_output([self.executable_io, self.files[0], str(method)], text=True)
                self.assertEqual(True, result.split()[1].isnumeric(), f"Method {method} failed: Expected numeric, got {result.split()[1]}")

    def test_returns_int_conv(self):
        for method in range(1, 6):
            with self.subTest(method=method):
                result = subprocess.check_output([self.executable_conv, self.files[0], str(method)], text=True)
                self.assertEqual(True, result.split()[1].isnumeric(), f"Method {method} failed: Expected numeric, got {result.split()[1]}")

    def test_io(self):
        for method in range(1,6):
            with self.subTest(method=method):
                for file in self.files:
                    sum_chars = run_test(self.executable_io, file, str(method))

                    expected_chars = count_characters(file)
                    self.assertEqual(sum_chars, expected_chars, f"Method {method} failed: Expected {expected_chars}, got {sum_chars}")

    def test_conv_no_mod64(self):
        for method in range(1,6):
            with self.subTest(method=method):
                sum = run_test(self.executable_conv, self.files[0], str(method))

                expected_sum = count_sum(self.files[0])
                self.assertEqual(sum, expected_sum, f"Method {method} failed: Expected {expected_sum}, got {sum}")

    def test_conv_mod64(self):
        for method in range(1,6):
            with self.subTest(method=method):
                for file in self.files:
                    sum = run_test(self.executable_conv, file, str(method))

                    expected_sum = count_sum(file)
                    self.assertEqual(sum, expected_sum, f"Method {method} failed: Expected {expected_sum}, got {sum}")

if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]])