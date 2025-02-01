import argparse
import subprocess
import os
import shutil
from dataclasses import dataclass
import tempfile


@dataclass
class Function:
    number: int
    config: str
    result: float
    epsilon: float
    timeout: int = 30


functions = [
    Function(1, "", 4.54544762 * 10**6, 20),
    Function(2, "", 8.572082414 * 10**5, 20),
    Function(3, "", -1.604646665, 0.1),
]


def setup(build_path: str = "build") -> str:
    if not os.path.exists(build_path):
        print("Creating build directory: " + build_path)
        os.makedirs(build_path)
    else:
        print("Using existing build directory: " + build_path)
    project_path = os.getcwd()
    os.chdir(build_path)
    return project_path


def cleanup(project_path: str, build_path: str) -> None:
    print("Cleaning up")
    os.chdir(project_path)
    shutil.rmtree(build_path)


def run(command: list[str], timeout: int = 20) -> tuple[str, str] | None:
    try:
        process = subprocess.run(
            command, capture_output=True, text=True, timeout=timeout
        )
    except subprocess.CalledProcessError:
        print(f"Failed to execute {command}")
        return None
    except subprocess.TimeoutExpired:
        print(f"Timed out during execution of {command}")
        return None
    return process.stdout, process.stderr


def build(project_path: str) -> bool:
    print("Building project: " + project_path)
    return (
        run(["cmake", project_path]) is not None
        and run(["cmake", "--build", "."]) is not None
    )


def get_results(project_path: str) -> list[tuple[str, str] | None]:
    print("Running tests")
    return [
        run(
            [
                "./integrate_serial",
                str(func.number),
                os.path.join(project_path, func.config),
            ],
            func.timeout,
        )
        for func in functions
    ]


def test_format(results: list[tuple[str, str] | None]) -> bool:
    print("Testing the format of output result")
    for result in results:
        if result is None:
            print("Found None result")
            return False
        lines = result[0].strip().split("\n")
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


def test_result(results: list[tuple[str, str] | None]) -> bool:
    print("Testing the correctness of output result")
    for i, result in enumerate(results):
        if result is None:
            print("Found None result")
            return False
        lines = result[0].split("\n")
        if abs(float(lines[0]) - functions[i].result) >= functions[i].epsilon:
            print(
                f"Wrong result: {lines[0]} != {functions[i].result} (+-{functions[i].epsilon})"
            )
            return False
    return True


def main(project_path: str):
    if not build(project_path):
        print("Build failed")
        return
    results = get_results(project_path)

    if not test_format(results):
        print("Format test failed")
        return
    if not test_result(results):
        print("Result test failed")
        return

    print("All tests passed")


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
    parser.add_argument("build_path")
    parser.add_argument("-c", "--clean", action="store_true")
    args = parser.parse_args()
    build_path: str = args.build_path
    clean: bool = args.clean

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
        main(project_path)
    finally:
        for temp_file in temp_files:
            os.unlink(temp_file.name)
        if clean:
            cleanup(project_path, build_path)
