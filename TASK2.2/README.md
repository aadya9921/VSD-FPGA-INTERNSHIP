# Car Parking Counter using C, RISC-V GCC and SPIKE Simulator

## Objective

To design and implement a Car Parking Counter application in C and analyze its execution using the RISC-V GCC compiler and SPIKE simulator. The project demonstrates counter-based logic for tracking parked vehicles and available parking slots.

## Application Description

A Car Parking Counter is a simple parking management system that keeps track of the number of vehicles in a parking area. The counter increases when a vehicle enters and decreases when a vehicle exits. The system also displays the number of available parking slots and prevents the count from exceeding the maximum parking capacity.

## Flow Diagram
```
Start
  |
Initialize Count = 0
  |
Display Menu
  |
Read Choice
  |
  +--> Car Enter?
  |       |
  |       +--> Count < Capacity ?
  |               |
  |               +--> Yes -> Count++
  |               |
  |               +--> No -> Parking Full
  |
  +--> Car Exit?
  |       |
  |       +--> Count > 0 ?
  |               |
  |               +--> Yes -> Count--
  |               |
  |               +--> No -> Parking Empty
  |
  +--> Exit?
          |
          +--> End Program

Display Available Slots
  |
Back to Menu
```

## A. C BASED COMPILATION

#### 1. Create/Open the C file.
   ```
   gedit car_parking_counter.c
   ```
#### SOURCE CODE 
   ```
   #include <stdio.h>

int main()
{
    int count = 0;
    int choice;
    const int capacity = 10;

    printf("=== Car Parking Counter ===\n");
    printf("Parking Capacity = %d\n", capacity);

    while(1)
    {
        printf("\nCars Parked: %d\n", count);
        printf("1. Car Enter\n");
        printf("2. Car Exit\n");
        printf("3. Exit Program\n");
        printf("Enter Choice: ");
        scanf("%d", &choice);

        switch(choice)
        {
            case 1:
                if(count < capacity)
                {
                    count++;
                    printf("Car Entered\n");
                }
                else
                {
                    printf("Parking Full!\n");
                }
                break;

            case 2:
                if(count > 0)
                {
                    count--;
                    printf("Car Exited\n");
                }
                else
                {
                    printf("Parking Empty!\n");
                }
                break;

            case 3:
                printf("Exiting Program...\n");
                return 0;

            default:
                printf("Invalid Choice!\n");
        }

        printf("Available Slots: %d\n", capacity - count);
    }

    return 0;
}
   ```
#### 2. Compile the program
   ```
   gcc car_parking_counter.c
   ```
#### 3. Execute the generated executable
   ```
   ./a.out
   ```
<img width="700" height="550" alt="Screenshot 2026-06-07 211410" src="https://github.com/user-attachments/assets/9915e068-3b53-49af-a8d9-ae49e15be157" />

### Result

The C program was successfully compiled using GCC and executed successfully.

## B. RISC-V GCC COMPILATION AND SPIKE SIMULATION

#### 1. Compile the C code Using RISC-V GCC.
   ```
   riscv64-unknown-elf-gcc -Ofast -mabi=lp64 -march=rv64i -o car_parking_counter.o car_parking_counter.c
   ```
#### 2. Run the Program on SPIKE Simulator.
   ```
   spike pk car_parking_counter.o
   ```
<img width="700" height="550" alt="Screenshot 2026-06-08 125931" src="https://github.com/user-attachments/assets/e1678b03-97ef-4e3d-8808-4e131152a915" />

### Observation:

The SPIKE simulator successfully executed the RISC-V binary and produced the same functional output as the native GCC compiler. Minor differences were observed in the formatting of console input/output due to the way SPIKE handles terminal I/O and input buffering. However, these differences did not affect the correctness of program execution.

## C. ANALYSIS AND DEBUGGING OF INSTRUCTIONS
### I. FOR O1 OPTIMIZATION LEVEL
#### 1. The C program was compiled using the RISC-V GCC compiler wtih *O1* optimization level.
   ```
   riscv64-unknown-elf-gcc -O1 -mabi=lp64 -march=rv64i -o car_parking_counter.o car_parking_counter.c
   ```
#### 2. The object file was disassembled to study the generated RISC-V instructions on a new terminal. Type /main to locate the main section of our code.
   ```
   riscv64-unknown-elf-objdump -d car_parking_counter.o | less
   ```
<img width="700" height="550" alt="Screenshot 2026-06-07 212245" src="https://github.com/user-attachments/assets/0e9c1ca8-85c9-4b07-a2b9-be7446ed801c" />

#### 3. Start SPIKE in Debug Mode
   ```
   spike -d pk car_parking_counter.o
   ```

#### 4. Navigate to the Main() Function
   ```
   until pc 0 10184
   ```
<img width="700" height="550" alt="Screenshot 2026-06-08 214722" src="https://github.com/user-attachments/assets/f0c78033-e04a-4d3f-a525-c2bd205185fd" />

- `addi sp, sp, -96` : Allocates 96 bytes of stack space. The stack pointer (`sp`) changes from `0x7f7e9b40` to `0x7f7e9ae0`.

- `sd ra, 88(sp)` : Stores the return address register (`ra`) on the stack. The value stored is `0x000000000001010c`.

- `sd s0, 80(sp)` : Stores the saved register (`s0`) on the stack. At this stage, `s0` contains `0x0000000000000000`.

### Observation:

O1 Optimization level produced 92 instructions. The debug analysis showed that the program allocates stack space and saves important registers (`ra` and `s0`) at the start of the `main()` function. This helps maintain correct program execution and function control flow.

### II. FOR Ofast OPTIMIZATION LEVEL
#### 1. The C program was compiled using the RISC-V GCC compiler wtih *Ofast* optimization level.
   ```
   riscv64-unknown-elf-gcc -Ofast -mabi=lp64 -march=rv64i -o car_parking_counter.o car_parking_counter.c
   ```
#### 2. The object file was disassembled to study the generated RISC-V instructions on a new terminal. Type /main to locate the main section of our code.

<img width="700" height="550" alt="Screenshot 2026-06-08 124434" src="https://github.com/user-attachments/assets/cd0e790e-0ca9-48ff-88e2-d46dad0bbca9" />

#### 3. Start SPIKE in Debug Mode
   ```
   spike -d pk car_parking_counter.o
   ```

#### 4. Navigate to the Main() Function
   ```
   until pc 0 100b0
   ```
<img width="700" height="550" alt="Screenshot 2026-06-08 215601" src="https://github.com/user-attachments/assets/aeefdcc1-8e29-4596-bc45-11a441f2432b" />

- `lui a0, 0x2b` : Loads the upper 20 bits (`0x2b`) into register `a0`. The value of `a0` changes from `0x0000000000000001` to `0x000000000002b000`.

- `addi sp, sp, -128` : Allocates 128 bytes of stack space. The stack pointer (`sp`) changes from `0x7f7e9b40` to `0x7f7e9ac0`.

- `addi a0, a0, -448` : Adds an immediate value of `-448` to register `a0`. The value of `a0` changes from `0x000000000002b000` to `0x000000000002ae40`.

### Observation:

Ofast Optimization level produced 98 instructions. The SPIKE debugger successfully traced the execution of the optimized (`-Ofast`) build. It was observed that the compiler used instructions such as `lui` and `addi` to efficiently generate memory addresses and allocate stack space. Compared to lower optimization levels, the generated code was more performance-oriented, demonstrating the effect of aggressive compiler optimizations.

## KEY LEARNINGS

Learned that higher optimization levels do not always produce fewer instructions. Although the `-Ofast` build generated 98 instructions compared to 92 instructions for `-O1`, this is normal because `-Ofast` prioritizes execution performance and speed over code size. To improve speed, the compiler may apply additional optimizations such as instruction scheduling, branch restructuring, and function inlining, which can sometimes increase the instruction count while still improving overall efficiency.

## CONCLUSION

The Car Parking Counter application was successfully developed and tested using GCC, RISC-V GCC, and the SPIKE simulator. The program correctly monitored vehicle entry and exit while updating the parking count and available slots for both Native GCC and RISC-V GCC. The assembly code generated at the `-O1` and `-Ofast` optimization levels was analyzed through SPIKE debugging to understand how compiler optimizations affect program execution. It was observed that the `-Ofast` build produced slightly more instructions (98) than the `-O1` build (92), showing that higher optimization levels aim to improve performance rather than simply reduce instruction count. Overall, this task provided hands-on experience with RISC-V compilation, simulation, debugging, and optimization analysis through a real-world application.
