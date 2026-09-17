# Autotests for Lab2: Cmake/Make

## Project Structure ( IMPORTANT )

For the tests to work correctly, your lab must strictly follow this structure:

```text
lab2-cmake-surnames/
├── sample/
│   ├── library/ ...
│   ├── example/ ...
│   └── ...
├── mystring/
│   ├── library/ ...
│   ├── example/ ...
│   └── ...
├── README.md
└── test_cmakemake.py
```

Where `sample` is a directory with your assigned library (bzip2 / libjpeg / zlib) and `mystring` is your implementation of cstring.

## How to use autotest script:

To run tests:
```bash
python3 test_cmakemake.py
```

To get info about all options:
```bash
python3 test_cmakemake.py -h
```

You can run different tests separately using `--bash`, `--make` and `--cmake` flags.
```bash
python3 test_cmakemake.py --bash
```

You can also combine those:
```bash
python3 test_cmakemake.py --bash --make
```

To run all the tests just don't write any of above.
