# Tests for lab on mpi

The tests utilize `docker-compose`.
You would need to be able to run it on your system.

!! Note: the `run_test.sh` script uses `docker compose` not `docker-compose`,
so make sure you update your docker to be able to run it!


Usage:

You'll need to have cloned the lab.
The script mounts three directories for each container:

- `./config_files/` as `/config_files` - copy your config files there.
    The config file has to be named `config.cfg`
- `./app` as `/app`. The lab is copied to `./app`.
- `./config_scripts/` as `/ssh` - this dir combines the `./scripts/` dir and the ssh keys for each container.


The general usage is as such:

`./run_test.sh <path_to_lab_directory>`

The script runs the lab twice and then checks if the results are the same. Good luck!
