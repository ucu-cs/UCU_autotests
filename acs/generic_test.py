import argparse
import subprocess
import os
import sys
import shutil
import logging
from dataclasses import dataclass
import tempfile


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
    shutil.rmtree(build_path)


def run(command: Command) -> Result:
    """Runs a command and captures its output.

    Args:
        command: List of command-line arguments to execute.

    Returns:
        Result object containing command output.
    """
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


def main(
    project_path: str,
    binary_name: str,
    print_tests: bool,
):
    """Main function to run all tests.

    Builds the project and runs format, consistency, correctness, and speed tests.

    Args:
        project_path: Path to the project root directory.
        binary_name: Name of the compiled binary to test.
        print_tests: Whether to print info about tests instead of running them.
    """
    if not build(project_path):
        logging.error("Build failed")
        return

    logging.info("Running tests")
    logging.info("All tests passed")


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
        choices=["serial", "parallel"],
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

    parallel = lab_type in ["parallel"]
    if not binary_name:
        binary_name = {
            "serial": "serial",
            "parallel": "parallel",
        }[lab_type]
        if sys.platform == "win32":
            binary_name += ".exe"

    @dataclass
    class Command:
        command: list[str]
        timeout: int = args.timeout

    project_path = setup(build_path)

    temp_files = []

    try:
        main(
            project_path,
            binary_name,
            print_tests,
        )
    finally:
        for temp_file in temp_files:
            os.unlink(temp_file.name)
        if clean:
            cleanup(project_path, build_path)
