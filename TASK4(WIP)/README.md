# TASK 4

## Objective

Design & Integrate Your First Memory-Mapped IP

## IP Specification

### Functionality

* 32-bit GPIO register
* Write operation updates GPIO output
* Read operation returns the last stored value

### Interface

* Memory-mapped peripheral
* Connected to the existing CPU bus
* Uses existing SoC bus signals

## Step 1:  Understand the existing SoC

The provided basicRISCV design is a simple RISC-V System-on-Chip (SoC). It consists of a RISC-V processor core, on-chip memory (RAM), UART peripheral, LED interface, clock/reset circuitry, and address decoding logic. The processor communicates with memory and peripherals through a memory-mapped interface, forming a complete embedded system.

### a) Accessing the RTL Directory

<img width="550" height="186" alt="Screenshot 2026-06-18 161047" src="https://github.com/user-attachments/assets/8a166ccf-f1ec-494b-b12b-1ba2281c299c" />


### b) Identifying the Main RTL Modules

<img width="550" height="70" alt="Screenshot 2026-06-18 161219" src="https://github.com/user-attachments/assets/3cd59553-e5e5-4d98-83c2-b184f29aedf2" />

### c) Understanding the CPU Interface

Studied the connection between the Processor and the SoC through the memory interface.

<img width="550" height="52" alt="Screenshot 2026-06-18 200215" src="https://github.com/user-attachments/assets/cf297516-cad5-4c89-b829-0f2685625262" />

<img width="550" height="83" alt="Screenshot 2026-06-18 200239" src="https://github.com/user-attachments/assets/1473c925-72e4-4eae-80f2-08c9672d1c6c" />

These signals are used for communication between the CPU and memory/peripherals.

### d) Understanding Address Decoding

Studied the address decoding logic used by the SoC.


<img width="550" height="56" alt="Screenshot 2026-06-18 200457" src="https://github.com/user-attachments/assets/99400e1f-7b6a-4b22-a013-c619ae9b89fc" />

The design separates RAM accesses from I/O accesses using the address bus.

* `RAM_rdata` : Stores the 32-bit data read from RAM.
* `mem_wordaddr = mem_addr[31:2]` : Converts byte addresses into word addresses by removing the lower 2 bits.
* `isIO = mem_addr[22]` : Indicates whether the access is to an I/O peripheral.
* `isRAM = !isIO` : Indicates whether the access is to RAM.
* `mem_wstrb = |mem_wmask` : Generates the write strobe signal whenever a write operation occurs.

### e) RAM Interface Analysis

The RAM module is connected to the processor through the memory bus.

<img width="550" height="77" alt="Screenshot 2026-06-18 200600" src="https://github.com/user-attachments/assets/dae6ec7a-8441-45c9-b420-567e9817e9d1" />


* `clk` provides the system clock.
* `mem_addr` supplies the memory address.
* `RAM_rdata` returns data from RAM.
* `isRAM & mem_rstrb` enables RAM read operations.
* `mem_wdata` carries data to be written.
* `{4{isRAM}} & mem_wmask` enables RAM write operations.

### f) Memory-Mapped I/O Analysis

The SoC uses memory-mapped I/O to communicate with peripherals.

<img width="550" height="302" alt="Screenshot 2026-06-18 201118" src="https://github.com/user-attachments/assets/be982f1b-6b5c-43d4-9d50-926346f52cb7" />


* `IO_LEDS_bit` controls the onboard LEDs.
* `IO_UART_DAT_bit` is used to transmit UART data.
* `IO_UART_CNTL_bit` provides UART status information.
* UART communication is handled through dedicated memory-mapped registers.
* `IO_rdata` returns peripheral data to the processor during read operations.

## Step2: Writing the IP RTL

### GPIO IP Features:
- 32-bit register storage
- Synchronous write operation
- Readback support
- Reset functionality
- Compatible with the existing SoC bus interface

### GPIO IP Implementation:

The GPIO module was implemented in a new RTL file (gpio_ip.v).

### GPIO Interface

- `clk` : System clock
- `resetn` : Active-low reset
- `gpio_sel` : GPIO select signal
- `gpio_we` : GPIO write enable
- `gpio_wdata` : Data written by the processor
- `gpio_rdata` : Data returned during read operations
- `gpio_out` : Stored GPIO register value

<img width="550" height="462" alt="Screenshot 2026-06-18 220310" src="https://github.com/user-attachments/assets/d1b937cf-5122-48e3-8fe4-c32224fb8705" />


