# TASK 2.1

## Objective

RISC-V SPIKE Simulation and Debug Analysis under -O1 and -Ofast Optimization Levels

### A. SPIKE SIMULATIOMN

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

### B. DEBUGGING OF INSTRUCTIONS
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

4. Navigate to the Main() Function
   ```
   until pc 0 10184
   ```
   <img width="700" height="550" alt="Screenshot 2026-06-05 152737" src="https://github.com/user-attachments/assets/95e8d04e-4078-4bfb-af55-14536b5f1787" />
- `addi sp, sp, -16` : Allocates 16 bytes of stack space. The stack pointer (`sp`) changes from `0x7f7e9b50` to `0x7f7e9b40`.

- `sd ra, 8(sp)` : Stores the return address register (`ra`) on the stack.

- `li a5, 100` : Loads the value `100 (0x64)` into register `a5`, which is used during program execution.

### Observation:
The SPIKE debugger successfully traced the execution of the optimized program and showed the changes in register values and stack memory during instruction execution.

### II. Debugging at Ofast Optimization level

1. Compile the Program with -Ofast Optimization
   ```
   riscv64-unknown-elf-gcc -Ofast -mabi=lp64 -march=rv64i -o sum1ton_O1.o sum1ton.c
   ```
2. Instruction Analysis using Objdump
   ```
   riscv64-unknown-elf-objdump -d sum1ton_O1.o | less
   ```
   <img width="700" height="550" alt="Screenshot 2026-06-05 151214" src="https://github.com/user-attachments/assets/8aed3501-6df4-4333-8dfb-4a9a618ce0f1" />

    The disassembled RISC-V object file generated at the -Ofast optimization level contained 12 instructions.

3. Start SPIKE in Debug Mode
   ```
   spike -d pk sum1ton_O1.o
   ```
4. Navigate to the Main() Function
   ```
   until pc 0 100b0
   ```
   <img width="700" height="550" alt="Screenshot 2026-06-05 151103" src="https://github.com/user-attachments/assets/98107af4-3db5-404a-8517-599756927025" />
- `lui a2, 0x1` : Loads the upper immediate value `0x1` into register `a2`. The register value changes from `0x0000000000000000` to `0x0000000000001000`.

- `lui a0, 0x21` : Loads the upper immediate value `0x21` into register `a0`. The register value changes from `0x0000000000000000` to `0x0000000000021000`.

- `addi sp, sp, -16` : Allocates 16 bytes of stack space. The stack pointer (`sp`) changes from `0x000000007f7e9b50` to `0x000000007f7e9b40`.

### Observation:
The SPIKE debugger successfully traced the execution of the **-Ofast** optimized program. Register values and stack memory updates were observed, showing how the compiler generated a highly optimized instruction sequence for efficient execution.

### Keywords
- **LUI (Load Upper Immediate):** Places the immediate value into bits 31:12 of the destination register and fills bits 11:0 with zeros.
- **ADDI (Add Immediate):** Adds an immediate value to a register.
- **SP (Stack Pointer):** Points to the top of the stack.
- **RA (Return Address):** Stores the return address of a function call.
- **PC (Program Counter):** Holds the address of the current instruction.
- **SD (Store Doubleword):** Stores a 64-bit value from a register into memory.
- **LI (Load Immediate):** Loads a constant value directly into a register.
