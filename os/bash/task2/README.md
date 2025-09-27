# Task 2 test script.


The script generates files older than n days, so no need for other files.
It compares the archives, but for anything other than zip you'll need to specify.

The first argument is the unarchive command (`tar xzf` by default) and the second is
the path to the bash script (`./my_inc_bkp.sh` by default).

It works as such:

```bash
./test_my_inc_bkp.sh 'tar xzf' './my_inc_bkp.sh'
# OR
./test_my_inc_bkp.sh 'unzip' './some/dir/my_inc_bkp.sh'
```

Tmp files are created in the same directory as the script.
The srcipt searches for archives as such:
```
find $PWD -regextype posix-extended -regex "$path_to-specified_dir/$dirname-[0-9]{4}(-[0-9]{2}){5}.*"
```


Good luck)
