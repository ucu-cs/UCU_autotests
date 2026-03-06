import argparse
import contextlib
import logging
import math
import pathlib
import shlex
import shutil
import subprocess
import sys
import tempfile
from collections import defaultdict
from typing import Literal


class ColoredFormatter(logging.Formatter):
    COLORS = {logging.DEBUG: "\033[36m", logging.INFO: "\033[32m", logging.WARNING: "\033[33m",
              logging.ERROR: "\033[31m", logging.CRITICAL: "\033[41m", }

    BOLD = "\033[1m"
    RESET = "\033[0m"

    def format(self, record: logging.LogRecord) -> str:
        color = self.COLORS.get(record.levelno, "")

        original_level = record.levelname
        original_msg = record.msg

        record.levelname = f"{self.BOLD}{color}{original_level}{self.RESET}"
        record.msg = f"{color}{record.getMessage()}{self.RESET}"

        result = super().format(record)

        record.levelname = original_level
        record.msg = original_msg

        return result


def setup_logging(level: str):
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(ColoredFormatter("[%(levelname)s] | %(message)s"))

    root = logging.getLogger()
    root.setLevel(level)
    root.handlers.clear()
    root.addHandler(handler)


OneBRC_SAMPLES_URL = "https://drive.google.com/file/d/1fr8d8RSz4Geqmi4AYY_E2v2Sw2vZcY6W/view"

StreamingType = Literal["silent", "capture", "verbose", "all"]

_SUBPROCESS_STREAMING_OPTIONS = {"silent": dict(stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL),
                                 "capture": dict(capture_output=True), "verbose": dict(),
                                 "all": dict(stdout=subprocess.PIPE, stderr=subprocess.STDOUT), }


def execute_command(command: str, timeout_s: float, streaming_type: StreamingType) -> subprocess.CompletedProcess:
    stream_options = _SUBPROCESS_STREAMING_OPTIONS[streaming_type]
    return subprocess.run(shlex.split(command), text=True, timeout=timeout_s, **stream_options)


def build_executable(build_dir_path: pathlib.Path, compiler_options: str):
    build_dir_path.mkdir(parents=True, exist_ok=True)

    build_dir_str = str(build_dir_path.resolve())
    commands = [f"cmake -B {build_dir_str} -DCMAKE_BUILD_TYPE=Release {compiler_options}",
                f"cmake --build {build_dir_str} -j 4"]
    for command in commands:
        completed_process = execute_command(command, timeout_s=60, streaming_type="verbose")
        assert completed_process.returncode == 0, f"Command `{command}` didn't exit with code 0."


def simple_solution(input_file_path, output_file_path) -> float:
    """
    Returns execution time in milliseconds.
    """
    import time

    class StationData:
        def __init__(self):
            self.count = 0
            self.sum = 0.0
            self.min = float("inf")
            self.max = float("-inf")

        def update(self, temp: float):
            self.count += 1
            self.sum += temp

            if temp < self.min:
                self.min = temp

            if temp > self.max:
                self.max = temp

        def mean(self):
            return self.sum / self.count if self.count != 0 else 0.0

    def process_file(file_path, output_path):
        station_data = defaultdict(lambda: StationData())

        with open(file_path, "r", encoding="utf-8") as file:
            for row in file:
                station, temp = row.strip().split(";")
                temp = float(temp)
                station_data[station].update(temp)

        with open(output_path, "w", newline="", encoding="utf-8") as file:
            for station, data in sorted(station_data.items()):
                file.write(f"{station}={data.min:.1f}/{data.mean():.1f}/{data.max:.1f}\n")

    start_time = time.perf_counter()
    process_file(input_file_path, output_file_path)
    execution_time = time.perf_counter() - start_time

    return execution_time * 1e3


@contextlib.contextmanager
def create_a_temporary_file(content: str, suffix: str):
    with tempfile.NamedTemporaryFile(mode="w", suffix=suffix, delete=True) as tmp:
        tmp.write(content)
        tmp.flush()
        yield pathlib.Path(tmp.name)


def create_config_content(infile: pathlib.Path, outfile: pathlib.Path, num_threads: int) -> str:
    return f"""\
    infile = {str(infile)}
    outfile= {str(outfile)}
    threads   ={num_threads}
    """


def find_sorted_test_pairs(test_suites_dir: pathlib.Path) -> list[tuple[pathlib.Path, pathlib.Path]]:
    input_files = list(sorted(test_suites_dir.glob("*.txt"), key=lambda p: p.stat().st_size))
    assert len(input_files), "Test samples empty. Download correct test samples."

    output_files = []
    for input_file in input_files:
        txt_out = input_file.with_name(input_file.name + ".out")
        plain_out = input_file.with_suffix(".out")

        if txt_out.exists():
            output_file = txt_out
        elif plain_out.exists():
            output_file = plain_out
        else:
            raise FileNotFoundError(f"Could not find a corresponding output sample for `{input_file}`.")

        output_files.append(output_file)

    return list(zip(input_files, output_files))


def parse_output_file(path: pathlib.Path) -> list:
    with open(path) as f:
        outputs = [line.strip() for line in f if line.strip()]

    outputs = [x.split("=") for x in outputs]
    for i in range(len(outputs)):
        outputs[i][1] = [float(x) for x in outputs[i][1].split("/")]
    return outputs


def compare_output(GT_records: list, compare_against_records: list) -> None:
    assert len(GT_records) == len(
        compare_against_records), f"Ground-truth file is of length {len(GT_records)}, while tested generated output file is of length {len(compare_against_records)}."

    for i, (GT_record, record) in enumerate(zip(GT_records, compare_against_records), start=1):
        assert GT_record[0] == record[
            0], f"Incorrect station name found at line # {i}. Should be {GT_record[0]} rather than {record[0]}."
        for j in range(3):
            assert math.isclose(GT_record[1][j], record[1][j], rel_tol=0.0,
                                abs_tol=0.1 + 1e-3), f"Incorrect values found at line # {i}. Should be {GT_record[1]} rather than {record[1]}."


def parse_total_execution_time(stdout: str) -> tuple[int, int, int]:
    lines = stdout.splitlines()

    prefixes = ("Total=", "Reading=", "Writing=")
    assert len(lines) == 3, f"Expected exactly 3 program output lines ({prefixes}). Got {lines}."

    values = []
    for i, (line, prefix) in enumerate(zip(lines, prefixes), start=1):
        assert line.startswith(prefix), f"Line # {i} must start with {prefix!r}, got {line!r}."
        value_str = line[len(prefix):]
        assert value_str, f"Line # {i} is missing a value."
        try:
            values.append(int(value_str))
            assert math.isclose(int(value_str), float(value_str))
        except ValueError:
            logging.error(f"Line # {i} should contain a time amount as an integer. Got: {line!r}.")

    return tuple(values)


def test_1brc(build_path: pathlib.Path, executable_name: str, compiler_options: str, keep_build: bool,
              test_suites_dir: pathlib.Path):
    try:
        logging.info(f"Building `{executable_name}` in `{build_path}`.")
        build_executable(build_path, compiler_options)

        assert test_suites_dir.exists(), "Test suites do not exist. This script depends on pre-downloaded test samples. Run the script w/ `--help` flag and explore the `--data-suite` argument."
        logging.info(f"Locating test samples.")
        sorted_test_pairs_paths = find_sorted_test_pairs(test_suites_dir)

        executable_path_str = str(build_path / executable_name)
        reruns = 2
        num_threads_to_try = (1, 2, 4)

        execution_times = defaultdict(lambda: list())

        with tempfile.TemporaryDirectory() as tmp_dir:
            output_path = pathlib.Path(tmp_dir) / "output.txt"

            logging.info(f"Starting running correctness checks on test samples.")

            for input_file_path, expected_output_file_path in sorted_test_pairs_paths:
                logging.debug(f"Running tests on `{input_file_path.name}`.")
                for rerun in range(reruns):
                    for threads in num_threads_to_try:
                        error_common_line = f"`{executable_name}` (threads={threads}, input_file={input_file_path.name})"

                        output_path.write_text("")

                        temporary_config_content = create_config_content(input_file_path, outfile=output_path,
                                                                         num_threads=threads)
                        with create_a_temporary_file(content=temporary_config_content, suffix=".cfg") as temp_config:
                            completed_process: subprocess.CompletedProcess = execute_command(
                                f"{executable_path_str} {str(temp_config)}", timeout_s=15, streaming_type="capture")
                            assert completed_process.returncode == 0, f"{error_common_line} finished with non-zero return code `{completed_process.returncode}`; stderr: `{completed_process.stderr}`."

                        GT_records = parse_output_file(expected_output_file_path)
                        try:
                            records = parse_output_file(output_path)
                        except Exception:
                            logging.error(f"{error_common_line} produced improperly formatted parsing output file:.")
                            raise

                        try:
                            compare_output(GT_records, records)
                        except Exception:
                            logging.error(f"{error_common_line} produced incorrect results.")
                            raise

                        try:
                            total_execution_time_ms, _, _ = parse_total_execution_time(completed_process.stdout)
                        except Exception:
                            logging.error(f"{error_common_line} printed to stdout an improperly formatted time amount.")
                            raise
                        execution_times[(input_file_path.name, threads)].append(total_execution_time_ms)

                logging.debug(f"Finished correctness checks on `{input_file_path.name}`.")

            logging.info(f"All correctness checks on test samples were successful.")

            logging.info("Running basic Python implementation.")
            simple_total_execution_time_ms = float("+inf")
            for _ in range(reruns):
                simple_total_execution_time_ms = min(simple_total_execution_time_ms,
                                                     simple_solution(input_file_path, output_path))

            cpp_implementation_faster_at_least_X_times = 3
            cpp_single_thread_total_execution_time_ms = min(execution_times[(input_file_path.name, 1)])
            X = simple_total_execution_time_ms / cpp_single_thread_total_execution_time_ms

            assert X > cpp_implementation_faster_at_least_X_times, f"C++ implementation w/ 1 thread should be at least {cpp_implementation_faster_at_least_X_times}x faster than a basic Python implementation. Got factor of {X:.2f}."
            logging.info(f"C++ implementation turned out to be {X:.2f}x faster than basic Python implementation.")

            parallelization_efficiency_threshold = 0.7
            for threads in (set(num_threads_to_try) - {1}):
                cpp_multi_threaded_total_execution_time_ms = min(execution_times[(input_file_path.name, threads)])
                parallelization_efficiency = cpp_single_thread_total_execution_time_ms / (
                        cpp_multi_threaded_total_execution_time_ms * threads)
                getattr(logging, {False: "info", True: "warning"}[
                    parallelization_efficiency < parallelization_efficiency_threshold])(
                    f"Execution with `{threads}` threads yields a parallelization efficiency of `{parallelization_efficiency:%}`.")

            logging.info("All tests passed.")

    finally:
        if not keep_build:
            shutil.rmtree(str(build_path), ignore_errors=True)


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--data-suite",
                        help=f"Directory path to 1brc samples. Download from `{OneBRC_SAMPLES_URL}`.", required=True,
                        type=pathlib.Path, )
    parser.add_argument("-b", "--build-path", help="Path to the directory, where to build the project",
                        type=pathlib.Path, default=pathlib.Path("tests-build"), )
    parser.add_argument("-n", "--binary-name", help="Name of the binary to test after the build", type=str,
                        default="1brc", )
    parser.add_argument("--compiler-options",
                        help="Compiler options passed during cmake build. For example: `-DCMAKE_CXX_COMPILER=/usr/bin/clang++`.",
                        type=str, default="", )
    parser.add_argument("-k", "--keep-build", action="store_true",
                        help="Whether to keep the build directory after running tests.", )

    parser.add_argument("-l", "--logging-level", type=str, default="INFO",
                        choices=["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"], )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    setup_logging(args.logging_level)

    binary_name = args.binary_name
    if sys.platform == "win32":
        binary_name += ".exe"

    try:
        test_1brc(build_path=args.build_path, executable_name=binary_name, compiler_options=args.compiler_options,
                  keep_build=args.keep_build, test_suites_dir=args.data_suite)
    except BaseException as err:
        logging.critical(f"Testing failed and stopped. Error encountered: {str(err)}")
