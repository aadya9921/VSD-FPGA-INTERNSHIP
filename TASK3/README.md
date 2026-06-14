# TASK 3

## Objective

Environment Setup & RISC-V Reference Bring-Up

## Environment Used

GitHub Codespace + Local Setup (Partial)

Local Environment: Ubuntu 18.04 LTS (VirtualBox)

### Step 1: GitHub Codespace Setup

The vsd-riscv2 repository was forked and launched using GitHub Codespaces.
The Codespace environment was created successfully and all required tools were available.


### Step 2: Toolchain Verification and RISC-V Reference Flow

The required development tools were verified and the sample RISC-V program sum1ton.c was compiled and executed successfully using the RISC-V GCC toolchain and Spike simulator.

Commands Used
```
- riscv64-unknown-elf-gcc --version
- spike --version
- iverilog -V
- cd samples
- riscv64-unknown-elf-gcc -o sum1ton.o sum1ton.c
- spike pk sum1ton.o
```
<img width="700" height="550" alt="Screenshot 2026-06-13 120425" src="https://github.com/user-attachments/assets/4d13b14a-     4f99-40fe-a9fd-b84a797f4bf0" />


<img width="700" height="550" alt="Screenshot 2026-06-13 120453" src="https://github.com/user-attachments/assets/2787ff0e-     7c31-459b-bd6a-b65960588a50" />


<img width="750" height="200" alt="Screenshot 2026-06-13 120751" src="https://github.com/user-attachments/assets/6ac9ef46-     f63d-4ad9-949a-198a13c7933c" />

