# TASK 5

## Objective

Design a Multi-Register GPIO IP with Software Control

This task includes:

- Designing a multi-register GPIO peripheral.
- Implementing address-offset based register decoding.
- Adding GPIO direction control and readback functionality.
- Integrating the IP into the RISC-V SoC.
- Validating the design through C firmware and RTL simulation.

## Step 1: Study and Plan

The first step was to review the GPIO IP developed in Task-2 and understand its existing architecture. The Task-2 implementation contained a single GPIO data register that supported basic write and readback operations. Based on the Task-3 specification, the required enhancements were identified before starting the RTL implementation.

### 1.1 Planning

The following design changes were planned:

- Extend the single-register GPIO IP into a multi-register GPIO Control IP.
- Add dedicated registers for GPIO data, direction control, and readback.
- Implement address-offset based decoding to access multiple registers.
- Define the required internal signals for data storage, direction control, and read operations.
- Maintain compatibility with the existing memory-mapped RISC-V SoC interface.


### 1.2 Register Specification

**Base Address:** `0x00400020`

| Offset | Register | Description |
|:------:|----------|-------------|
| `0x00` | **GPIO_DATA** | Stores GPIO output data written by software. |
| `0x04` | **GPIO_DIR** | Configures GPIO direction (`1 = Output`, `0 = Input`). |
| `0x08` | **GPIO_READ** | Returns the current GPIO pin state. |

### 1.3 Address Offset Decoding

To support multiple registers within a single GPIO peripheral, address-offset decoding was planned using the lower address bits.

```text
gpio_addr = mem_addr[3:2]
```

| gpio_addr | Register Selected |
|:---------:|-------------------|
| `2'b00` | GPIO_DATA |
| `2'b01` | GPIO_DIR |
| `2'b10` | GPIO_READ |

This decoding mechanism enables the processor to access each register using a different offset while sharing the same GPIO base address.

### 1.4 Effect of GPIO Direction

The **GPIO_DIR** register determines whether each GPIO pin operates as an input or an output.

- **Bit = 1:** The corresponding GPIO pin acts as an **output**, and the value stored in `GPIO_DATA` is driven to `gpio_out`.
- **Bit = 0:** The corresponding GPIO pin acts as an **input**, and its value is obtained from `gpio_in`.

During read operations, the **GPIO_READ** register returns the current GPIO state based on the configured direction. This allows software to both control output pins and monitor input pins using the same GPIO peripheral.

### 1.5 Internal Signal Planning

The following internal signals were planned for the GPIO Control IP:

| Signal | Purpose |
|---------|---------|
| `gpio_data_reg` | Stores GPIO output data. |
| `gpio_dir_reg` | Stores the direction configuration for each GPIO pin. |
| `gpio_read_reg` | Stores the GPIO value returned during read operations. |
| `gpio_addr` | Selects the target register based on the address offset. |
| `gpio_wdata` | Receives data written by the processor. |
| `gpio_rdata` | Returns data to the processor during read operations. |
| `gpio_in` | Receives external GPIO input values. |
| `gpio_out` | Drives the GPIO output pins. |


### 1.6 Expected Operation

Based on the above planning:

- Writing to **GPIO_DATA** updates the GPIO output register.
- Writing to **GPIO_DIR** configures each GPIO pin as an input or an output.
- Reading **GPIO_DATA** returns the last value written to the data register.
- Reading **GPIO_READ** returns the current GPIO state based on the configured direction.


## Step 2: Implement Multi-Register RTL

Based on the planning completed in Step 1, the GPIO IP RTL was redesigned to support multiple memory-mapped registers. A new module, **`gpio_control.v`**, was created by extending the Task-2 GPIO IP. The implementation introduces separate registers for GPIO data, direction control, and readback while preserving compatibility with the existing SoC interface.

### RTL Implementation

The following features were implemented in the RTL:

- Added three internal registers:
  - `gpio_data_reg`
  - `gpio_dir_reg`
  - `gpio_read_reg`
- Implemented address-offset based register selection using `gpio_addr`.
- Added support for GPIO input through the `gpio_in` signal.
- Implemented synchronous write logic for GPIO_DATA and GPIO_DIR registers.
- Implemented combinational read logic to return the selected register value through `gpio_rdata`.
- Generated the GPIO output using the stored data and direction information.

```verilog
module gpio_control(
    input clk,
    input resetn,

    // Interface Signals
    input gpio_sel,
    input gpio_we,
    input [1:0] gpio_addr,
    input [31:0] gpio_wdata,

    // GPIO Inputs
    input [31:0] gpio_in,

    // Interface Outputs
    output reg [31:0] gpio_rdata,
    output [31:0] gpio_out
);

    //=========================================================
    // Register Definitions
    //=========================================================

    localparam GPIO_DATA = 2'b00;
    localparam GPIO_DIR  = 2'b01;
    localparam GPIO_READ = 2'b10;

    // Internal Registers
    reg [31:0] gpio_data_reg;
    reg [31:0] gpio_dir_reg;
    reg [31:0] gpio_read_reg;

    //=========================================================
    // Write Logic (Synchronous)
    //=========================================================

    always @(posedge clk) begin
        if (!resetn) begin
            gpio_data_reg <= 32'd0;
            gpio_dir_reg  <= 32'd0;
        end
        else if (gpio_sel && gpio_we) begin
            case (gpio_addr)
                GPIO_DATA: gpio_data_reg <= gpio_wdata;
                GPIO_DIR : gpio_dir_reg  <= gpio_wdata;
                default  : ;
            endcase
        end
    end

    //=========================================================
    // GPIO Read Register Generation
    //=========================================================

    always @(*) begin
        gpio_read_reg = (gpio_data_reg & gpio_dir_reg) |
                        (gpio_in & ~gpio_dir_reg);
    end

    //=========================================================
    // Read Logic (Combinational)
    //=========================================================

    always @(*) begin
        case (gpio_addr)
            GPIO_DATA: gpio_rdata = gpio_data_reg;
            GPIO_DIR : gpio_rdata = gpio_dir_reg;
            GPIO_READ: gpio_rdata = gpio_read_reg;
            default  : gpio_rdata = 32'd0;
        endcase
    end

    //=========================================================
    // GPIO Output
    //=========================================================

    assign gpio_out = gpio_data_reg;

endmodule

```

## Step 3: Integrate into the SoC

After implementing the GPIO Control IP, the SoC (`riscv.v`) was updated to integrate the enhanced peripheral. The integration was carried out while maintaining the existing memory-mapped I/O architecture used in Task-2. Only the required interface signals and address decoding logic were modified to support the new GPIO functionality.

### 3.1 Changes Made in the SoC

The following modifications were performed in `riscv.v`:

- Added new GPIO interface signals:
  - `gpio_addr`
  - `gpio_in`
- Updated the GPIO module instantiation to connect the new interface signals.
- Connected `gpio_addr` using the lower address bits:
  ```verilog
  assign gpio_addr = mem_addr[3:2];
  ```
- Connected `gpio_in` to a constant value for RTL simulation:
  ```verilog
  assign gpio_in = 32'h00000000;
  ```
- Retained the existing GPIO address selection logic (`gpio_sel`) and write enable (`gpio_we`).
- Connected `gpio_rdata` to the SoC read-data path.
- Connected `gpio_out` to the GPIO output interface.

### 3.2 Updated GPIO Module Instantiation

```verilog
gpio_control GPIO(
    .clk(clk),
    .resetn(resetn),
    .gpio_sel(gpio_sel),
    .gpio_we(gpio_we),
    .gpio_addr(gpio_addr),
    .gpio_wdata(mem_wdata),
    .gpio_in(gpio_in),
    .gpio_rdata(gpio_rdata),
    .gpio_out(gpio_out)
);
```

### 3.3 SoC Integration Summary

The enhanced GPIO Control IP was successfully integrated into the existing RISC-V SoC without modifying the overall memory-mapped I/O architecture. The updated interface enables software to access the GPIO_DATA, GPIO_DIR, and GPIO_READ registers while maintaining compatibility with the Task-2 integration flow.

## Step 4: Software Validation

The integrated GPIO Control IP was validated through RTL simulation using a dedicated firmware test program. The C program was developed to configure GPIO directions, write different data patterns, read back the GPIO state, and print the results through UART for verification.

### 4.1 GPIO Test Program

A C program (`gpio_control_test.c`) was created to verify the functionality of the GPIO Control IP.

The program performs the following operations:

- Configures different GPIO direction settings using **GPIO_DIR**.
- Writes multiple test patterns to **GPIO_DATA**.
- Reads the GPIO state using **GPIO_READ**.
- Prints all register values through UART.
- Verifies the correct operation of direction control and GPIO readback.

```c
#include <stdio.h>
#include <stdint.h>

#define GPIO_BASE 0x00400020

#define GPIO_DATA (*(volatile uint32_t *)(GPIO_BASE + 0x00))
#define GPIO_DIR  (*(volatile uint32_t *)(GPIO_BASE + 0x04))
#define GPIO_READ (*(volatile uint32_t *)(GPIO_BASE + 0x08))

int main(void)
{
    printf("\n==============================\n");
    printf(" GPIO CONTROL IP TEST - TASK 3\n");
    printf("==============================\n\n");

    // Test 1 : Configure all GPIO pins as outputs
    printf("Test 1 : Configure Direction\n");
    GPIO_DIR = 0xFFFFFFFF;
    printf("GPIO_DIR  : %X\n\n", GPIO_DIR);

    // Test 2 : Write first data pattern
    printf("Test 2 : Write Pattern 66398812\n");
    GPIO_DATA = 0x66398812;
    printf("GPIO_DATA : %X\n", GPIO_DATA);
    printf("GPIO_READ : %X\n\n", GPIO_READ);

    // Test 3 : Configure lower 16 bits as outputs
    printf("Test 3 : Configure Lower 16 Bits as OUTPUT\n");
    GPIO_DIR = 0x0000FFFF;
    printf("GPIO_DIR  : %X\n\n", GPIO_DIR);

    // Test 4 : Write second data pattern
    printf("Test 4 : Write Pattern A0A0A0A0\n");
    GPIO_DATA = 0xA0A0A0A0;
    printf("GPIO_DATA : %X\n", GPIO_DATA);
    printf("GPIO_READ : %X\n\n", GPIO_READ);

    // Test 5 : Mixed GPIO direction configuration
    printf("Test 5 : Mixed Direction Configuration\n");
    GPIO_DIR = 0x00FF00FF;
    printf("GPIO_DIR  : %X\n\n", GPIO_DIR);

    // Test 6 : Write third data pattern
    printf("Test 6 : Write Pattern 12345678\n");
    GPIO_DATA = 0x12345678;
    printf("GPIO_DATA : %X\n", GPIO_DATA);
    printf("GPIO_READ : %X\n\n", GPIO_READ);

    // Test 7 : Configure all GPIO pins as inputs
    printf("Test 7 : Configure All Inputs\n");
    GPIO_DIR = 0x00000000;
    printf("GPIO_DIR  : %X\n", GPIO_DIR);
    printf("GPIO_READ : %X\n\n", GPIO_READ);

    printf("==============================\n");
    printf("ALL GPIO TESTS COMPLETED\n");
    printf("==============================\n");

    return 0;
}
```

### 4.2 Firmware Compilation

The test program was compiled using the RISC-V toolchain to generate the firmware image.

**Command used:**

```bash
make gpio_control_test.bram.hex
```

### Build Flow

```
C Program
      │
      ▼
RISC-V ELF File
      │
      ▼
BRAM HEX File
      │
      ▼
firmware.hex
```

<img width="700" height="216" alt="Screenshot 2026-06-26 102558" src="https://github.com/user-attachments/assets/38fde97d-6e5e-4f6c-8caf-c45ac2745f70" />

### 4.3 UART Simulation Output

The generated firmware was executed on the RISC-V processor using RTL simulation. The UART output confirms the correct operation of the GPIO Control IP.

**Simulation Commands**

```bash
iverilog -DBENCH -o sim.vvp riscv.v gpio_control.v ice40_stubs.v
vvp -n sim.vvp
```

**Expected Output**

```text
==============================
GPIO CONTROL IP TEST - TASK 3
==============================

Test 1 : Configure Direction
GPIO_DIR  : FFFFFFFF

Test 2 : Write Pattern 66398812
GPIO_DATA : 66398812
GPIO_READ : 66398812

Test 3 : Configure Lower 16 Bits as OUTPUT
GPIO_DIR  : 0000FFFF

Test 4 : Write Pattern A0A0A0A0
GPIO_DATA : A0A0A0A0
GPIO_READ : 0000A0A0

Test 5 : Mixed Direction Configuration
GPIO_DIR  : 00FF00FF

Test 6 : Write Pattern 12345678
GPIO_DATA : 12345678
GPIO_READ : 00340078

Test 7 : Configure All Inputs
GPIO_DIR  : 00000000
GPIO_READ : 00000000

==============================
ALL GPIO TESTS COMPLETED
==============================
```

<img width="700" height="340" alt="Screenshot 2026-06-26 103551" src="https://github.com/user-attachments/assets/10a30cf0-474f-474e-af38-6571938b75fc" />


The successful execution of all test cases confirms that:

- GPIO direction control functions correctly.
- GPIO output data is written successfully.
- GPIO readback follows the configured GPIO direction.
- The GPIO Control IP is correctly integrated with the RISC-V SoC.

### 4.4 GTKWave Analysis

The RTL simulation waveform was analyzed using **GTKWave** to verify the functionality of the GPIO Control IP. The waveform confirms that the firmware successfully communicates with the GPIO peripheral through the memory-mapped interface and that all internal registers operate as expected.


<img width="900" height="449" alt="Screenshot 2026-06-26 105823" src="https://github.com/user-attachments/assets/425b7c9c-fa27-458e-83d7-bbdbeb594157" />

#### Observations:

- **GPIO Data Register (`gpio_data_reg`)**
  - Correctly stores the data written by the processor.
  - The waveform shows successive updates to:
    - `0x66398812`
    - `0xA0A0A0A0`
    - `0x12345678`

- **GPIO Direction Register (`gpio_dir_reg`)**
  - Updates according to the direction configurations programmed by the firmware.
  - The observed values are:
    - `0xFFFFFFFF`
    - `0x0000FFFF`
    - `0x00FF00FF`
    - `0x00000000`

- **GPIO Read Register (`gpio_read_reg`)**
  - Correctly returns the GPIO state based on the configured direction register.
  - Readback values change as expected during each test case.

- **GPIO Output (`gpio_out`)**
  - Reflects the value stored in `gpio_data_reg`, confirming successful output generation.

- **GPIO Input (`gpio_in`)**
  - Remains `0x00000000` throughout the simulation because it is connected to a constant input for RTL verification.

- **Address and Data Signals**
  - `gpio_addr` correctly selects the target register using address-offset decoding.
  - `mem_addr`, `mem_wdata`, and `mem_rdata` confirm successful memory-mapped communication between the RISC-V processor and the GPIO peripheral.

### Conclusion

The GTKWave results verify the correct operation of the multi-register GPIO Control IP. The waveform demonstrates successful register updates, proper address decoding, accurate GPIO direction control, and correct readback functionality. These observations confirm that the GPIO Control IP has been successfully integrated and validated within the RISC-V SoC.
