#!/usr/bin/env python3
#=========================================================================
# verif_riscv_dv_tests.py
#=========================================================================
# End-to-end script that:
#   1. Deletes existing assembly tests from riscv_dv/
#   2. Regenerates them by running riscv-dv
#   3. Transforms the riscv-dv output into Zeppelin-compatible assembly
#   4. Configures a fresh build directory with CMake
#   5. Compiles all ASM tests and both ELF test binaries, then runs them
#   6. Prints a structured pass/fail report to the terminal
#
# Usage:
#   python tools/verif_riscv_dv_tests.py
#   python tools/verif_riscv_dv_tests.py --build-dir my_build --parallel 8
#   python tools/verif_riscv_dv_tests.py --skip-gen --build-dir existing_build

import argparse
import concurrent.futures
import dataclasses
import html as html_mod
import os
import shutil
import subprocess
import sys
import threading
from datetime import datetime
from pathlib import Path

#-------------------------------------------------------------------------
# Paths
#-------------------------------------------------------------------------

REPO_ROOT     = Path(__file__).resolve().parent.parent
RISCV_DV_HOME = Path.home() / "riscv-dv"
ASM_TEST_DIR       = REPO_ROOT / "hw" / "top" / "test" / "riscv_dv_asm" / "test_asm"
CUSTOM_TARGETS_DIR = REPO_ROOT / "hw" / "top" / "test" / "riscv_dv_asm" / "custom_targets"

VERSIONS = ["ZeppelinV8", "Zeppelin"]
TARGETS  = [
  "rv32_base_zeppelin",
  "rv32_arith_zeppelin",
  "rv32_mem_zeppelin",
  "rv32_ctrl_zeppelin",
  "rv32_arith_mem_zeppelin",
  "rv32_arith_ctrl_zeppelin",
  "rv32_all_zeppelin",
]

RISCV_DV_CMD = [
  "python", "run.py",
  "--simulator=vcs",
  "--verbose",
  # "--iss=spike",
  "--steps=all",
  "--mabi=ilp32",
  "--isa=rv32im_zicsr_zifencei",
  "--iss_timeout=300",
  "-o", "out_SCRIPT_DESIGNATED__",
]

# Input directory that riscv-dv writes asm_test/ files into, derived
# from the -o flag above so it stays in sync automatically.
_RISCV_DV_OUT  = RISCV_DV_CMD[RISCV_DV_CMD.index("-o") + 1]
RISCV_DV_INPUT = RISCV_DV_HOME / _RISCV_DV_OUT / "asm_test"

#-------------------------------------------------------------------------
# Result dataclass
#-------------------------------------------------------------------------

@dataclasses.dataclass
class TestResult:
  name:     str
  version:  str
  build_ok: bool        = False
  run_ok:   bool | None = None   # None means skipped (build failed)
  stdout:   str         = ""
  stderr:   str         = ""

  def status_str( self ):
    if not self.build_ok:
      return "BUILD_ERR"
    if self.run_ok is None:
      return "SKIP"
    return "PASS" if self.run_ok else "FAIL"

#-------------------------------------------------------------------------
# Formatting helpers
#-------------------------------------------------------------------------

_WIDTH = 72

def _banner( msg ):
  print(f"\n{'=' * _WIDTH}\n  {msg}\n{'=' * _WIDTH}")

def _run( cmd, cwd, capture=False, check=True ):
  """
  Run a shell command, streaming or capturing output.
  """
  result = subprocess.run(cmd, cwd=str(cwd), text=True, capture_output=capture)
  if check and result.returncode != 0:
    raise subprocess.CalledProcessError(result.returncode, cmd,
                                        result.stdout, result.stderr)
  return result

#=========================================================================
# Step: Clean riscv_dv/
#=========================================================================

def step_clean():
  """
  Delete stale generated files so subsequent steps start from a known-clean state.

  Removes all ``*.S`` files from ASM_TEST_DIR and deletes the entire riscv-dv
  output directory (RISCV_DV_HOME / _RISCV_DV_OUT). Silently skips the output
  directory if it does not yet exist.
  """
  _banner("Step 1: Cleaning riscv_dv/")
  deleted = 0
  for f in ASM_TEST_DIR.glob("*.S"):
    f.unlink()
    deleted += 1
  print(f"  Deleted {deleted} file(s) from {ASM_TEST_DIR}")

  riscv_dv_out = RISCV_DV_HOME / _RISCV_DV_OUT
  if riscv_dv_out.exists():
    shutil.rmtree(riscv_dv_out)
    print(f"  Deleted riscv-dv output directory: {riscv_dv_out}")
  else:
    print(f"  riscv-dv output directory not found, skipping: {riscv_dv_out}")

#=========================================================================
# Step: Run riscv-dv
#=========================================================================

def step_riscv_dv():
  """
  Invoke riscv-dv once per target to generate randomised RISC-V assembly tests.

  Derives a deterministic-but-varied seed from wall-clock time (seconds since
  midnight) so successive runs on the same day produce different programs while
  still being reproducible when the seed is recorded. Runs each target in
  TARGETS sequentially inside RISCV_DV_HOME. Raises
  ``subprocess.CalledProcessError`` if any invocation exits non-zero.

  Returns:
    int: The seed used for all riscv-dv invocations this run.
  """
  _banner("Step 2: Running riscv-dv")
  now  = datetime.now()
  seed = now.hour * 3600 + now.minute * 60 + now.second
  print(f"  cwd : {RISCV_DV_HOME}")
  print(f"  seed: {seed}  ({now.strftime('%H:%M:%S')})")
  for target in TARGETS:
    tmp_cmd  = list(RISCV_DV_CMD)
    tmp_cmd += [f"--custom_target={CUSTOM_TARGETS_DIR / target}"]
    tmp_cmd += ["--seed", str(seed)]
    print(f"  cmd : {' '.join(tmp_cmd)}\n")
    _run(tmp_cmd, cwd=RISCV_DV_HOME)
  return seed

#=========================================================================
# Step: Transform riscv-dv output into Zeppelin-compatible assembly
#=========================================================================

def _transform( lines ):
  """
  Convert a riscv-dv generated .S file into a Zeppelin test_entry file.

  Slices the body from `init:` up to (not including) `kernel_instr_start:`,
  renames `init:` to `test_entry:`, and replaces the test-done block
  (`la <reg>, test_done` ... `j write_tohost`) with a jump to test_return.
  """
  import re

  # Locate init: label
  init_idx = next(
    (i for i, l in enumerate(lines)
     if re.match(r'^init:\s*$', l) or re.match(r'^init:\s+', l)),
    None
  )
  if init_idx is None:
    raise ValueError("Could not find 'init:' label")

  # Locate kernel_instr_start: label
  kernel_idx = next(
    (i for i, l in enumerate(lines)
     if re.match(r'^kernel_instr_start:\s*$', l)
     or re.match(r'^kernel_instr_start:\s+', l)),
    None
  )
  if kernel_idx is None:
    raise ValueError("Could not find 'kernel_instr_start:' label")

  body = lines[init_idx:kernel_idx]
  body[0] = re.sub(r'^init:', 'test_entry:', body[0])

  # Replace test-done termination block with jalr to test_return
  start_idx = next(
    (i for i, l in enumerate(body)
     if re.search(r'\bla\s+\w+,\s*test_done\b', l)),
    None
  )
  end_idx = next(
    (i for i, l in enumerate(body)
     if start_idx is not None and i >= start_idx
     and re.search(r'\bj\s+write_tohost\b', l)),
    None
  )
  if start_idx is None or end_idx is None:
    raise ValueError("Could not find test-done termination block")

  la_line   = re.sub(r'\btest_done\b', 'test_return', body[start_idx])
  jalr_line = body[start_idx + 1]
  body      = body[:start_idx] + [la_line, jalr_line] + body[end_idx + 1:]

  return ['.globl test_entry\n'] + body


def step_transform():
  """
  Convert every riscv-dv ``*.S`` file in RISCV_DV_INPUT into a Zeppelin-compatible
  assembly file and write it to ASM_TEST_DIR.

  The transformation (see ``_transform``) strips the kernel preamble, renames
  ``init:`` to ``test_entry:``, and replaces the ``write_tohost`` termination
  block with a jump to ``test_return`` so the file fits Zeppelin's test harness
  entry/exit convention. Files that cannot be transformed (missing expected
  labels) are logged and skipped rather than aborting the run.

  Creates ASM_TEST_DIR if it does not already exist.
  """
  _banner("Step 3: Transforming riscv-dv output")
  print(f"  Input : {RISCV_DV_INPUT}")
  print(f"  Output: {ASM_TEST_DIR}\n")

  ASM_TEST_DIR.mkdir(parents=True, exist_ok=True)

  written  = 0
  skipped  = 0
  for src in sorted(RISCV_DV_INPUT.glob("*.S")):
    dst = ASM_TEST_DIR / src.name
    lines = src.read_text().splitlines(keepends=True)
    try:
      result = _transform(lines)
    except ValueError as e:
      print(f"  Skipping {src.name}: {e}")
      skipped += 1
      continue
    dst.write_text("".join(result))
    written += 1

  print(f"  Written {written} file(s), skipped {skipped}")

#=========================================================================
# Step: CMake configuration
#=========================================================================

def step_cmake( build_name ):
  """
  Create a fresh CMake build directory and configure it for coverage builds.

  Deletes any existing directory at REPO_ROOT/build_name before recreating it,
  ensuring no stale CMake cache or generated files interfere. Configures with
  ``-DCOVERAGE=1``; all other options use CMake defaults. Raises
  ``subprocess.CalledProcessError`` if ``cmake`` exits non-zero.

  Args:
    build_name (str): Directory name relative to REPO_ROOT.

  Returns:
    Path: Absolute path to the newly created and configured build directory.
  """
  _banner(f"Step 4: Configuring build directory '{build_name}'")

  build_dir = REPO_ROOT / build_name
  if build_dir.exists():
    print(f"  Removing existing {build_dir} ...")
    shutil.rmtree(build_dir)
  build_dir.mkdir()
  print(f"  Created {build_dir}\n")

  _run(["cmake", "..", "-DCOVERAGE=1"], cwd=build_dir)
  return build_dir

#=========================================================================
# Step: Compile and run
#=========================================================================

def step_build_and_run( build_dir, parallel ):
  """
  Compile all ASM tests, build ELF test binaries, and run each test against
  each processor version.

  Three sub-phases run sequentially:

  * **5a** — Build ``asm-test-<name>`` for every ``.S`` file in ASM_TEST_DIR
    using a thread pool of size ``parallel``. Build failures are recorded but do
    not stop other tests.
  * **5b** — Build ``<version>_elf_test`` for each entry in VERSIONS. Exits the
    process if this fails (these binaries are required for 5c).
  * **5c** — Run every (version, test-name) pair in parallel. Tests whose ASM
    build failed are skipped (``run_ok=None``).

  Exits the process with status 1 if no assembly tests were found after step 3.

  Args:
    build_dir (Path): Build directory returned by ``step_cmake``.
    parallel  (int):  Maximum number of concurrent worker threads.

  Returns:
    tuple[list[str], dict[str, dict[str, TestResult]]]:
      ``test_names`` — ordered list of test stem names;
      ``results``    — ``results[version][name]`` gives the ``TestResult``.
  """
  _banner("Step 5: Compiling and running tests")

  asm_files  = sorted(ASM_TEST_DIR.glob("*.S"))
  test_names = [f.stem for f in asm_files]
  print(f"  Found {len(test_names)} assembly test(s)\n")

  if not test_names:
    print("  No tests found — did step 3 produce any .S files?")
    sys.exit(1)

  #-----------------------------------------------------------------------
  # 5a: Compile each asm-test-NAME
  #-----------------------------------------------------------------------

  print(f"  [5a] Compiling ASM tests (parallel={parallel}) ...")

  build_ok   = {}
  build_lock = threading.Lock()

  def _build_asm( name ):
    result = subprocess.run(
      ["make", f"asm-test-{name}"],
      cwd=str(build_dir), capture_output=True, text=True,
    )
    ok = result.returncode == 0
    with build_lock:
      build_ok[name] = ok
      mark = "ok" if ok else "FAIL"
      print(f"    asm-test-{name}: {mark}")
    return name, ok

  with concurrent.futures.ThreadPoolExecutor(max_workers=parallel) as pool:
    list(pool.map(_build_asm, test_names))

  n_asm_ok   = sum(build_ok.values())
  n_asm_fail = len(test_names) - n_asm_ok
  print(f"\n  ASM compilation: {n_asm_ok} ok, {n_asm_fail} failed\n")

  #-----------------------------------------------------------------------
  # 5b: Build ELF test binaries
  #-----------------------------------------------------------------------

  for version in VERSIONS:
    target = f"{version}_elf_test"
    print(f"  [5b] Building {target} ...")
    _run(["make", target, "-j"], cwd=build_dir)
  print()

  #-----------------------------------------------------------------------
  # 5c: Run each ELF against each test binary
  #-----------------------------------------------------------------------

  print(f"  [5c] Running {len(test_names) * len(VERSIONS)} test(s) "
        f"(parallel={parallel}) ...")

  results    = { v: {} for v in VERSIONS }
  run_lock   = threading.Lock()

  def _run_test( args ):
    version, name = args
    r = TestResult(name=name, version=version, build_ok=build_ok.get(name, False))

    if not r.build_ok:
      with run_lock:
        results[version][name] = r
      return

    elf_path = f"riscv_dv_asm/{name}"
    proc = subprocess.run(
      [f"./{version}_elf_test", f"+elf={elf_path}"],
      cwd=str(build_dir), capture_output=True, text=True,
    )
    r.run_ok = proc.returncode == 0
    r.stdout = proc.stdout
    r.stderr = proc.stderr

    with run_lock:
      results[version][name] = r
      mark = "PASS" if r.run_ok else "FAIL"
      print(f"    [{version}] {name}: {mark}")

  all_pairs = [(v, n) for v in VERSIONS for n in test_names]
  with concurrent.futures.ThreadPoolExecutor(max_workers=parallel) as pool:
    list(pool.map(_run_test, all_pairs))

  return test_names, results

#=========================================================================
# Email helper
#=========================================================================

def _send_email( subject, report_text ):
  result = subprocess.run(
    ["git", "config", "user.email"],
    capture_output=True, text=True,
  )
  email = result.stdout.strip()

  if not email:
    print("  WARNING: git config user.email not set, skipping email")
    return

  html_body = (
    "<html><body>"
    "<pre style=\"font-family: 'Courier New', Courier, monospace; font-size: 13px;\">"
    f"{html_mod.escape(report_text)}"
    "</pre></body></html>"
  )
  message = (
    f"To: {email}\n"
    f"Subject: {subject}\n"
    f"Content-Type: text/html; charset=utf-8\n"
    f"\n"
    f"{html_body}"
  )
  result = subprocess.run(
    ["sendmail", "-t"],
    input=message, capture_output=True, text=True,
  )
  if result.returncode == 0:
    print(f"  Email sent to {email}")
  else:
    print(f"  WARNING: failed to send email: {result.stderr}")

#=========================================================================
# Step: Report
#=========================================================================

def step_report( test_names, results, build_dir, start_time, seed=None ):
  """
  Print a structured pass/fail report and email it to the git committer address.

  Renders a fixed-width table with one column per VERSIONS entry and one row per
  test, showing ``PASS``, ``FAIL``, ``BUILD_ERR``, or ``SKIP``. Appends a
  per-version summary and, for any failures, the last five lines of stderr.

  The full report text is forwarded to ``_send_email`` via ``sendmail -t``;
  warnings are printed if the git email is unset or sendmail fails, but neither
  case aborts the run.

  Args:
    test_names (list[str]):                         Ordered test stem names.
    results    (dict[str, dict[str, TestResult]]):  Keyed by version then name.
    build_dir  (Path):                              Build directory, shown in header.
    start_time (datetime):                          Wall-clock start; used for elapsed time.
    seed       (int | None):                        riscv-dv seed, or None when ``--skip-gen``.

  Returns:
    bool: True if every test passed for every version, False otherwise.
  """
  _banner("Step 6: Results")

  # Column widths
  name_w   = max((len(n) for n in test_names), default=20)
  name_w   = max(name_w, 20)
  ver_w    = max(len(v) for v in VERSIONS)
  ver_w    = max(ver_w, 9)  # room for "BUILD_ERR"
  col_sep  = "  "

  sep_width = name_w + len(VERSIONS) * (len(col_sep) + ver_w)

  _buf = []

  def _emit( text="" ):
    print(text)
    _buf.append(text)

  def _row( label, vals ):
    line = f" {label:<{name_w}}"
    for v in vals:
      line += f"{col_sep}{v:>{ver_w}}"
    _emit(line)

  def _sep():
    _emit(" " + "-" * sep_width)

  #-----------------------------------------------------------------------
  # Header
  #-----------------------------------------------------------------------

  elapsed = datetime.now() - start_time
  _emit(f"\n{'=' * _WIDTH}")
  _emit(f" RISCV-DV Test Report")
  _emit(f" Generated : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
  _emit(f" Seed      : {seed if seed is not None else 'N/A (--skip-gen)'}")
  _emit(f" Build dir : {build_dir}")
  _emit(f" Elapsed   : {elapsed}")
  _emit(f"{'=' * _WIDTH}")

  #-----------------------------------------------------------------------
  # Per-test table
  #-----------------------------------------------------------------------

  _emit(f"\n RESULTS")
  _sep()
  _row("TEST", VERSIONS)
  _sep()

  status_counts = { v: {"PASS": 0, "FAIL": 0, "BUILD_ERR": 0, "SKIP": 0}
                    for v in VERSIONS }

  for name in test_names:
    vals = []
    for v in VERSIONS:
      r = results[v].get(name)
      s = r.status_str() if r else "SKIP"
      status_counts[v][s] = status_counts[v].get(s, 0) + 1
      vals.append(s)
    _row(name, vals)

  _sep()

  #-----------------------------------------------------------------------
  # Totals row
  #-----------------------------------------------------------------------

  total = len(test_names)
  totals = []
  for v in VERSIONS:
    c = status_counts[v]
    totals.append(f"{c['PASS']}/{total}")
  _row("PASSED", totals)

  #-----------------------------------------------------------------------
  # Status summary
  #-----------------------------------------------------------------------

  _emit(f"\n STATUS")
  _sep()

  overall_pass = True
  for v in VERSIONS:
    c      = status_counts[v]
    passed = c["PASS"]
    if passed == total:
      tag = "ALL PASSED"
    else:
      fails = c["FAIL"]
      errs  = c["BUILD_ERR"]
      tag   = f"FAILED  ({fails} fail, {errs} build_err)"
      overall_pass = False
    _emit(f"  {v:<{name_w}}  {tag}")

  #-----------------------------------------------------------------------
  # Failure details
  #-----------------------------------------------------------------------

  any_failures = any(
    r.run_ok is False or not r.build_ok
    for v in VERSIONS
    for r in results[v].values()
  )

  if any_failures:
    _emit(f"\n FAILURES")
    _sep()
    for v in VERSIONS:
      for name in test_names:
        r = results[v].get(name)
        if r and (not r.build_ok or r.run_ok is False):
          _emit(f"  [{v}] {name}: {r.status_str()}")
          if r.stderr:
            for line in r.stderr.strip().splitlines()[-5:]:
              _emit(f"    {line}")

  _emit(f"\n{'=' * _WIDTH}\n")

  report_text = "\n".join(_buf)
  tag         = "PASSED" if overall_pass else "FAILED"
  _send_email(f"[Zeppelin RISCV-DV] {tag}", report_text)

  return overall_pass

#=========================================================================
# main
#=========================================================================

def main():

  parser = argparse.ArgumentParser(
    description="Generate, compile, and run riscv-dv ELF tests against ZeppelinV8/V11"
  )
  parser.add_argument(
    "--build-dir", default="build_SCRIPT_DESIGNATED__",
    help="Name of the build directory to create (default: build_script)"
  )
  parser.add_argument(
    "--parallel", type=int, default=os.cpu_count() or 4,
    help="Number of parallel compile/run workers (default: CPU count)"
  )
  args = parser.parse_args()

  start_time = datetime.now()

  step_clean()
  seed = step_riscv_dv()
  step_transform()

  build_dir = step_cmake(args.build_dir)
  test_names, results = step_build_and_run(build_dir, args.parallel)
  ok = step_report(test_names, results, build_dir, start_time, seed=seed)

  sys.exit(0 if ok else 1)


if __name__ == "__main__":
  main()
