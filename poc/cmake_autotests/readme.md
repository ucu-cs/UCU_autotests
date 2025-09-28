# Autotests for Lab2: Cmake/Make

### How to use autotest script:

P.S: sign '|' mean just OR here

To get info about all options:
```bash
python3 test_cmakemake.py -h | --help
```

In order to run a script you MUST use 2 flags:

```bash
python test_cmakemake.py [-S | --sample] <path/to/sample/libary> [-M | --mystring] <path/to/mystring> 
```

To run different tests :
```bash
python3 test_cmakemake.py ... --bash | --cmake | --make
```

You can also combine those:

```bash
python3 test_cmakemake.py ... --bash --make
```

To run all the tests just don't write any of above.

To clean all bin / obj folders after testing (a.k.a clean):

```bash
python3 test_cmakemake.py ... [--clean | -c]
```

### Project Structure ( IMPORTANT )
Structure of the project **MUST BE** the same as on example in metodychka

Names of "**_mystring_**" and "**_sample_lib_**" can be **any**, since you enter those as flags in order to run the script

Example of project structure: 

lab2_cmakemake-...surnames:\
├── sample_lib: ... \
├── mystring: ... \
└── README.md

