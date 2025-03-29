import argparse
import dataclasses
import math
import subprocess
import os
import sys
import shutil
import logging
from dataclasses import dataclass
import tempfile
import re
import random
import multiprocessing

@dataclass
class Task:
    infile:  str
    outfile: str
    threads: int    = 1
    name:    str    = ""
    epsilon: float  = 0.1
    timeout: int    = 30

@dataclass
class Result:
    name: str
    stdout: str | None
    stderr: str | None

@dataclass
class ParsedResult:
    total:   int
    reading: int
    writing: int

@dataclass
class ParsedLine:
    station: str
    min: float
    mean: float
    max: float

def setup(build_path: str = "build", data_path: str = "data") -> str:
    """Sets up the build environment.

    Creates a build directory if it doesn't exist and
    changes the current directory to it.

    Args:
        build_path: Path to the build directory.
        data_path: Path to the results data directory
    Returns:
        Original project path before changing to build directory.
    """
    if not os.path.exists(data_path):
        logging.info("Creating data directory: " + data_path)
        os.makedirs(data_path)
    else:
        logging.info("Using existing data directory: " + data_path)

    if not os.path.exists(build_path):
        logging.info("Creating build directory: " + build_path)
        os.makedirs(build_path)
    else:
        logging.info("Using existing build directory: " + build_path)
    project_path = os.getcwd()
    os.chdir(build_path)
    return project_path, os.path.join(project_path, data_path)

def cleanup(project_path: str, build_path: str, data_path: str) -> None:
    """Cleans up the build environment.

    Changes back to the original project directory and removes the build directory.

    Args:
        project_path: Original project path to return to.
        build_path: Path to the build directory to remove.
        data_path: Path to the results data directory to remove.
    """
    logging.info("Cleaning up")
    os.chdir(project_path)
    shutil.rmtree(build_path)
    shutil.rmtree(data_path)

def run(command: list[str], task: Task | None = None) -> Result:
    """Runs a command and captures its output.

    Args:
        command: List of command-line arguments to execute.

    Returns:
        Result object containing command output.
    """
    if task is not None:
        name = f"Config {task.name}"
        timeout = task.timeout
    else:
        name = f"Command {' '.join(command)}"
        timeout = 30
    try:
        process = subprocess.run(
            command, capture_output=True, text=True, timeout=timeout
        )
    except subprocess.CalledProcessError:
        logging.error(f"Failed to execute {command}")
        return Result(name, None, None)
    except subprocess.TimeoutExpired:
        logging.error(f"Timed out during execution of {command}")
        return Result(name, None, None)
    return Result(name, process.stdout, process.stderr)

def build(project_path: str) -> bool:
    """Builds the project using cmake.

    Args:
        project_path: Path to the project root directory.

    Returns:
        True if the build was successful, False otherwise.
    """
    logging.info("Building project: " + project_path)

    return (
        run(["cmake", "-DCMAKE_BUILD_TYPE=Release", project_path]).stdout is not None
        and run(["cmake", "--build", "."]).stdout is not None
    )

def parse_result(result: Result) -> ParsedResult | None:
    """Parses the given Result object to extract numerical values.

    Args:
        result: Result object to be parsed

    Returns:
        ParsedResult object
    """
    if result.stdout is None:
        logging.error(f"Found None result: {result}")
        return None

    pattern = r"Total=(\d+)\s*Reading=(\d+)\s*Writing=(\d+)"
    match = re.search(pattern, result.stdout)

    if not match:
        logging.error(f"Invalid format: {result}")
        return None

    total, reading, writing = map(int, match.groups())
    return ParsedResult(total, reading, writing)

def get_results(project_path: str, binary_name: str, tasks_to_run: list[Task]) -> list[Result] | None:
    """Runs the integration binary for each function and collects results.

    Args:
        project_path: Path to the project root directory.
        binary_name: Name of the compiled binary to run.
        tasks_to_run: List of Task objects to test.

    Returns:
        List of Result objects containing the output for each function.
    """
    results = []

    for task in tasks_to_run:
        temp_file_path = create_temp_config(task.infile, task.outfile, task.threads)
        try:
            result = run(
                [
                    f"./{binary_name}",
                    temp_file_path
                ],
                task,
            )
        finally:
            os.remove(temp_file_path)

        results.append(result)

    return results

def parse_line(line: str) -> ParsedLine | None:
    """Extracts station name and temperatures

    Args:
        line: line of file
    Returns:
        ParseLine structure
    """
    match = re.match(r"(.+)=(-?\d+\.\d+)/(-?\d+\.\d+)/(-?\d+\.\d+)", line.strip())
    if match:
        station = match.group(1)
        min_temp, mean_temp, max_temp = map(float, match.groups()[1:])
        return ParsedLine(station, min_temp, mean_temp, max_temp)

    logging.error(f"Line does not match subscription: {line}")
    return None

def isclose(a: float, b: float, tol: float):
    """Compares two floats with set tolerance"""
    return round(abs(a-b), 1) <= tol

def compare_files(file_name1: str, file_name2: str, epsilon: float = 0.1, log: bool =True) -> bool:
    """Compares two weather data files line by line using regex, ensuring order and accuracy within ±epsilon.

    Args:
        file_name1: path to #1 file
        file_name2: path to #2 file
        epsilon: accuracy to compare with
    Returns:
        True if all rows in files match, floats compared with epsilon accuracy, else False
    """
    with open(file_name1, 'r', encoding='utf-8') as file1, open(file_name2, 'r', encoding='utf-8') as file2:
        for i, (line1, line2) in enumerate(zip(file1, file2)):
            parsed1, parsed2 = parse_line(line1), parse_line(line2)

            if not parsed1 or not parsed2:
                if log:
                    logging.error(f"Invalid format in one of the files: \"{line1.strip()}\" | \"{line2.strip()}\"")
                else:
                    print(f"Invalid format in one of the files: \"{line1.strip()}\" | \"{line2.strip()}\"")
                return False

            res1 = parsed1
            res2 = parsed2

            if res1.station != res2.station:
                if log:
                    logging.error(f"Station name mismatch: \"{res1.station}\" vs \"{res2.station}\"")
                else:
                    print(f"Station name mismatch in files {file_name1}, {file_name2} in line {i}: \"{res1.station}\" vs \"{res2.station}\"")
                return False

            if not (isclose(res1.min, res2.min, epsilon) and
                    isclose(res1.mean, res2.mean, epsilon) and
                    isclose(res1.max, res2.max, epsilon)):
                if log:
                    logging.error(f"Temperature mismatch at {line1} vs {line2}")
                else:
                    print(f"Temperature mismatch at {line1} vs {line2}")
                return False

        if file1.readline() or file2.readline():
            if log:
                logging.error("File length mismatch!")
            else:
                print("File length mismatch!")
            return False

    return True

def python_script() -> str:
    """Creates python tempfile

    Returns:
        name of python file
    """
    script_content = """\
import time
import sys
from collections import defaultdict

class StationData:
    def __init__(self):
        self.count = 0
        self.sum = 0.0
        self.min = float('inf')
        self.max = float('-inf')

    def update(self, temp: float):
        self.count += 1
        self.sum += temp
        if temp < self.min:
            self.min = temp
        if temp > self.max:
            self.max = temp

    def mean(self):
        return self.sum / self.count if self.count != 0 else 0.0

def process_file(file_path, output_file_path):
    station_data = defaultdict(lambda: StationData())

    with open(file_path, 'r', encoding='utf-8') as file:
        for row in file:
            station, temp = row.strip().split(';')
            temp = float(temp)
            station_data[station].update(temp)

    with open(output_file_path, 'w', newline='', encoding='utf-8') as file:
        for station, data in sorted(station_data.items()):
            file.write(f"{station}={data.min:.1f}/{data.mean():.1f}/{data.max:.1f}\\n")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <input_file> <output_file>")
        sys.exit(1)

    input_file_path = sys.argv[1]
    output_file_path = sys.argv[2]

    start_time = time.time()
    process_file(input_file_path, output_file_path)
    end_time = time.time()
    execution_time = end_time - start_time
    print(f"Execution time: {execution_time:.2f} seconds")
"""

    with tempfile.NamedTemporaryFile(mode="w", suffix=".py", delete=False) as temp_file:
        temp_file.write(script_content)
        os.chmod(temp_file.name, 0o755)
        return temp_file.name

def create_temp_config(infile: str, outfile: str, threads: int) -> str:
    """Generates temp configfile

    Args:
        infile: path to input file
        outfile: path to output file
        threads: number of threads
    Returns:
        name of configuration tempfile
    """
    config_content = f"""\
infile="{infile}"
outfile="{outfile}"
threads={threads}
"""

    with tempfile.NamedTemporaryFile(mode="w", suffix=".cfg", delete=False, encoding="utf-8") as temp_config:
        temp_config.write(config_content)
        return temp_config.name

def generate_weather_data(size: int, stations: int) -> str:
    """Generate temp weather data file

    Args:
        size: number of lines
        stations: number of stations in the file
    Returns:
        name of tempfile instance
    """

    station_names = [get_random_unicode(random.randint(6, 20)) for _ in range(stations)]
    temperatures = [round(random.uniform(-99.9, 99.9), 1) for _ in range(size)]

    with tempfile.NamedTemporaryFile(mode='w', delete=False, encoding='utf-8') as temp_file:
        for _ in range(size):
            station = random.choice(station_names)
            temperature = random.choice(temperatures)
            temp_file.write(f"{station};{temperature}\n")

    return temp_file.name

def get_random_unicode(length) -> str:
    """Generate random unicode string

    Args:
        length: Length of resultring string

    Returns:
        string of unicode characters
    """
    # the characters are all characters that occur in the large archieve
    alphabet = " '()-/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzÀÁÅÇÉÍÑÓÖÜßàáâãäåæçèéêëìíîïðñòóôõöøúûüýĀāăąćČčďĐēėęěğĠġħĩĪīĭİıļĽľŁłńňŌōŏőřŚŞşŠšŢţťūŭųźŻżŽžƏơə̧̃̄̇ḐḑḥḨḩẕẖạẤầếệỉịốồộủừửựỹ‘’"
    return ''.join(random.choice(alphabet) for _ in range(length))

def get_next_prime(prev: float = 0) -> float:
    """Generates a prime number for the first few times - then just some bigger number.

    Uses a simple formula to generate a sequence of values for testing
    different thread counts.

    Args:
        prev: Previous value in the sequence.

    Returns:
        Next value in the sequence.
    """
    if prev == 0:
        prev = 2.920050977316134712092562917112019
    floor = math.floor(prev)
    return floor * (prev - floor + 1)

def test_format(results: list[Result], tasks: list[Task]) -> bool:
    """
    Checks if the file parses correctly

    :param result: result of cpp run
    :param tasls: tasks that were run to obtain results in the same order as results
    :return: True if everything is correct
    """
    parsed = [parse_result(res) for res in results]
    if any(res is None for res in parsed):
        return False

    for result, task in zip(parsed, tasks):
        with open(task.outfile, "r", encoding="utf-8") as file:
            for line in file:
                parsed_line = parse_line(line)
                if parsed_line is None:
                    print(f"Cannot parse the line in {task.outfile}:\n{line}")
                    return False

    return True

def test_result(results: list[Result], tasks: list[Task], data_path: str) -> bool:
    """
    runs python to get correct file and compares with it

    :param result: result of cpp run
    :param tasls: tasks that were run to obtain results in the same order as results
    :return: True if everything is correct
    """
    for result, task in zip(results, tasks):
        py_outfile = os.path.join(data_path, "py_" + task.name + ".out")
        py_script = python_script()
        try:
            py_res = run(["python3", py_script, task.infile, py_outfile])
        finally:
            os.remove(py_script)

        if not compare_files(task.outfile, py_outfile, log=False):
            return False

    return True

def test_speed(results: list[Result], tasks: list[Task], data_path) -> bool:
    """
    compares time of cpp file with python

    :param result: result of cpp run
    :param tasls: tasks that were run to obtain results in the same order as results
    :return: True if everything is correct
    """
    for result, task in zip(results, tasks):
        py_outfile = os.path.join(data_path, "py_" + task.name + ".out")
        py_script = python_script()
        try:
            py_res = run(["python3", py_script, task.infile, py_outfile])
        finally:
            os.remove(py_script)

        pattern = r"Execution time: (\d+\.\d+) seconds"
        match = re.search(pattern, py_res.stdout)
        py_time = float(match.group(1)) * 1000

        cpp_total = parse_result(result).total #millis

        if py_time < 3 * cpp_total:
            print(f"python time: {py_time}, cpp time: {cpp_total}")
            return False
    return True

def test_consistency(results: list[ParsedResult], tasks: list[Task]) -> bool:
    """
    checks if all results return same files

    :param results: list of results to compare
    :param tasls: tasks that were run to obtain results in the same order as results
    :return: True if all outfiles are the same
    """
    for i, task in enumerate(tasks[1:]):
        if not compare_files(tasks[0].outfile, task.outfile):
            print(f"Files differ in 1st and {i}th runs")
            return False

    return True

def main(
    project_path: str,
    data_path: str,
    binary_name: str,
    consistency_check: bool,
    speed_check: bool,
):
    """Main function to run all tests.

    Builds the project and runs format, consistency, correctness, and speed tests.

    Args:
        project_path: Path to the project root directory.
        data_path: Path to the results data directory.
        binary_name: Name of the compiled binary to test.
        consistency_check: Whether to perform consistency checks.
        speed_check: Whether to perform speed checks.
    """
    file_map = {}

    if not build(project_path):
        logging.error("Build failed")
        return

    file_map["short"]=generate_weather_data(100, 5)
    file_map["long"]=generate_weather_data(int(1e6), int(1e2))

    if consistency_check:
        file_map["one_station"] = generate_weather_data(int(1e3), 1)

    tasks = [
        Task(
            file_map["short"],
            os.path.join(data_path, "short_single_thread.out"),
            threads = 1,
            name="short_single_thread"
        ),
        Task(
            file_map["long"],
            os.path.join(data_path, "long_multi_thread.out"),
            threads = multiprocessing.cpu_count(),
            name = "long_multi_thread"
        )
    ]
    try:
        logging.info("Running tests")
        results = get_results(project_path, binary_name, tasks)

        logging.info("=============================")
        logging.info("Testing the format of output")
        if not test_format(results, tasks):
            logging.error("Format tests failed")
            return
        logging.info("Format tests passed")

        logging.info("=============================")
        logging.info("Testing the correctness of results")
        if not test_result(results, tasks, data_path):
            logging.error("Correctness tests failed")
            return
        logging.info("Correctness tests passed")

        if speed_check:
            logging.info("=============================")
            logging.info("Testing the speed of different number of threads")
            if not test_speed(results[1:2], tasks[1:2], data_path):
                logging.error(f"Speed tests failed at {tasks[1].threads} threads")
                return
            logging.info("Threaded tests passed")

        if consistency_check:
            logging.info("=============================")
            logging.info("Testing the consistency of result")

            primes = [2, 7, 13, 17, 29]

            consist_tasks = [Task(file_map["one_station"],
                                  os.path.join(data_path, f"one_station_{t}.out"),
                                  threads=t,
                                  name=f"consistency_check_{t}") for t in primes]
            consist_res = get_results(project_path, binary_name, consist_tasks)

            if not test_consistency(consist_res, consist_tasks):
                logging.error("Consistency tests failed")
                return
            logging.info("Consistency tests passed")

        logging.info("All tests passed")
    finally:

        for _key, t_file in file_map.items():
            try:
                os.remove(t_file)
            except OSError as e:
                logging.error(f"Error deleting temp file: {e}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-b",
        "--build-path",
        help="Path to the directory, where to build the project",
        type=str,
        default="tests-build",
    )
    parser.add_argument(
        "-d",
        "--data-path",
        help="Path to the directory, where all results will be stored",
        type=str,
        default="test-data",
    )
    parser.add_argument(
        "-n",
        "--binary-name",
        help="Name of the binary to test after the build",
        type=str,
        required=False,
    )
    parser.add_argument(
        "-c",
        "--clean",
        action="store_true",
        help="Whether to clean the build directory after running tests",
    )
    parser.add_argument(
        "-C",
        "--consistency",
        action="store_true",
        help="Whether to check for consistent result values on several attempts",
    )
    parser.add_argument(
        "-s",
        "--speed",
        action="store_true",
        help="Whether to check if 1 thread is slower than several threads",
    )
    parser.add_argument(
        "-l",
        "--logging-level",
        help="How much to log",
        type=str,
        default="info",
        choices=["debug", "info", "warning", "error", "critical"],
    )

    args = parser.parse_args()
    build_path: str = args.build_path
    data_path: str = args.data_path
    binary_name: str = args.binary_name
    clean: bool = args.clean
    consistency_check: bool = args.consistency
    speed_check: bool = args.speed
    logging_level: str = args.logging_level.upper()
    logging.basicConfig(
        level=logging.getLevelName(logging_level), format="%(levelname)s: %(message)s"
    )

    if not binary_name:
        binary_name = "1brc"
        if sys.platform == "win32":
            binary_name += ".exe"

    project_path, data_path = setup(build_path, data_path)

    try:
        main(
            project_path,
            data_path,
            binary_name,
            consistency_check,
            speed_check,
        )
    finally:
        if clean:
            cleanup(project_path, build_path, data_path)
