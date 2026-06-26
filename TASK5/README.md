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

### 1.4 Internal Signal Planning

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


### 1.5 Expected Operation

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
