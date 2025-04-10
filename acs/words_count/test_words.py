import argparse
import base64
from pathlib import Path
import subprocess
import os
import sys
import shutil
import logging
from dataclasses import dataclass
import tempfile
import zipfile

# from typing import override # because old python


@dataclass
class TempNames:
    directory: str
    out_by_a: str
    out_by_n: str
    config: str


@dataclass
class Test:
    number: int
    base64_contents: str
    extensions: list[str]
    max_file_size: int
    temp_names: TempNames
    expected_a: list[tuple[str, int]]
    expected_n: list[tuple[str, int]]

    # @override
    def __str__(self) -> str:
        return f"""# Test #{self.number}
## Config:
{self.get_config()}"""

    def get_config(self) -> str:
        extensions = "\n".join(
            f"indexing_extensions = {extension}" for extension in self.extensions
        )
        return f"""indir="{self.temp_names.directory}"
out_by_a="{self.temp_names.out_by_a}"
out_by_n="{self.temp_names.out_by_n}"
{extensions}
archives_extensions = .zip
max_file_size = {self.max_file_size}"""


# indexing_threads = 3
# merging_threads = 1
# filenames_queue_size = 10000
# raw_files_queue_size = 1000
# dictionaries_queue_size = 1000"""


class Command:
    """Represents a command to be executed.

    Attributes:
        command: List of command-line arguments to execute.
        timeout: Maximum execution time in seconds.
    """

    command: list[str]
    timeout: int


@dataclass
class Result:
    """Represents the result of running a command.

    Attributes:
        name: A string representation of the function that was tested.
        stdout: Captured standard output, or None if execution failed.
        stderr: Captured standard error, or None if execution failed.
    """

    name: str
    stdout: str | None
    stderr: str | None


def extract_zip(zip_data: str, extract_location: str):
    """Extracts a zip file to a temporary dir.

    Args:
        zip_data: Base64-encoded zip file data that contains a directory.
        extract_location: Directory to extract the zip file to.
    """
    zip_binary = base64.b64decode(zip_data)

    temp_zip = tempfile.NamedTemporaryFile("wb", suffix=".zip", delete=False)
    temp_zip.write(zip_binary)
    temp_zip.close()

    with zipfile.ZipFile(temp_zip.name, "r") as zip_ref:
        zip_ref.extractall(extract_location)


def create_temp_file():
    return tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False)


def create_temp_config(test: Test):
    config_file = tempfile.NamedTemporaryFile("w", suffix=".cfg", delete=False)
    test.temp_names.config = config_file.name
    config_file.write(test.get_config())
    config_file.close()
    return config_file


def setup_temps(tests: list[Test], temp_files: list, temp_dirs: list[str]):
    """Sets up temporary files and directories for each test.

    Updates tests in place with new locations.

    Args:
        tests: List of Test objects to create temporary files and directories for.

    Returns:
        A tuple containing a list of temporary files and a list of temporary directories.
    """
    for test in tests:
        directory = tempfile.mkdtemp()
        extract_zip(test.base64_contents, directory)
        out_by_a = create_temp_file()
        out_by_n = create_temp_file()
        test.temp_names = TempNames(directory, out_by_a.name, out_by_n.name, "")
        temp_config = create_temp_config(test)
        temp_files.append(out_by_a)
        temp_files.append(out_by_n)
        temp_files.append(temp_config)
        temp_dirs.append(directory)


def setup(build_path: str = "build") -> str:
    """Sets up the build environment.

    Creates a build directory if it doesn't exist and
    changes the current directory to it.

    Args:
        build_path: Path to the build directory.

    Returns:
        Original project path before changing to build directory.
    """
    if not os.path.exists(build_path):
        logging.info("Creating build directory: " + build_path)
        os.makedirs(build_path)
    else:
        logging.info("Using existing build directory: " + build_path)
    project_path = os.getcwd()
    os.chdir(build_path)
    return project_path


def cleanup(project_path: str, build_path: str) -> None:
    """Cleans up the build environment.

    Changes back to the original project directory and removes the build directory.

    Args:
        project_path: Original project path to return to.
        build_path: Path to the build directory to remove.
    """
    logging.info("Cleaning up")
    os.chdir(project_path)
    if os.path.exists(build_path):
        shutil.rmtree(build_path)
    if os.path.exists("__tests__"):
        shutil.rmtree("__tests__")


def run(command: Command, test: Test | None = None) -> Result:
    """Runs a command and captures its output.

    Args:
        command: List of command-line arguments to execute.
        test: Test object associated with the command, or None.

    Returns:
        Result object containing command output.
    """
    if test is not None:
        name = f"Test #{test.number}"
    else:
        name = f"Command {' '.join(command.command)}"
    timeout = command.timeout
    try:
        process = subprocess.run(
            command.command, capture_output=True, text=True, timeout=timeout
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
        run(Command(["cmake", "-DCMAKE_BUILD_TYPE=Release", project_path])).stdout
        is not None
        and run(Command(["cmake", "--build", "."])).stdout is not None
    )


def print_tests_info(project_path: str, tests: list[Test]) -> None:
    tests_path = Path(project_path) / Path("__tests__")
    if not os.path.exists(tests_path):
        os.mkdir(tests_path)
    for test in tests:
        path = str(
            Path(project_path) / Path("__tests__") / Path(f"test_num_{test.number}")
        )
        extract_zip(
            test.base64_contents,
            path,
        )
        test.temp_names.directory = path
        print(test)


def get_results(binary_name: str, tests: list[Test]) -> list[Result]:
    return [
        run(
            Command(
                [
                    f"./{binary_name}",
                    test.temp_names.config,
                ],
            ),
            test,
        )
        for test in tests
    ]


def test_stdout_format(results: list[Result]) -> bool:
    correct_format = True
    for result in results:
        if result.stdout is None:
            logging.error(f"Found no stdout for result: {result}")
            correct_format = False
            continue
        lines = [i for i in result.stdout.split("\n") if i.strip()]
        if len(lines) != 2:
            logging.error(f"Did not get 2 lines in stdout: {result}")
            correct_format = False
            continue
        if not lines[0].startswith("Total=") or not lines[1].startswith("Writing="):
            logging.error(f"Did not get the correct keys in stdout: {result}")
            correct_format = False
            continue
        try:
            int(lines[0].split("=")[1])
            int(lines[1].split("=")[1])
        except ValueError:
            logging.error(f"Did not get integer values in stdout: {result}")
            correct_format = False
            continue
    return correct_format


def test_file_format(tests: list[Test]) -> bool:
    correct_format = True
    for test in tests:
        for file in [
            ("output a", test.temp_names.out_by_a),
            ("output n", test.temp_names.out_by_n),
        ]:
            with open(file[1], "r") as f:
                lines = [i for i in f.read().split("\n") if i.strip()]
                for line in lines:
                    splitted = line.split(":")
                    if len(splitted) != 2:
                        logging.error(
                            f"Did not get the format `name:count` in file: {file}"
                        )
                        correct_format = False
                        break
                    name, count = splitted
                    name, count = name.strip(), count.strip()
                    if not count.isnumeric():
                        logging.error(f"Did not get integer count in file: {file}")
                        correct_format = False
                        break
    return correct_format


def get_result_from_file(file: str) -> list[tuple[str, int]]:
    with open(file, "r") as f:
        return [
            (i[0].strip(), int(i[1]))
            for i in [i.split(":") for i in f.read().split("\n") if i.strip()]
        ]


def test_correctness(results: list[Result], tests: list[Test]) -> bool:
    correct = True
    for result, test in zip(results, tests):
        result_list = get_result_from_file(test.temp_names.out_by_a)
        if result_list != test.expected_a:
            logging.error(f"{result.name} file a:")
            logging.error(f"Expected: {test.expected_a}")
            logging.error(f"Got: {result_list}\n")
            correct = False
        result_list = get_result_from_file(test.temp_names.out_by_n)
        if result_list != test.expected_n:
            logging.error(f"{result.name} file n:")
            logging.error(f"Expected: {test.expected_n}")
            logging.error(f"Got: {result_list}\n")
            correct = False
    return correct


def main(
    project_path: str,
    tests: list[Test],
    binary_name: str,
    print_tests: bool,
):
    """Main function to run all tests.

    Builds the project and runs format, consistency, correctness, and speed tests.

    Args:
        project_path: Path to the project root directory.
        tests: List of tests to run.
        binary_name: Name of the compiled binary to test.
        print_tests: Whether to print info about tests instead of running them.
    """
    if print_tests:
        logging.info("=============================")
        logging.info("Printing tests info")
        print_tests_info(project_path, tests)
        return

    if not build(project_path):
        logging.info("=============================")
        logging.error("Build failed")
        return

    logging.info("=============================")
    logging.info("Getting results")
    results = get_results(binary_name, tests)
    logging.info("=============================")
    logging.info("Running tests")
    logging.info("=============================")
    logging.info("Testing the format of stdout")
    if not test_stdout_format(results):
        logging.error("Stdout format tests failed")
        return
    logging.info("=============================")
    logging.info("Testing the format of output files")
    if not test_file_format(tests):
        logging.error("File format tests failed")
        return
    logging.info("=============================")
    logging.info("Testing the correctness of results")
    if not test_correctness(results, tests):
        logging.error("Correctness tests failed")
        return

    logging.info("=============================")
    logging.info("All tests passed")


TESTS = [
    Test(
        1,
        "UEsDBBQAAAAAAJl8iloAAAAAAAAAAAAAAAAGAAAAdGVzdDEvUEsDBBQAAAAAAJl8iloAAAAAAAAAAAAAAAAIAAAAdGVzdDEvZi9QSwMEFAACAAgANnyKWqdc1xYdAAAALQAAAA4AAAB0ZXN0MS9mL2YxLnR4dEvLz0vVUUgrKc9XsAJSGUWpqVwQCkxAhezBKrgAUEsDBBQAAgAIAEV8iloK+iNbGQAAAC8AAAAOAAAAdGVzdDEvZi9mMi50eHRLKynPV0jDJPLz9bjSSjKKUlMVIBSY4AIAUEsDBBQAAgAIAJJ8ilrsW0cZ9wAAABMCAAALAAAAdGVzdDEvei56aXAL8GZmEWEAgUk1XVEMSIAJiKv0A8DyTAwcDB8LGqNO2887wwYUZwdiDrB8upFeSUWJtz87ox5DANysyVVNUZPZrhsxAtmMcLVpxiC1XAgjg4FWfvJfIy0PlDZAKDMBKQv2OKMZ6HHGO9DD+7S+btOEmMxKLlbLpUc55DwEW5gZEIZEAw1RyQ2YLgrULAPEnBB3GepllOTmeJ8/7x3q4S6g+vRnTMxLVUnXlStjgHoZmeyZcfsaBt46MkDDAKIeVyjAwJJGBaQwQbYFW3ggdPkghQ6yXdiCB6GrGCmwkHVhCw+Erh3IoRPgzQryBwMrEHIC3fUFrAoAUEsBAj8DFAAAAAAAmXyKWgAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAO1BAAAAAHRlc3QxL1BLAQI/AxQAAAAAAJl8iloAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAADtQSQAAAB0ZXN0MS9mL1BLAQI/AxQAAgAIADZ8ilqnXNcWHQAAAC0AAAAOAAAAAAAAAAAAAACkgUoAAAB0ZXN0MS9mL2YxLnR4dFBLAQI/AxQAAgAIAEV8iloK+iNbGQAAAC8AAAAOAAAAAAAAAAAAAACkgZMAAAB0ZXN0MS9mL2YyLnR4dFBLAQI/AxQAAgAIAJJ8ilrsW0cZ9wAAABMCAAALAAAAAAAAAAAAAACkgdgAAAB0ZXN0MS96LnppcFBLBQYAAAAABQAFABsBAAD4AQAAAAA=",
        [".txt"],
        10000000,
        TempNames("", "", "", ""),
        [
            ("alt", 2),
            ("and", 1),
            ("ffour", 4),
            ("fn", 2),
            ("fone", 1),
            ("fthree", 3),
            ("fthreethree", 2),
            ("ftwo", 6),
            ("ftwooo", 1),
            ("gggggg", 1),
            ("plus", 1),
        ],
        [
            ("ftwo", 6),
            ("ffour", 4),
            ("fthree", 3),
            ("alt", 2),
            ("fthreethree", 2),
            ("fn", 2),
            ("and", 1),
            ("fone", 1),
            ("ftwooo", 1),
            ("gggggg", 1),
            ("plus", 1),
        ],
    ),
    Test(
        2,
        "UEsDBBQAAAAAAGJ3gloAAAAAAAAAAAAAAAAGAAAAdGVzdDIvUEsDBBQAAAAAAGJ3gloAAAAAAAAAAAAAAAAKAAAAdGVzdDIveWF5L1BLAwQUAAAAAAAEd4JavLpOYAQAAAAEAAAAEQAAAHRlc3QyL3lheS95YXkudHh0eWF5ClBLAwQUAAAAAABid4JaAAAAAAAAAAAAAAAAEQAAAHRlc3QyL3lheS95YXl5YXkvUEsDBBQAAAAAAAp3glouBBpXCAAAAAgAAAAYAAAAdGVzdDIveWF5L3lheXlheS95YXkudHh0eWF5IHlheQpQSwMEFAAAAAAAFXeCWry6TmAEAAAABAAAAA4AAAB0ZXN0Mi95YXkuaHRtbHlheQpQSwMEFAAAAAAALneCWqEj5WIIAAAACAAAAAwAAAB0ZXN0Mi9zeW4ubWRzeW4gYWNrClBLAwQUAAAAAABQd4JaiUgspgcAAAAHAAAAEAAAAHRlc3QyL3R4dC5ub3R0eHRub3R0eHQKUEsBAj8DFAAAAAAAYneCWgAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAO1BAAAAAHRlc3QyL1BLAQI/AxQAAAAAAGJ3gloAAAAAAAAAAAAAAAAKAAAAAAAAAAAAAADtQSQAAAB0ZXN0Mi95YXkvUEsBAj8DFAAAAAAABHeCWry6TmAEAAAABAAAABEAAAAAAAAAAAAAAKSBTAAAAHRlc3QyL3lheS95YXkudHh0UEsBAj8DFAAAAAAAYneCWgAAAAAAAAAAAAAAABEAAAAAAAAAAAAAAO1BfwAAAHRlc3QyL3lheS95YXl5YXkvUEsBAj8DFAAAAAAACneCWi4EGlcIAAAACAAAABgAAAAAAAAAAAAAAKSBrgAAAHRlc3QyL3lheS95YXl5YXkveWF5LnR4dFBLAQI/AxQAAAAAABV3glq8uk5gBAAAAAQAAAAOAAAAAAAAAAAAAACkgewAAAB0ZXN0Mi95YXkuaHRtbFBLAQI/AxQAAAAAAC53glqhI+ViCAAAAAgAAAAMAAAAAAAAAAAAAACkgRwBAAB0ZXN0Mi9zeW4ubWRQSwECPwMUAAAAAABQd4JaiUgspgcAAAAHAAAAEAAAAAAAAAAAAAAApIFOAQAAdGVzdDIvdHh0Lm5vdHR4dFBLBQYAAAAACAAIAOQBAACDAQAAAAA=",
        [".txt", ".md"],
        10000000,
        TempNames("", "", "", ""),
        [("ack", 1), ("syn", 1), ("yay", 3)],
        [("yay", 3), ("ack", 1), ("syn", 1)],
    ),
]


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-b",
        "--build-path",
        help="Path to the directory, where to build the project",
        type=str,
        default="cmake-build-tests",
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
        "-p",
        "--print-tests",
        action="store_true",
        help="Whether to print tests instead of running them",
    )
    parser.add_argument(
        "-l",
        "--logging-level",
        help="How much to log",
        type=str,
        default="info",
        choices=["debug", "info", "warning", "error", "critical"],
    )
    parser.add_argument(
        "-t",
        "--timeout",
        help="The default timeout for commands (currently only cmake builds)",
        type=int,
        default=45,
    )
    parser.add_argument(
        "lab_type",
        help="Type of lab to test",
        type=str,
        choices=["serial", "parallel", "tbb", "tools"],
    )

    args = parser.parse_args()
    print_tests: bool = args.print_tests
    build_path: str = args.build_path
    binary_name: str = args.binary_name
    clean: bool = args.clean
    lab_type: str = args.lab_type
    logging_level: str = args.logging_level.upper()
    logging.basicConfig(
        level=logging.getLevelName(logging_level), format="%(levelname)s: %(message)s"
    )

    parallel = lab_type in ["parallel", "tbb"]
    if not binary_name:
        binary_name = {
            "serial": "countwords_seq",
            "parallel": "countwords_par",
            "tools": "countwords_par_proftools",
            "tbb": "countwords_par_tbb",
        }[lab_type]
        if sys.platform == "win32":
            binary_name += ".exe"

    @dataclass
    class Command:
        command: list[str]
        timeout: int = args.timeout

    project_path = setup(build_path)

    temp_files = []
    temp_dirs: list[str] = []

    try:
        setup_temps(TESTS, temp_files, temp_dirs)
        main(
            project_path,
            TESTS,
            binary_name,
            print_tests,
        )
    finally:
        for temp_file in temp_files:
            os.unlink(temp_file.name)
        for temp_dir in temp_dirs:
            shutil.rmtree(temp_dir)
        if clean:
            cleanup(project_path, build_path)
