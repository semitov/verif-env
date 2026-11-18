#!/usr/bin/env bash
# check-tools: print the version of every tool in the SemiTO-V verification
# image and exit non-zero if anything is missing. Run it after setup and
# paste its output when asking for help.

set -u
fail=0

row() { printf '  %-22s %s\n' "$1" "$2"; }

check() {
  # check <label> <command...>: run the command, print its first output line
  local label=$1; shift
  if ! command -v "$1" >/dev/null 2>&1; then
    row "$label" "MISSING ($1 not on PATH)"; fail=1; return
  fi
  local out
  out=$("$@" 2>&1 | head -n 1)
  row "$label" "${out:-ok}"
}

present() {
  # present <label> <command>: only check that the command exists
  if command -v "$2" >/dev/null 2>&1; then row "$1" "ok ($(command -v "$2"))"
  else row "$1" "MISSING"; fail=1; fi
}

echo "SemiTO-V verification image: tool check"
echo
echo "Simulation and formal"
check   "verilator"      verilator --version
check   "yosys"          yosys -V
present "sby"            sby
present "yosys-smtbmc"   yosys-smtbmc
check   "boolector"      boolector --version
check   "bitwuzla"       bitwuzla --version
check   "yices"          yices-smt2 --version
echo
echo "RISC-V"
present "spike"          spike
check   "dtc"            dtc --version
check   "riscv gcc"      riscv64-unknown-elf-gcc --version
if [ -f "${RISCV_FORMAL:-/opt/riscv-formal}/checks/genchecks.py" ]; then
  row "riscv-formal" "ok (${RISCV_FORMAL:-/opt/riscv-formal})"
else
  row "riscv-formal" "MISSING"; fail=1
fi
n=$(find "${RISCV_TESTS:-/opt/riscv-tests}/isa" -maxdepth 1 -type f -name 'rv32*' 2>/dev/null | wc -l)
if [ "$n" -gt 0 ]; then row "riscv-tests" "ok ($n RV32 test programs)"
else row "riscv-tests" "MISSING"; fail=1; fi
echo
echo "Python"
check "python" python3 --version
python3 - <<'EOF' || fail=1
from importlib.metadata import version, PackageNotFoundError
bad = False
for pkg in ("cocotb", "pyuvm", "cocotb-coverage", "pytest", "scapy"):
    try:
        print(f"  {pkg:<22} {version(pkg)}")
    except PackageNotFoundError:
        print(f"  {pkg:<22} MISSING")
        bad = True
raise SystemExit(1 if bad else 0)
EOF
echo
echo "Networking (Step 6)"
if [ -c /dev/net/tun ]; then row "/dev/net/tun" "ok"
else row "/dev/net/tun" "not available (start the container with --device=/dev/net/tun --cap-add=NET_ADMIN)"; fi

echo
if [ "$fail" -eq 0 ]; then echo "All tools found."; else echo "Some tools are missing: see above."; fi
exit "$fail"
