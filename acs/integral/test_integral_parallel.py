import argparse
import dataclasses
import math
import subprocess
import os
import shutil
from dataclasses import dataclass
import tempfile


@dataclass
class Function:
    """Represents a function to be integrated.

    Attributes:
        number: The number of the function.
        config: String path to configuration file.
        result: Expected result of the integration.
        epsilon: Maximum allowable error in the result.
        threads: Number of threads to use for the integration.
        timeout: Maximum execution time in seconds.
    """

    number: int
    config: str
    result: float
    epsilon: float
    threads: int = 1
    timeout: int = 30


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


# Predefined functions to test with their expected results and error tolerances
functions = [
    Function(1, "", 4.54544762 * 10**6, 20, threads=1),
    Function(2, "", 8.572082414 * 10**5, 20, threads=1),
    Function(3, "", -1.604646665, 0.1, threads=1),
]


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
        print("Creating build directory: " + build_path)
        os.makedirs(build_path)
    else:
        print("Using existing build directory: " + build_path)
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
    print("Cleaning up")
    os.chdir(project_path)
    shutil.rmtree(build_path)


def run(command: list[str], func: Function | None = None) -> Result:
    """Runs a command and captures its output.

    Args:
        command: List of command-line arguments to execute.
        func: Optional Function object providing arguments for the integral.
            If not present, the command will be called as is.

    Returns:
        Result object containing command output.
    """
    if func is not None:
        name = f"Function #{func.number}, threads: {func.threads}"
        timeout = func.timeout
    else:
        name = f"Command {' '.join(command)}"
        timeout = 30
    try:
        process = subprocess.run(
            command, capture_output=True, text=True, timeout=timeout
        )
    except subprocess.CalledProcessError:
        print(f"Failed to execute {command}")
        return Result(name, None, None)
    except subprocess.TimeoutExpired:
        print(f"Timed out during execution of {command}")
        return Result(name, None, None)
    return Result(name, process.stdout, process.stderr)


def build(project_path: str) -> bool:
    """Builds the project using cmake.

    Args:
        project_path: Path to the project root directory.

    Returns:
        True if the build was successful, False otherwise.
    """
    print("Building project: " + project_path)
    return (
        run(["cmake", "-DCMAKE_BUILD_TYPE=Release", project_path]).stdout is not None
        and run(["cmake", "--build", "."]).stdout is not None
    )


def get_results(
    project_path: str, binary_name: str, functions_to_run: list[Function]
) -> list[Result]:
    """Runs the integration binary for each function and collects results.

    Args:
        project_path: Path to the project root directory.
        binary_name: Name of the compiled binary to run.
        functions_to_run: List of Function objects to test.

    Returns:
        List of Result objects containing the output for each function.
    """
    return [
        run(
            [
                f"./{binary_name}",
                str(func.number),
                os.path.join(project_path, func.config),
                str(func.threads),
            ],
            func,
        )
        for func in functions_to_run
    ]


def test_format(results: list[Result]) -> bool:
    """Tests if the output format is correct.

    Expected format is 4 lines, each containing a number (convertible to float).

    Args:
        results: List of Result objects to check.

    Returns:
        True if all results have the correct format, False otherwise.
    """
    for result in results:
        if result.stdout is None:
            print(f"Found None result: {result}")
            return False
        lines = result.stdout.strip().split("\n")
        if len(lines) != 4:
            print(f"Wrong number of lines: '{len(lines)}' in {result}")
            return False
        for i in lines:
            try:
                float(i)
            except ValueError:
                print(f"Line '{i}' is not a number in {result}")
                return False
    return True


def test_consistency(more_results: list[list[Result]]) -> bool:
    """Tests if multiple runs produce consistent results.

    Compares the results of multiple runs to check if they are within the
    allowed error range.

    Args:
        more_results: List of lists of Result objects from multiple runs.

    Returns:
        True if all results are consistent, False otherwise.
    """
    success = True
    for i, results in enumerate(more_results):
        if i == len(more_results) - 1:
            break
        next_results = more_results[i + 1]
        for j, result in enumerate(results):
            if result.stdout is None:
                print(f"Found None result: {result}")
                return False
            next_result = next_results[j]
            if next_result.stdout is None:
                print(f"Found None result: {next_result}")
                return False

            lines = result.stdout.strip().split("\n")
            next_lines = next_result.stdout.strip().split("\n")
            if abs(float(lines[0]) - float(next_lines[0])) > functions[j].epsilon:
                print(
                    f"\nWrong result: {lines[0]} != {next_lines[0]} (+-{functions[j].epsilon})\n{result=}\n{next_result=}\n"
                )
                success = False
    return success


def test_result(results: list[Result]) -> bool:
    """Tests if the calculated results match the expected values.

    Args:
        results: List of Result objects to check.

    Returns:
        True if all results match the expected values within the error range,
        False otherwise.
    """
    success = True
    for i, result in enumerate(results):
        if result.stdout is None:
            print("Found None result")
            return False
        lines = result.stdout.split("\n")
        if abs(float(lines[0]) - functions[i].result) >= functions[i].epsilon:
            print(
                f"\nWrong result: {lines[0]} != {functions[i].result} (+-{functions[i].epsilon})\n{result=}\n"
            )
            success = False
    return success


def test_speed(results: list[Result], threaded_results: list[Result]) -> bool:
    """Tests if multithreaded execution is faster than single-threaded.

    Compares the execution time of single-threaded and multithreaded runs.

    Args:
        results: List of Result objects from single-threaded runs.
        threaded_results: List of Result objects from multithreaded runs.

    Returns:
        True if all multithreaded runs are faster, False otherwise.
    """
    success = True
    for i, result in enumerate(results):
        if result.stdout is None:
            print("Found None result")
            return False
        threaded_result = threaded_results[i]
        if threaded_result.stdout is None:
            print("Found None result")
            return False
        regular_time = int(result.stdout.split("\n")[3])
        threaded_time = int(threaded_result.stdout.split("\n")[3])
        if threaded_time > regular_time:
            print(f"\n{threaded_result=} is slower than {result=}\n")
            success = False
    return success


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


def main(
    project_path: str,
    binary_name: str,
    consistency_check: bool,
    speed_check: bool,
    print_tests: bool,
):
    """Main function to run all tests.

    Builds the project and runs format, consistency, correctness, and speed tests.

    Args:
        project_path: Path to the project root directory.
        binary_name: Name of the compiled binary to test.
        consistency_check: Whether to perform consistency checks.
        speed_check: Whether to perform speed checks.
        print_tests: Whether to print info about tests instead of running them.
    """
    consistency_threads = [get_next_prime()]
    for i in range(len(functions)):
        consistency_threads.append(get_next_prime(consistency_threads[i]))
    consistency_threads.pop(0)
    for i, threads in enumerate(consistency_threads):
        consistency_threads[i] = math.floor(threads)
    consistency_runs = 2

    speed_threads = [4, 7]

    if print_tests:
        for i, config in enumerate(configs):
            print("=============================")
            print(f"{functions[i]}")
            print()
            print("Config:")
            print(config)
        print("==============================")
        print("Number of threads to test consistency:")
        print(consistency_threads)
        print("Number of runs to test consistency:", consistency_runs)
        print("==============================")
        print("Number of threads to test speed:")
        print(speed_threads)
        return

    if not build(project_path):
        print("Build failed")
        return

    print("Running tests")
    results = get_results(project_path, binary_name, functions)
    additional_functions = [dataclasses.replace(func) for func in functions]

    print("=============================")
    print("Testing the format of output")
    if not test_format(results):
        print("Format tests failed")
        return
    print("Format tests passed")
    if consistency_check:
        print("=============================")
        print("Testing the consistency of result")
        more_results = [results]
        for i in range(len(additional_functions)):
            additional_functions[i].threads = consistency_threads[i]
        more_results += [
            get_results(project_path, binary_name, additional_functions)
            for _ in range(2)
        ]
        if not test_consistency(more_results):
            print("Consistency tests failed")
            return
        print("Consistency tests passed")
    print("=============================")
    print("Testing the correctness of results")
    if not test_result(results):
        print("Correctness tests failed")
        return
    print("Correctness tests passed")
    if speed_check:
        print("=============================")
        print("Testing the speed of different number of threads")
        for threads in speed_threads:
            for i in range(len(additional_functions)):
                additional_functions[i].threads = threads
            threaded_results = get_results(project_path, binary_name, additional_functions)
            if not test_speed(results, threaded_results):
                print(f"Speed tests failed at {threads} threads")
                return
    print("Result tests passed")

    print("All tests passed")


# Configuration strings for the three test functions
configs = [
    """abs_err=0.0005
rel_err = 0.00000002
x_start=-50
x_end=50
y_start=-50
y_end=50
init_steps_x = 100
init_steps_y = 100
max_iter=30""",
    """abs_err=0.0005
rel_err = 0.00000002
x_start=-100
x_end=100
y_start=-100
y_end=100
init_steps_x = 100
init_steps_y = 100
max_iter=30""",
    """abs_err=0.000001
rel_err = 0.00002
x_start=-10
x_end=10
y_start=-10
y_end=10
init_steps_x = 100
init_steps_y = 100
max_iter=10""",
]


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
        "-n",
        "--binary-name",
        help="Name of the binary to test after the build",
        type=str,
        default="integrate_parallel",
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
        "-C",
        "--consistency",
        action="store_true",
        help="Whether to check for consistent results on several attempts",
    )
    parser.add_argument(
        "-s",
        "--speed",
        action="store_true",
        help="Whether to check if 1 thread is slower than several threads",
    )
    args = parser.parse_args()
    print_tests: bool = args.print_tests
    build_path: str = args.build_path
    binary_name: str = args.binary_name
    clean: bool = args.clean
    consistency_check: bool = args.consistency
    speed_check: bool = args.speed

    project_path = setup(build_path)

    temp_files = []
    for config in configs:
        file = tempfile.NamedTemporaryFile("w", delete=False)
        file.write(config.strip())
        file.flush()
        temp_files.append(file)

    for func, temp_file in zip(functions, temp_files):
        func.config = temp_file.name
        temp_file.close()

    try:
        main(project_path, binary_name, consistency_check, speed_check, print_tests)
    finally:
        for temp_file in temp_files:
            os.unlink(temp_file.name)
        if clean:
            cleanup(project_path, build_path)
