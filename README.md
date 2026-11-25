# INT8 systolic array

A 4x4 output-stationary systolic array in Verilog: signed INT8 inputs, INT32 accumulators, C = A x B in 11 clock cycles from start to done.

A Python golden model writes 300 matrix pairs, including the extreme values -128 and 127. The testbench compares every output element, checks that inputs are latched and that start is ignored while busy.

Run with `make` (Icarus Verilog and Python 3). Simulation only: not synthesised yet, so there are no area or timing numbers.

Written with an AI coding assistant.
