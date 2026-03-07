# Running Tests
 
Most likely, you'd want to run the tests as:
```bash
python test_1brc.py -b tests-build -n 1brc --data-suite <path-to-1brc_samples> --keep-build -l INFO
```
This compiles the `1brc` inside the `tests-build` directory, and uses the pre-downloaded test samples.

Run `python test_1brc.py --help` to get a link to download test samples or to explore other CLI options.
