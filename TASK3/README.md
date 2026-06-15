# TASK 3

## Objective

Environment Setup & RISC-V Reference Bring-Up

## Environment Used

GitHub Codespace + Local Setup (Partial)

Local Environment: Ubuntu 18.04 LTS (VirtualBox)

## Step 1: GitHub Codespace Setup

The vsd-riscv2 repository was forked and launched using GitHub Codespaces.
The Codespace environment was created successfully and all required tools were available.


## Step 2: Toolchain Verification and RISC-V Reference Flow

The required development tools were verified and the sample RISC-V program sum1ton.c was compiled and executed successfully using the RISC-V GCC toolchain and Spike simulator.

### Source Code
```
#include <stdio.h>

int main() {

    int i, sum = 0, n = 100;

    for(i = 1; i <= n; i++)
        sum = sum + i;

    printf("Sum from 1 to %d is %d \n", n, sum);

    return 0;
}
```
Commands Used
```
- riscv64-unknown-elf-gcc --version
- spike --version
- iverilog -V
- cd samples
- riscv64-unknown-elf-gcc -o sum1ton.o sum1ton.c
- spike pk sum1ton.o
```
<img width="700" height="550" alt="Screenshot 2026-06-13 120425" src="https://github.com/user-attachments/assets/45ff4ad3-201d-4585-8237-550f0ffc58d2" />
<br><br>
<img width="700" height="550" alt="Screenshot 2026-06-13 120453" src="https://github.com/user-attachments/assets/c9ee1299-0d66-489a-9a49-90ece8eff3de" />
<br><br>
<img width="700" height="150" alt="Screenshot 2026-06-13 120751" src="https://github.com/user-attachments/assets/2fcac4e0-056b-4b46-8d28-cacb562286fb" />

## Step 3: VSDFPGA Lab Execution

The VSDFPGA repository was cloned inside the same GitHub Codespace environment.

- Clone Repository:
  ```
  git clone https://github.com/vsdip/vsdfpga_labs.git

  cd vsdfpga_labs
  ```
- Firmware Generation:

  The firmware image for the RISC-V logo application was generated successfully.

  ```
  cd vsdfpga_labs/basicRISCV/Firmware

  make riscv_logo.bram.hex
  ```
  The generated firmware image was copied to the RTL directory for further processing.
<img width="700" height="550" alt="Screenshot 2026-06-14 221400" src="https://github.com/user-attachments/assets/ac673eab-2ddd-4ed2-bb67-1d738578807b" />


- RISC-V Logo Program Execution

  The `riscv_logo.c` program was compiled and executed using the RISC-V GCC toolchain and Spike simulator.

  ```
  riscv64-unknown-elf-gcc -o riscv_logo.elf riscv_logo.c

  spike pk riscv_logo.elf
  ```
  Output

  ```text
  ************************************************************
  *                                                          *
  *   L E A R N   T O   T H I N K   L I K E   A   C H I P    *
  *                                                          *
  *      V S D S Q U A D R O N  F P G A   M I N I            *
  *                                                          *
  *B R I N G S   R I S C - V   T O   V S D  C L A S S R O O M*
  *                                                          *
  ************************************************************
  ```
<img width="700" height="550" alt="Screenshot 2026-06-15 121008" src="https://github.com/user-attachments/assets/7b7bc934-2c98-45e4-b2b8-7cb599fa516f" />

- Why **.elf** instead of **.o**?

  The .o file generated during compilation is an object file and may not contain all the information required for execution.   The .elf file is a fully linked executable that can be loaded by the Proxy Kernel (pk) and executed by the Spike
  simulator. Therefore, riscv_logo.elf was used for simulation instead of riscv_logo.o.

## Step 4: Local Machine Preparation

A local Ubuntu 18.04 LTS virtual machine was prepared using VirtualBox.

Both repositories were cloned locally:

```bash
git clone https://github.com/vsdip/vsd-riscv2.git
git clone https://github.com/vsdip/vsdfpga_labs.git
```
Note:

This step was performed to understand the local development environment required for future FPGA-related tasks. The repositories were cloned successfully in an Ubuntu virtual machine, and the Dockerfile was reviewed to identify the required tools, packages, and setup dependencies. As specified in the task instructions, a complete FPGA tool installation was not required at this stage.
