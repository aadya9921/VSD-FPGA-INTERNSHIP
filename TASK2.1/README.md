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

### A. Debugging of  Instructions
### I. Debugging at O1 Optimization level

1. Compile the Program with -O1 Optimization
   ```
   riscv64-unknown-elf-gcc -O1 -mabi=lp64 -march=rv64i -o sum1ton_O1.o sum1ton.c
   ```
2. Instruction Analysis using Objdump
   ```
   riscv64-unknown-elf-objdump -d sum1ton_O1.o | less
   ```
   <img width="700" height="550" alt="Screenshot 2026-06-05 152339" src="https://github.com/user-attachments/assets/d554ddc3-8a13-4fe2-b9b2-159fe81e4b18" />

   The disassembled RISC-V object file generated at the -O1 optimization level contained 15 instructions.

3. Start SPIKE in Debug Mode
   ```
   spike -d pk sum1ton_O1.o
   ```

4. Navigate to the Main Function
   ```
   until pc 0 10184
   ```
   <img width="700" height="550" alt="Screenshot 2026-06-05 152737" src="https://github.com/user-attachments/assets/95e8d04e-4078-4bfb-af55-14536b5f1787" />
- `addi sp, sp, -16` : Allocates 16 bytes of stack space. The stack pointer (`sp`) changes from `0x7f7e9b50` to `0x7f7e9b40`.

- `sd ra, 8(sp)` : Stores the return address register (`ra`) on the stack.

- `li a5, 100` : Loads the value `100 (0x64)` into register `a5`, which is used during program execution.

### Observation:
The SPIKE debugger successfully traced the execution of the optimized program and showed the changes in register values and stack memory during instruction execution.

### I. Debugging at Ofast Optimization level
