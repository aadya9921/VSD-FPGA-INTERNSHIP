# TASK 2.1

## Objective

RISC-V SPIKE Simulation and Debug Analysis under -O1 and -Ofast Optimization Levels

### A. SPIKE Simulation

1. Compile the C code using native GCC compiler.
   ```
   gcc sum1ton.c
   ./a.out
   ```
2. Compile the C code Using RISC-V GCC.
   ```
   riscv64-unknown-elf-gcc -Ofast -mabi=lp64 -march=rv64i -o sum1ton.o sum1ton.c
   ```
3. Run the Program on SPIKE Simulator.
   ```
   spike pk sum1ton.o
   ```
<img width="700" height="550" alt="Screenshot 2026-06-05 150032" src="https://github.com/user-attachments/assets/ea449569-3223-4dff-b6f6-e8d669072080" />

### Observation:
The SPIKE simulator successfully executed the RISC-V binary and produced the same output as native GCC Compiler.

    Sum from 1 to 100 is 5050
