# Autotests for Lab2: Cmake/Make

### How to use autotest script:

To get info about all options:
```bash
python3 test_cmakemake.py -h
```

In order to run tests you MUST use 2 flags - `-S` and `-M`. Replace text in arrow brackets with your paths.

```bash
python test_cmakemake.py -S <path/to/sample/libary> -M <path/to/mystring> 
```

You can run different tests separately using `--bash`, `--make` and `--cmake` flags.
```bash
python3 test_cmakemake.py -S <path/to/sample/libary> -M <path/to/mystring> --bash
```

You can also combine those:
```bash
python3 test_cmakemake.py -S <path/to/sample/libary> -M <path/to/mystring> --bash --make
```

To run all the tests just don't write any of above.

### Project Structure ( IMPORTANT )
Structure of the project **MUST BE** the same as on example in metodychka

Names of "**_mystring_**" and "**_sample_lib_**" can be **any**, since you enter those as flags in order to run the script

Example of project structure: 

lab2_cmakemake-...surnames:\
├── sample_lib: ... \
├── mystring: ... \
└── README.md

