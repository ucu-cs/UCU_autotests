import base64
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("filename")
args = parser.parse_args()
filename = args.filename

with open(filename, "rb") as zip_file:
    encoded_zip = base64.b64encode(zip_file.read()).decode("utf-8")
    print(encoded_zip)
