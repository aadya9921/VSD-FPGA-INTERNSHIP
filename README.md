# VSDSQUADRON FPGA INTERNSHIP 2026

### DETAILS:
#### Name: Aadya Rastogi
#### College: LNM Institute of Informationn Technology
#### Email ID: aadya9921@gmail.com
#### GitHub Profile: [@aadya9921](https://github.com/aadya9921)


<details>
<summary><b>Task 1 : Compilation of C Program using GCC and RISC-V GCC Compiler</b></summary>

## Objective

Refer to the C-based and RISC-V lab videos and execute the task of compiling a C program using GCC and RISC-V compiler.

## A. C BASED COMPILATION

#### 1. Create/Open the C file.
   ```
   leafpad sum1ton.c
   ```
<img width="700" height="550" alt="Screenshot 2026-06-02 130332" src="https://github.com/user-attachments/assets/9aa0d727-3f67-473d-9596-93520ff33b4f" />

#### 2. Compile the program
   ```
   gcc sum1ton.c
   ```
#### 3. Execute the generated executable
   ```
   ./a.out
   ```
<img width="700" height="550" alt="Screenshot 2026-06-02 130245" src="https://github.com/user-attachments/assets/24590b1d-4405-4d93-9849-da31a01b2894" />

### Output

Sum of numbers from 1 to 100 is 5050

### Result

The C program was successfully compiled using GCC and executed successfully.


## B. RISC-V BASED COMPILATION

#### 1. The following command opens the C code.
   ```
   cat sum1ton.c
   ```
<img width="700" height="550" alt="Screenshot 2026-06-02 163928" src="https://github.com/user-attachments/assets/53e34e4b-d054-4e73-8b30-571d70d282cc" />

#### 2. The C program was compiled using the RISC-V GCC compiler wtih O1 optimization level.
   ```
   riscv64-unknown-elf-gcc -O1 -mabi=lp64 -march=rv64i -o sum1ton.o sum1ton.c
   ```
#### 3. The object file was disassembled to study the generated RISC-V instructions on a new terminal. Type /main to locate the main section of our code.
   ```
   riscv64-unknown-elf-objdump -d sum1ton.o
   ```
<img width="700" height="550" alt="Screenshot 2026-06-02 164255" src="https://github.com/user-attachments/assets/903162fa-4cf0-416c-ba24-b0ad9ec7b0f2" />

#### 4. The C program was then compiled using the RISC-V GCC compiler wtih Ofast optimization level.
   ```
   riscv64-unknown-elf-gcc -Ofast -mabi=lp64 -march=rv64i -o sum1ton.o sum1ton.c
   ```
<img width="700" height="550" alt="Screenshot 2026-06-02 164439" src="https://github.com/user-attachments/assets/70204270-c877-4e23-a02e-3a13c6724dd6" />

#### 5. The object file was disassembled to study the generated RISC-V instructions.  Type /main to locate the main section of our code.
<img width="700" height="550" alt="Screenshot 2026-06-02 120649" src="https://github.com/user-attachments/assets/4bf521f7-b49e-437d-9a41-ee2c2dc7840f" />

### OPTIMIZATION COMPARISON
1. The -O1 optimization level performs basic optimizations and generates moderately optimized assembly code.(15 Instructions)
2. The -Ofast optimization level performs aggressive optimizations to improve execution speed, basically reduces unnecessary instructions and produce efficient machine code.(12 Instructions)
3. Higher optimization levels can improve performance but may make the generated assembly harder to understand.

### KEYWORDS
- #### riscv64-unknown-elf-gcc
  It is the RISC-V cross-compiler used to compile C/C++ programs into executable code for a RISC-V processor. It is part of the RISC-V GNU Toolchain.
  
- #### -O1
  -O1 is a compiler optimization level that performs basic optimizations to improve execution speed and reduce code size.

- #### -Ofast
  -Ofast is an aggressive optimization level that prioritizes performance and may apply optimizations beyond standard compliance.

- ##### -march=rv64i
   Specifies the target architecture as the 64-bit base RISC-V Integer Instruction Set (RV64I).

- #### -mabi=lp64
   Specifies the Application Binary Interface (ABI) where long integers and pointers are 64 bits wide.

- #### objdump
   A utility used to display information about object files and disassemble machine code into assembly instructions.

- #### Disassembly
   The process of converting machine code back into assembly language for analysis.


## OBSERVATIONS

- The C program was successfully compiled using the RISC-V GCC compiler and native GCC compiler.
- Different optimization levels produced different assembly instruction sequences.
- The `-Ofast` optimization generated more optimized code compared to `-O1`.
- The RISC-V assembly code can be analyzed using the `objdump` utility.

## CONCLUSION

The C program was successfully compiled for the RISC-V architecture using the RISC-V GCC compiler. The assembly code generated at different optimization levels was analyzed to understand the impact of compiler optimizations on instruction generation and program performance. It was observed that higher optimization levels produced shorter and more efficient code, improving performance. However, the optimized assembly code can be harder to read, understand and debug compared to the unoptimized version. This task helped in understanding the trade-off between code simplicity and performance.
