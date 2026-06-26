# TASK 5

## Objective

Design a Multi-Register GPIO IP with Software Control

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
