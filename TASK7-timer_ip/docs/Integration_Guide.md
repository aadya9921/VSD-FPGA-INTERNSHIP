# Timer IP — Integration Guide

This guide assumes you are integrating this IP into **your own** VSDSquadron-based SoC, and are not familiar with the reference project this IP was originally developed in.

## Required Files

Copy the following into your project:

`rtl/timer_ip.v`

No other files are required — the IP has no external module dependencies.

## Module Interface

```verilog
module timer_ip (
    input            clk,
    input            resetn,
    input            sel,
    input            wr_en,
    input            rd_en,      // unused internally, kept for bus-interface symmetry
    input      [1:0] addr,       // word offset: 00=CTRL 01=LOAD 10=VALUE 11=STATUS
    input      [31:0] wdata,
    output reg [31:0] rdata,
    output           timeout_o
);
```

| Signal      | Direction | Width | Description                                                |
|-------------|-----------|-------|--------------------------------------------------------------|
| `clk`       | in        | 1     | System clock                                                  |
| `resetn`    | in        | 1     | Active-low asynchronous reset                                 |
| `sel`       | in        | 1     | Asserted when this IP's address range is selected             |
| `wr_en`     | in        | 1     | Write enable (bus write to this IP)                            |
| `rd_en`     | in        | 1     | Read enable (unused internally — reads are combinational; kept for interface consistency with other IPs on the same bus) |
| `addr`      | in        | 2     | Word offset into the register map (typically `mem_addr[3:2]`)  |
| `wdata`     | in        | 32    | Write data bus                                                 |
| `rdata`     | out       | 32    | Read data bus                                                  |
| `timeout_o` | out       | 1     | Sticky timeout flag, mirrors `STATUS.TIMEOUT`                  |

## Where to Instantiate It

Instantiate `timer_ip` alongside your other memory-mapped peripherals, at the same level as your CPU-to-bus connection (typically your top-level SoC module).

```verilog
timer_ip TIMER (
    .clk       (clk),
    .resetn    (resetn),
    .sel       (timer_sel),
    .wr_en     (timer_we),
    .rd_en     (timer_re),
    .addr      (mem_addr[3:2]),
    .wdata     (mem_wdata),
    .rdata     (timer_rdata),
    .timeout_o (timer_timeout)
);
```

## Address Decoding Expectations

The IP itself does **not** perform address decoding — that is the integrator's responsibility. `sel` must only be asserted when the bus address falls within the range you assign to this IP.

Recommended pattern (4KB-aligned window):

```verilog
localparam TIMER_BASE = 32'h2000_1000;   // choose any 4KB-aligned address
wire is_timer = (mem_addr[31:12] == TIMER_BASE[31:12]);

wire timer_sel = is_timer;
wire timer_we  = is_timer & |mem_wmask;
wire timer_re  = is_timer & mem_rstrb;
```

Then mux `timer_rdata` into your bus's read-data path alongside your other peripherals:

```verilog
assign mem_rdata =
    is_ram   ? ram_rdata   :
    is_timer ? timer_rdata :
    32'b0;
```

**Important:** `addr` must be the **word offset**, not the byte address — i.e. pass `mem_addr[3:2]`, not `mem_addr[3:0]`. Passing the raw byte address will cause register writes to land on the wrong offset.

## Signals Exposed to Top-Level

Only one signal needs to be routed beyond the immediate bus connection: `timeout_o`. Connect it to whatever should react to a timeout — an LED driver, an interrupt controller, another peripheral's enable line, etc. This IP does not assume or require any specific consumer.

## Pin Connections (If Applicable)

This IP has no direct physical pin connections of its own — it is a purely bus-side peripheral. If you connect `timeout_o` to an LED (as in the reference board demo), that LED's physical pin assignment is entirely up to your own board's PCF/constraint file; see `docs/Example_Usage.md` for the reference board demo's specific wiring and clock source used.

## Integration Checklist

- [ ] `timer_ip.v` copied into your RTL source tree
- [ ] Address decode (`is_timer`) added at a 4KB-aligned base address that doesn't overlap other peripherals
- [ ] `sel` / `wr_en` / `rd_en` correctly gated by `is_timer`
- [ ] `addr` connected as the 2-bit **word offset**, not byte address
- [ ] `rdata` muxed into your top-level read-data bus
- [ ] `timeout_o` connected to your intended consumer (LED, interrupt logic, etc.)
- [ ] `LOAD` value in your firmware recalculated for your actual system clock frequency
