#!/usr/bin/env python3
import argparse
import os
import sys
import subprocess
from pathlib import Path

DEFAULT_TIMEOUT = 60

class Result:
    def __init__(self, name: str):
        self.name = name
        self.steps = []

    def add(self, prefix: str, ok: bool, detail: str):
        self.steps.append((prefix, ok, detail))

    def summary(self) -> str:
        def first_msg(detail: str) -> str:
            if not detail:
                return ""
            for line in detail.splitlines():
                t = line.strip()
                if t and not t.startswith("exit="):
                    return t
            return detail.strip().splitlines()[0]
        lines = [f"\n=== {self.name} ==="]
        for task in ("Bash", "Make", "CMake"):
            rel = [s for s in self.steps if s[0].startswith(task)]
            if not rel:
                lines.append(f"{task}:  SKIP")
                continue
            ok = all(s[1] for s in rel)
            if ok:
                lines.append(f"{task}:  PASS")
            else:
                fail = next(s for s in rel if not s[1])
                lines.append(f"{task}:  FAIL — {fail[0]}: {first_msg(fail[2])}")
        return "\n".join(lines)

def run(cmd, cwd=None, timeout=DEFAULT_TIMEOUT, env=None):
    """Run a subprocess and capture stdout/stderr safely."""
    try:
        p = subprocess.run(cmd, cwd=cwd, timeout=timeout, env=env,
                           capture_output=True, text=True, check=False)
        return p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired as e:
        return 124, e.stdout or "", e.stderr or "Timeout"
    except KeyboardInterrupt:
        return 130, "", "Interrupted"
    except Exception as e:
        return 1, "", str(e)

def print_progress(stage: str, status: str):
    """Print a short progress line like: '[Bash] testing...' or '[Bash] done.'"""
    print(f"[{stage}] {status}")

def find_example_dir(project_dir: Path) -> Path | None:
    """Return examples dir path (prefer 'examples', else 'example'), or None."""
    d = project_dir / "examples"
    if d.is_dir():
        return d
    d = project_dir / "example"
    if d.is_dir():
        return d
    return None

def has_makefile(d: Path | None) -> bool:
    """True if dir has Makefile/makefile."""
    return bool(d and d.is_dir() and ((d / "Makefile").exists() or (d / "makefile").exists()))

def find_libs(project_dir: Path):
    """Find shared and static libraries only in project/library/bin/."""
    lib_bin = project_dir / "library" / "bin"
    if not lib_bin.is_dir():
        return [], []
    so = list(lib_bin.glob("lib*.so")) + list(lib_bin.glob("lib*.dylib"))
    a = list(lib_bin.glob("lib*.a"))
    return so, a

def find_example_objs(ex_dir: Path | None):
    """Find .o objects only in example(s)/obj/."""
    if not ex_dir:
        return []
    obj_dir = ex_dir / "obj"
    if not obj_dir.is_dir():
        return []
    return list(obj_dir.glob("*.o"))

def find_example_execs(ex_dir: Path | None):
    """Find executables only in example(s)/bin/ (files without extension and executable bit)."""
    if not ex_dir:
        return []
    bin_dir = ex_dir / "bin"
    if not bin_dir.is_dir():
        return []
    xs = []
    for p in bin_dir.glob("*"):
        if p.is_file() and os.access(p, os.X_OK) and p.suffix == "":
            xs.append(p)
    return xs

def hint_from_build_stderr(stderr: str) -> str:
    """Generate actionable hints from common compiler/linker errors."""
    s = stderr or ""
    if "fatal error:" in s and "bzlib.h" in s:
        return "Add -I./library (or correct include path) when compiling examples."
    if "cannot find -l" in s:
        return "Add -L./library/bin and ensure the lib is named lib<name>.so/.a there; add -Wl,-rpath,./library/bin for runtime."
    if "No such file or directory" in s and ".o" in s:
        return "Create the referenced object directory (mkdir -p …) or fix the object path."
    if "invalid conversion" in s and ".c:" in s:
        return "Compile C sources with gcc (or force C mode) instead of g++."
    return ""

def run_script_sh(script_path: Path):
    """Run a compile.sh via /bin/sh from its own folder so relative paths work."""
    return run(["/bin/sh", script_path.name], cwd=script_path.parent)

def check_bash(project_dir: Path):
    """Run compile.sh, then verify libs (library/bin), example objs (obj) and executables (bin)."""
    res = []
    script = project_dir / "compile.sh"
    if not script.exists():
        res.append(("Bash: compile.sh exists", False, "compile.sh not found at project root"))
        return res

    print_progress("Bash", "testing...")
    code, out, err = run_script_sh(script)
    detail = (err or out or "no output").strip()
    hint = hint_from_build_stderr(detail)
    if hint:
        detail = f"{detail.splitlines()[0]}\nHINT: {hint}"
    res.append(("Bash: run compile.sh", code == 0, f"exit={code}\n{detail}"))

    dyn, sta = find_libs(project_dir)
    lib_ok = (len(dyn) > 0 and len(sta) > 0)
    res.append(("Bash: libs in library/bin/", lib_ok, f"dynamic={len(dyn)}; static={len(sta)}"))

    ex_dir = find_example_dir(project_dir)
    if lib_ok and ex_dir:
        objs = find_example_objs(ex_dir)
        res.append(("Bash: objects in example/obj/", len(objs) > 0, f"count={len(objs)}"))
        exes = find_example_execs(ex_dir)
        res.append(("Bash: executables in example/bin/", len(exes) > 0, f"count={len(exes)}"))
    print_progress("Bash", "done.")
    return res

def check_make(project_dir: Path):
    """Run make clean+all in library first, then in example(s); verify artifacts."""
    res = []
    lib_dir = project_dir / "library"
    ex_dir = find_example_dir(project_dir)

    print_progress("Make", "testing...")
    if not lib_dir.is_dir():
        res.append(("Make: library dir exists", False, "library/ missing"))
        print_progress("Make", "done.")
        return res
    if ex_dir is None:
        res.append(("Make: example dir exists", False, "example or examples missing"))
        print_progress("Make", "done.")
        return res

    if not has_makefile(lib_dir):
        res.append(("Make: library Makefile present", False, "library/Makefile or library/makefile missing"))
    else:
        c1, o1, e1 = run(["make", "clean"], cwd=lib_dir)
        res.append(("Make: library clean", c1 == 0, (e1 or o1).strip()))
        c2, o2, e2 = run(["make"], cwd=lib_dir)
        res.append(("Make: library all", c2 == 0, (e2 or o2).strip()))

    if not has_makefile(ex_dir):
        res.append(("Make: example Makefile present", False, f"{ex_dir.name}/Makefile or {ex_dir.name}/makefile missing"))
    else:
        c3, o3, e3 = run(["make", "clean"], cwd=ex_dir)
        res.append(("Make: example clean", c3 == 0, (e3 or o3).strip()))
        c4, o4, e4 = run(["make"], cwd=ex_dir)
        res.append(("Make: example all", c4 == 0, (e4 or o4).strip()))

    dyn, sta = find_libs(project_dir)
    res.append(("Make: libs in library/bin/", len(dyn) > 0 or len(sta) > 0, f"dynamic={len(dyn)}; static={len(sta)}"))
    objs = find_example_objs(ex_dir)
    res.append(("Make: objects in example/obj/", len(objs) > 0, f"count={len(objs)}"))
    exes = find_example_execs(ex_dir)
    res.append(("Make: executables in example/bin/", len(exes) > 0, f"count={len(exes)}"))
    print_progress("Make", "done.")
    return res

def check_cmake(project_dir: Path):
    """Configure and build with CMake (root+library+example(s) CMakeLists required)."""
    res = []
    lib_dir = project_dir / "library"
    ex_dir = find_example_dir(project_dir)
    root_c = project_dir / "CMakeLists.txt"
    lib_c = lib_dir / "CMakeLists.txt"
    ex_c = ex_dir / "CMakeLists.txt" if ex_dir else None

    print_progress("CMake", "testing...")
    missing = []
    if not root_c.exists():
        missing.append("CMakeLists.txt at project root")
    if not lib_c.exists():
        missing.append("library/CMakeLists.txt")
    if not ex_dir or not ex_c or not ex_c.exists():
        missing.append("example(s)/CMakeLists.txt")
    if missing:
        res.append(("CMake: required CMakeLists", False, ", ".join(missing)))
        print_progress("CMake", "done.")
        return res

    b = project_dir / ".cmake-build"
    code, out, err = run(["cmake", "-S", str(project_dir), "-B", str(b)])
    res.append(("CMake: configure", code == 0, (err or out).strip()))
    if code == 0:
        code2, out2, err2 = run(["cmake", "--build", str(b)])
        res.append(("CMake: build", code2 == 0, (err2 or out2).strip()))

    print_progress("CMake", "done.")
    return res

def clean_all_artifacts(project_dir: Path):
    """Remove all build artifacts so each task starts clean and no leftovers remain."""
    lib_dir = project_dir / "library"
    ex_dir = find_example_dir(project_dir)
    if has_makefile(lib_dir):
        run(["make", "clean"], cwd=lib_dir)
    if has_makefile(ex_dir):
        run(["make", "clean"], cwd=ex_dir)
    for d in filter(None, [
        project_dir / "library" / "bin",
        project_dir / "library" / "obj",
        (ex_dir / "bin") if ex_dir else None,
        (ex_dir / "obj") if ex_dir else None,
        project_dir / ".cmake-build",
    ]):
        if d.exists():
            if d.is_dir():
                for p in d.rglob("*"):
                    try:
                        if p.is_file():
                            p.unlink()
                    except Exception:
                        pass
                try:
                    d.rmdir()
                except Exception:
                    pass
            else:
                try:
                    d.unlink()
                except Exception:
                    pass

def test_project(project_dir: Path, do_bash: bool, do_make: bool, do_cmake: bool) -> Result:
    """Run selected checks for one project with progress and cleanup after each task."""
    r = Result(project_dir.name)

    if do_bash:
        for t in check_bash(project_dir):
            r.add(*t)
        clean_all_artifacts(project_dir)

    if do_make:
        for t in check_make(project_dir):
            r.add(*t)
        clean_all_artifacts(project_dir)

    if do_cmake:
        for t in check_cmake(project_dir):
            r.add(*t)
        clean_all_artifacts(project_dir)

    return r

def parse_args():
    """Parse CLI: required project folders; optional selectors (default: run all)."""
    p = argparse.ArgumentParser(prog="test_lab2", description="Run Bash/Make/CMake checks for two projects")
    p.add_argument("--bash", action="store_true", help="Check compile.sh at project root")
    p.add_argument("--make", action="store_true", help="Check Makefiles in library/ and example(s)/")
    p.add_argument("--cmake", action="store_true", help="Check CMake configure/build")
    p.add_argument("--sample", "-S", required=True, help="Folder name for the sample project (required)")
    p.add_argument("--mystring", "-M", required=True, help="Folder name for the mystring project (required)")
    p.add_argument("--clean", "-c", action="store_true", help="(Ignored) always cleans after each task")
    args = p.parse_args()
    if not (args.bash or args.make or args.cmake):
        args.bash = args.make = args.cmake = True
    return args

def main():
    """Entry point: iterate projects, show progress, print per-project summaries, exit code."""
    args = parse_args()
    base = Path(".").resolve()
    projects = [args.sample, args.mystring]

    print("===== REPORT =====")
    results = []
    for proj in projects:
        d = base / proj
        if not d.exists():
            r = Result(proj)
            r.add("Bash: compile.sh exists", False, f"{proj} not found")
            r.add("Make: library dir exists", False, f"{proj} not found")
            r.add("CMake: required CMakeLists", False, f"{proj} not found")
            print(r.summary())
            results.append(r)
            continue

        print()
        print_progress("Project", f"{proj}: testing started…")
        res = test_project(d, args.bash, args.make, args.cmake)
        print_progress("Project", f"{proj}: test completed.")
        print(res.summary())
        results.append(res)

    any_fail = any(any(not s[1] for s in r.steps if s[0].startswith(t))
                   for r in results for t in ("Bash", "Make", "CMake"))
    sys.exit(1 if any_fail else 0)

if __name__ == "__main__":
    main()
