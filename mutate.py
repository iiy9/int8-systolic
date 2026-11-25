#!/usr/bin/env python3
"""Mutation test: inject one fault at a time and check that a testbench fails."""
import pathlib, subprocess, sys, tempfile

ROOT = pathlib.Path(__file__).parent
RTL = ["pe", "systolic"]
# file, testbench, original text, faulty text
MUTANTS = [
    ("pe", "tb_systolic", "wire signed [15:0] prod", "wire [15:0] prod"),
    ("pe", "tb_systolic", "input  wire signed [7:0]  a_in, b_in", "input  wire [7:0]  a_in, b_in"),
    ("pe", "tb_systolic", "acc   <= acc + prod", "acc   <= prod"),
    ("pe", "tb_systolic", "if (rst || clr)", "if (rst)"),
    ("systolic", "tb_systolic", "LAST = 3*N-3", "LAST = 3*N-4"),
    ("systolic", "tb_systolic", "wire clr = start && !busy", "wire clr = start"),
    ("systolic", "tb_systolic", "a_r[(i*N + k)*8 +: 8]", "a_r[(k*N + i)*8 +: 8]"),
    ("systolic", "tb_systolic", "wire [7:0] k = t - i", "wire [7:0] k = t"),
    ("systolic", "tb_systolic", "a_r <= a_flat;", "a_r <= {a_flat[N*N*8-9:0], 8'd0};"),
]


def passes(tb, sources):
    with tempfile.TemporaryDirectory() as d:
        files = []
        for name, text in sources.items():
            p = pathlib.Path(d, name + ".v")
            p.write_text(text)
            files.append(str(p))
        out = pathlib.Path(d, "sim.vvp")
        subprocess.run(["iverilog", "-g2012", "-Wno-timescale", "-s", tb, "-o", str(out), *files,
                        str(ROOT / "tb" / (tb + ".v"))], check=True, capture_output=True)
        try:
            r = subprocess.run(["vvp", str(out)], cwd=ROOT, capture_output=True, text=True, timeout=60)
        except subprocess.TimeoutExpired:
            return False
        return "PASS" in r.stdout and "FAIL" not in r.stdout


clean = {n: (ROOT / "rtl" / (n + ".v")).read_text() for n in RTL}
for tb in sorted({m[1] for m in MUTANTS}):
    if not passes(tb, clean):
        sys.exit(f"{tb} fails on the unmodified design")
caught = 0
for name, tb, old, new in MUTANTS:
    if clean[name].count(old) != 1:
        sys.exit(f"{name}: expected exactly one '{old}'")
    ok = not passes(tb, {**clean, name: clean[name].replace(old, new)})
    caught += ok
    print("caught  " if ok else "SURVIVED", f"{name}: {old} -> {new or '(removed)'}")
print(f"{caught} of {len(MUTANTS)} faults caught")
sys.exit(caught != len(MUTANTS))
