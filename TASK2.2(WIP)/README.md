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

## B. RISC-V BASED COMPILATION

#### 1. The C program was compiled using the RISC-V GCC compiler wtih O1 optimization level.
   ```
   riscv64-unknown-elf-gcc -O1 -mabi=lp64 -march=rv64i -o car_parking_counter.o car_parking_counter.c
   ```
#### 2. The object file was disassembled to study the generated RISC-V instructions on a new terminal. Type /main to locate the main section of our code.
   ```
   riscv64-unknown-elf-objdump -d car_parking_counter.o | less
   ```
<img width="700" height="550" alt="Screenshot 2026-06-07 212245" src="https://github.com/user-attachments/assets/0e9c1ca8-85c9-4b07-a2b9-be7446ed801c" />

O1 Optimization level produced 92 instructions.

#### 3. The C program was then compiled using the RISC-V GCC compiler wtih Ofast optimization level.
   ```
   riscv64-unknown-elf-gcc -Ofast -mabi=lp64 -march=rv64i -o car_parking_counter.o car_parking_counter.c
   ```
#### 4. The object file was disassembled to study the generated RISC-V instructions.  Type /main to locate the main section of our code.
<img width="700" height="550" alt="Screenshot 2026-06-08 124434" src="https://github.com/user-attachments/assets/2456bf37-2a25-4f3d-80b9-798f4ef74e24" />

Ofast Optimization level produced 98 instructions.

## C. SPIKE SIMULATION

#### 1. Compile the C code Using RISC-V GCC.
   ```
   riscv64-unknown-elf-gcc -Ofast -mabi=lp64 -march=rv64i -o sum1ton.o sum1ton.c
   ```
#### 2. Run the Program on SPIKE Simulator.
   ```
   spike pk sum1ton.o
   ```
<img width="700" height="550" alt="Screenshot 2026-06-08 125931" src="https://github.com/user-attachments/assets/e1678b03-97ef-4e3d-8808-4e131152a915" />
