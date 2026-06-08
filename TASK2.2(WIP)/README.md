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
