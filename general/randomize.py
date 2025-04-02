import random
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("path", type=str, help="the path to the file with teams in format: `name1,name2,...\n`")
args = parser.parse_args()
path: str = args.path

with open(path, "r") as file:
    lines = file.read().split("\n")

for line in lines:
    surnames = line.split(",")
    print(random.choice(surnames))
