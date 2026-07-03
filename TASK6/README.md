# TASK 6

## Objective

### Timer IP — Core Contributor Task (Task-4)

## Overview

This is a minimal, memory-mapped **Timer peripheral IP** designed and integrated into an existing RISC-V SoC (based on the `femtorv32`-style single-cycle-bus processor). The Timer provides a programmable countdown that generates a `TIMEOUT` event and status flag, supporting both **one-shot** and **periodic (auto-reload)** modes, with an optional prescaler.

- **Owner:** Timer IP (Option 1)
- **SoC integration base address:** `TIMER_BASE = 0x2000_1000`
- **Bus interface:** memory-mapped, 32-bit registers, word-aligned accesses

---

## What the IP Does

The Timer IP counts down from a software-programmed value (`LOAD`) to zero, at a rate controlled by an optional prescaler. When the count reaches zero:

- A sticky `TIMEOUT` status bit is set.
- In **one-shot mode**, the timer stops (value stays at 0, `EN` remains set).
- In **periodic mode**, the value automatically reloads from `LOAD` and counting continues — no software intervention needed between cycles.

Software detects a timeout by polling `STATUS.TIMEOUT`, and clears it with a **write-1-to-clear** to the same bit. On real hardware, every `TIMEOUT` event toggles an onboard LED, giving a visible heartbeat.

**timer_ip.v**
```verilog
module timer_ip (
    input            clk,
    input            resetn,
    // Bus interface (matches SOC instantiation)
    input            sel,
    input            wr_en,
    input            rd_en,     // unused internally (combinational read), kept for interface match
    input      [1:0] addr,      // word offset: 00=CTRL 01=LOAD 10=VALUE 11=STATUS
    input      [31:0] wdata,
    output reg [31:0] rdata,
    // Output
    output           timeout_o
);
    // ------------------------------------------------------------
    // Register map (word offsets, matches mem_addr[3:2])
    // ------------------------------------------------------------
    localparam REG_CTRL  = 2'b00;  // 0x00
    localparam REG_LOAD  = 2'b01;  // 0x04
    localparam REG_VALUE = 2'b10;  // 0x08
    localparam REG_STAT  = 2'b11;  // 0x0C

    // ------------------------------------------------------------
    // Internal registers
    // ------------------------------------------------------------
    reg        en, mode, presc_en;
    reg [7:0]  presc_div;
    reg [31:0] load_reg;
    reg [31:0] value_reg;
    reg        timeout_flag;
    reg        en_prev;
    reg [7:0]  presc_cnt;

    assign timeout_o = timeout_flag;

    // ------------------------------------------------------------
    // Write logic — CTRL / LOAD (STATUS clear handled in core block)
    // ------------------------------------------------------------
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            en        <= 1'b0;
            mode      <= 1'b0;
            presc_en  <= 1'b0;
            presc_div <= 8'd0;
            load_reg  <= 32'd0;
        end else if (sel && wr_en) begin
            case (addr)
                REG_CTRL: begin
                    en        <= wdata[0];
                    mode      <= wdata[1];
                    presc_en  <= wdata[2];
                    presc_div <= wdata[15:8];
                end
                REG_LOAD: load_reg <= wdata;
                default: ; // REG_VALUE read-only, REG_STAT handled below
            endcase
        end
    end

    // ------------------------------------------------------------
    // Prescaler tick generation
    // ------------------------------------------------------------
    wire tick = en && (!presc_en || (presc_cnt == presc_div));

    always @(posedge clk or negedge resetn) begin
        if (!resetn) presc_cnt <= 8'd0;
        else if (!en)               presc_cnt <= 8'd0;
        else if (presc_en && tick)  presc_cnt <= 8'd0;
        else if (presc_en)          presc_cnt <= presc_cnt + 1'b1;
    end

    // ------------------------------------------------------------
    // Timer core: load-on-enable, countdown, sticky TIMEOUT,
    // write-1-to-clear
    // ------------------------------------------------------------
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            value_reg    <= 32'd0;
            timeout_flag <= 1'b0;
            en_prev      <= 1'b0;
        end else begin
            en_prev <= en;

            if (en && !en_prev) begin
                // Timer just started: load initial value
                value_reg <= load_reg;
            end else if (en && tick) begin
                if (value_reg == 32'd0) begin
                    timeout_flag <= 1'b1;
                    if (mode)
                        value_reg <= load_reg;   // periodic reload
                    // else: one-shot, VALUE stays 0, EN stays 1
                end else begin
                    value_reg <= value_reg - 1'b1;
                end
            end

            // Write-1-to-clear
            if (sel && wr_en && addr == REG_STAT && wdata[0])
                timeout_flag <= 1'b0;
        end
    end

    // ------------------------------------------------------------
    // Read logic
    // ------------------------------------------------------------
    always @(*) begin
        case (addr)
            REG_CTRL:  rdata = {16'b0, presc_div, 5'b0, presc_en, mode, en};
            REG_LOAD:  rdata = load_reg;
            REG_VALUE: rdata = value_reg;
            REG_STAT:  rdata = {31'b0, timeout_flag};
            default:   rdata = 32'b0;
        endcase
    end
endmodule
```
---

## Register Map

Base address: `TIMER_BASE = 0x2000_1000`

| Offset | Name   | R/W | Description                  |
|--------|--------|-----|-------------------------------|
| 0x00   | CTRL   | R/W | Control bits                  |
| 0x04   | LOAD   | R/W | Countdown start value         |
| 0x08   | VALUE  | R   | Current countdown value       |
| 0x0C   | STATUS | R/W | Timeout status / clear        |

### CTRL (0x00)

| Bits   | Field      | Description                                              |
|--------|------------|------------------------------------------------------------|
| 0      | EN         | 1 = enable counting, 0 = stop                              |
| 1      | MODE       | 0 = one-shot, 1 = periodic / auto-reload                   |
| 2      | PRESC_EN   | 0 = no prescale, 1 = prescale enabled                      |
| 15:8   | PRESC_DIV  | Prescaler divide value; effective divisor = (PRESC_DIV+1)  |
| others | —          | Reserved, read as 0                                        |

### LOAD (0x04)
32-bit value the countdown loads on start (`EN` rising edge) and on every periodic reload.

### VALUE (0x08)
Current countdown value. **Read-only.** Writes are ignored.

### STATUS (0x0C)

| Bit | Field   | Description                                              |
|-----|---------|-------------------------------------------------------------|
| 0   | TIMEOUT | Set to 1 when countdown reaches 0. **Write 1 to clear.**    |

---

## Functional Behavior

- While `EN=1`, `VALUE` decrements once per tick (every clock cycle if the prescaler is disabled, or every `PRESC_DIV+1` cycles if enabled).
- When `VALUE` reaches 0:
  - `TIMEOUT` is set (and stays set — **sticky** — until explicitly cleared by software).
  - **One-shot (`MODE=0`):** counting stops; `VALUE` remains 0, `EN` stays 1.
  - **Periodic (`MODE=1`):** `VALUE` reloads from `LOAD` and counting continues automatically.
- On `EN` rising edge (0→1), `VALUE` is loaded from `LOAD` before the first decrement — this avoids a false immediate timeout on enable.

---

## SoC Integration

- **Address decoding:** `is_timer = (mem_addr[31:12] == TIMER_BASE[31:12])` — gives the Timer IP its own 4KB address window, isolated from RAM and UART.
- **Bus connection:** standard `sel` / `wr_en` / `addr` / `wdata` / `rdata` interface, driven from the CPU's `mem_addr`, `mem_wmask`, `mem_wdata`, and `mem_rstrb` signals via the top-level `SOC` module.
- **Read mux:** `mem_rdata` is muxed between RAM, Timer, and UART based on which address region is selected.
- **LED demo:** `timeout_o` from the Timer IP feeds an edge-detector in `SOC` that toggles `led_toggle` on every rising edge of `TIMEOUT`, driving both the onboard LED (`LEDS`, active-low) and an external LED pin (`LED_EXT`, active-high, pin 46).

---

## How Software Controls It

```c
#define TIMER_BASE   0x20001000
#define TIMER_CTRL   (*(volatile unsigned int *)(TIMER_BASE + 0x00))
#define TIMER_LOAD   (*(volatile unsigned int *)(TIMER_BASE + 0x04))
#define TIMER_VALUE  (*(volatile unsigned int *)(TIMER_BASE + 0x08))
#define TIMER_STAT   (*(volatile unsigned int *)(TIMER_BASE + 0x0C))

#define CTRL_EN    (1 << 0)
#define CTRL_MODE  (1 << 1)   // 0 = one-shot, 1 = periodic

// Program LOAD, then enable
TIMER_LOAD = TICK_COUNT;
TIMER_CTRL = CTRL_EN | CTRL_MODE;   // periodic mode

// Poll for timeout, then clear (write-1-to-clear)
while ((TIMER_STAT & 1) == 0) ;
TIMER_STAT = 1;
```

The included test program (`test/timer.c`) demonstrates:
1. Programming `LOAD`
2. Enabling the timer
3. Polling `STATUS.TIMEOUT`
4. Clearing `STATUS.TIMEOUT` (write-1-to-clear)
5. **Both** one-shot mode (single timeout, then stop) **and** periodic mode (multiple auto-reloading timeouts) in sequence
6. UART logging of each phase for observability in simulation

---

## Validation

### Simulation

Full functional simulation was performed with `iverilog`/`vvp`, producing:
- A clean terminal log showing UART output for every phase (one-shot detect/clear, three periodic beats, completion) with a clean `$finish`.
- GTKWave waveform captures confirming, at the signal level:
  1. **Register writes** — CTRL and LOAD values correctly latched on `sel && wr_en`.
  2. **One-shot mode** — `value_reg` counts down to 0, `timeout_flag` sets and stays sticky, `value_reg`/`en` hold state afterward (timer stopped).
  3. **Write-1-to-clear** — `timeout_flag` clears exactly on the cycle `STATUS` is written with bit 0 set.
  4. **Periodic auto-reload** — `value_reg` repeatedly counts down and reloads from `load_reg` with no further software writes.
  5. **LED toggle** — `led_toggle`, `LEDS` (inverted), and `LED_EXT` all transition correctly on the rising edge of `timeout_o`.

(See `/test` for simulation logs and waveform screenshots.)

### Hardware (VSDSquadron FPGA)

The design was synthesized and flashed to a VSDSquadron FPGA Mini board (iCE40UP5K) using the open-source `yosys` / `nextpnr-ice40` / `icepack` / `iceprog` flow.

- Onboard LED (`LEDS`, pin 39) visibly toggles in response to real `TIMEOUT` events generated by the Timer IP running on actual silicon — video evidence included in `/test`.
- **Note on clock source:** the board's external 12 MHz crystal input could not be reliably routed to the design in this environment; the internal iCE40 `SB_LFOSC` (10 kHz) oscillator was used instead as the system clock for hardware validation. All register-level Timer IP behavior (functional correctness, mode switching, sticky status, W1C) is independent of clock source and was fully proven both in simulation (at the intended operating frequency) and on hardware (at the fallback frequency). Firmware timing constants (`TICK_COUNT`) were scaled accordingly for the hardware run.

---

## Directory Structure

```
/timer_ip/
  rtl/
    timer_ip.v          -- Timer IP RTL
  test/
    timer.c              -- C validation program
    simulation_log.txt   -- terminal simulation output
    waveform_*.png        -- GTKWave screenshots (register write, one-shot,
                             W1C, periodic reload, LED toggle)
    hardware_demo.mp4     -- board validation video
  README.md               -- this file
```

---

## Design Decisions

- **Sticky status flag:** `TIMEOUT` is implemented as a level-held flag rather than a single-cycle pulse, matching the spec's poll-then-clear software flow and making it observable even by slow polling loops or a human watching an LED.
- **Load-on-enable:** `VALUE` is loaded from `LOAD` on the `EN` 0→1 edge (not just on periodic reload), preventing a spurious immediate timeout when the timer is first started from a post-reset `VALUE=0` state.
- **Word-aligned, 4-state register decode:** `addr` is a 2-bit word offset (`mem_addr[3:2]`), giving a simple, fully decoded 4-register map with no partial/byte-level complexity, consistent with the "Common Integration Rules" (32-bit, word-aligned registers; undefined offsets read 0 / ignore writes).
- **Prescaler as a separate counter:** implemented as an independent `presc_cnt` comparator against `presc_div`, gating the main countdown's `tick` signal — keeps the main countdown logic simple and unaffected when the prescaler is disabled.
