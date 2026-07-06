# TASK 6

## Objective

### Timer IP — Core Contributor Task

## Overview

This is a minimal, memory-mapped **Timer peripheral IP** designed and integrated into an existing RISC-V SoC (based on the `femtorv32`-style single-cycle-bus processor). The Timer provides a programmable countdown that generates a `TIMEOUT` event and status flag, supporting both **one-shot** and **periodic (auto-reload)** modes, with an optional prescaler.

- **Owner:** Timer IP 
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
// timer_test.c — Validates Timer IP with UART logging
#define TIMER_BASE   0x20001000
#define TIMER_CTRL   (*(volatile unsigned int *)(TIMER_BASE + 0x00))
#define TIMER_LOAD   (*(volatile unsigned int *)(TIMER_BASE + 0x04))
#define TIMER_VALUE  (*(volatile unsigned int *)(TIMER_BASE + 0x08))
#define TIMER_STAT   (*(volatile unsigned int *)(TIMER_BASE + 0x0C))

#define UART_BASE    0x40000000
#define UART_DAT     (*(volatile unsigned int *)(UART_BASE + 0x08))

// CTRL bit layout
#define CTRL_EN        (1 << 0)
#define CTRL_MODE      (1 << 1)   // 0 = one-shot, 1 = periodic

#define TICK_COUNT     15000         // small value for fast simulation

static void uart_putc(char c)
{
    UART_DAT = (unsigned int) c;
}

static void uart_puts(const char *s)
{
    while (*s) {
        uart_putc(*s);
        s++;
    }
}

// Poll STATUS.TIMEOUT until set, then clear it (write-1-to-clear)
static void wait_and_clear(void)
{
    while ((TIMER_STAT & 1) == 0)
        ;
    TIMER_STAT = 1;
}

int main(void)
{
    uart_puts("=== Timer IP Validation ===\n");

    // ---- ONE-SHOT MODE ----
    uart_puts("[ONE-SHOT] Loading TIMER_LOAD, enabling EN=1 MODE=0\n");
    TIMER_LOAD = TICK_COUNT;
    TIMER_CTRL = CTRL_EN;             // EN=1, MODE=0 (one-shot)
    wait_and_clear();
    uart_puts("[ONE-SHOT] TIMEOUT detected and cleared. Timer stopped.\n");
    TIMER_CTRL = 0;

// ---- PERIODIC MODE (continuous) ----
    uart_puts("[PERIODIC] Loading TIMER_LOAD, enabling EN=1 MODE=1\n");
    TIMER_LOAD = TICK_COUNT;
    TIMER_CTRL = CTRL_EN | CTRL_MODE; // EN=1, MODE=1 (periodic)

    for (int beat = 0; beat < 100; beat++) {
        wait_and_clear();
        uart_puts("[PERIODIC] TIMEOUT detected, STATUS cleared.\n");
    }

    TIMER_CTRL = 0;
    uart_puts("=== Validation Complete ===\n");

    return 0;
}
```

The included test program (`test/timer.c`) demonstrates:
1. Programming `LOAD`
2. Enabling the timer
3. Polling `STATUS.TIMEOUT`
4. Clearing `STATUS.TIMEOUT` (write-1-to-clear)
5. **Both** one-shot mode (single timeout, then stop) **and** periodic mode (multiple auto-reloading timeouts) in sequence
6. UART logging of each phase for observability in simulation

**Note on periodic loop count:** the periodic phase runs for **100 beats** (`for (int beat = 0; beat < 100; beat++)`), each beat taking ~1.5 seconds (`TICK_COUNT = 15000` at the 10 kHz `SB_LFOSC` clock used for hardware validation — see clock source note below). This gives ~2.5 minutes of visible, repeating LED toggling — clearly demonstrating continuous periodic operation — while still terminating and printing `"=== Validation Complete ==="` in simulation, unlike an unbounded `while(1)` loop which would never complete.


---

## Validation

### I. Simulation

1. **Firmware Build**

   The Timer IP firmware was successfully compiled using the RISC-V GNU toolchain. The `timer.c` application and supporting runtime files were compiled, assembled, linked, and converted into the memory initialization file (`firmware.hex`) used by the RISC-V processor.

   <img width="950" height="206" alt="Screenshot 2026-07-06 150951" src="https://github.com/user-attachments/assets/970305b6-29da-4a81-ab97-f94f7e87ae80" />


2. **RTL Compilation and Simulation**

   The complete RISC-V SoC, including the integrated Timer IP, was compiled using **Icarus Verilog (iverilog)** and functionally simulated using **vvp**.

   ```bash
   iverilog -DBENCH -o sim2.vvp riscv_new.v ice40_stubs.v
   vvp sim2.vvp
    ```

   <img width="950" height="409" alt="Screenshot 2026-07-06 150509" src="https://github.com/user-attachments/assets/1f1ce557-7455-4dd0-808a-c2dd2aed1eea" />


   <img width="950" height="350" alt="Screenshot 2026-07-06 150631" src="https://github.com/user-attachments/assets/2dbee655-6b7c-43ac-b607-8dd76b90eedb" />



3. **Waveform Analysis (GTKWave)**

   A VCD waveform file (`sim.vcd`) was generated during simulation and analyzed using **GTKWave** to verify the functionality of the Timer IP.

- **Register Writes:** The `CTRL` and `LOAD` registers were successfully written when `sel && wr_en` were asserted.

   <img width="950" height="448" alt="Screenshot 2026-07-02 155234" src="https://github.com/user-attachments/assets/f7b7fced-3c10-4b7e-b1de-5af94a368663" />

- **One-Shot Mode:** The `value_reg` counted down to zero, `timeout_flag` was asserted and remained set, while `value_reg` and `EN` held their values after timeout.

   <img width="950" height="448" alt="Screenshot 2026-07-02 155525" src="https://github.com/user-attachments/assets/77e5b140-77a6-4b9c-9368-c2009013523a" />

- **Write-1-to-Clear:** Writing a logic '1' to the `STATUS` register successfully cleared the sticky `timeout_flag`.

   <img width="950" height="448" alt="Screenshot 2026-07-02 160931" src="https://github.com/user-attachments/assets/56859bd5-2205-47ee-b8df-0b3ad6c1d278" />

- **Periodic Auto-Reload:** In periodic mode, `value_reg` automatically reloaded from `load_reg` after each timeout and continued counting without additional software writes.

   <img width="950" height="448" alt="Screenshot 2026-07-02 161708" src="https://github.com/user-attachments/assets/d0fe87c3-ad64-49c0-8cf3-946b023e3e7b" />

- **LED Toggle:** The `led_toggle`, `LEDS` (active-low), and `LED_EXT` (active-high) signals toggled correctly on every rising edge of `timeout_o`, confirming proper hardware indication of timeout events.

   <img width="950" height="447" alt="Screenshot 2026-07-02 162142" src="https://github.com/user-attachments/assets/0a897990-9ebf-4d4c-b703-e8c6eb5f7086" />

### II. Hardware (VSDSquadron FPGA)

The design was synthesized and flashed to a VSDSquadron FPGA Mini board (iCE40UP5K) using the open-source `yosys` / `nextpnr-ice40` / `icepack` / `iceprog` flow.

```bash
make clean
make
sudo make flash
```

Internally, `make` runs the following synthesis and place-and-route pipeline:

```bash
yosys -q -p "read_verilog -DSYNTHESIS -DNEGATIVE_RESET riscv_new.v; synth_ice40 -abc9 -device u -dsp -top SOC -json SOC.json"
nextpnr-ice40 --force --json SOC.json --pcf VSDSquadronFM.pcf --asc SOC.asc --freq 1 --up5k --package sg48 --opt-timing
icetime -p VSDSquadronFM.pcf -P sg48 -r SOC.timings -d up5k -t SOC.asc
icepack -s SOC.asc SOC.bin
```

and `sudo make flash` runs:

```bash
iceprog SOC.bin
```

- Onboard LED (`LEDS`, pin 39) visibly toggles in response to real `TIMEOUT` events generated by the Timer IP running on actual silicon — video evidence included in `/test`.

- **Note on clock source:** the board's external 12 MHz crystal input could not be reliably routed to the design in this environment; the internal iCE40 `SB_LFOSC` (10 kHz) oscillator was used instead as the system clock for hardware validation:


```verilog
  wire clk_lf;
  SB_LFOSC lfosc (
      .CLKLFPU(1'b1),
      .CLKLFEN(1'b1),
      .CLKLF(clk_lf)
  );
  assign clk = clk_lf;
```

  All register-level Timer IP behavior (functional correctness, mode switching, sticky status, W1C) is independent of clock source and was fully proven both in simulation (at the intended operating frequency) and on hardware (at the fallback frequency). Firmware timing constants (`TICK_COUNT`) were scaled accordingly for the hardware run.

**Build & flash log:**

<img width="950" height="209" alt="Screenshot 2026-07-06 150349" src="https://github.com/user-attachments/assets/6837a879-4c73-4932-9a85-622026d32077" />


  

   
 https://github.com/user-attachments/assets/77466d54-9378-4aaa-8dea-82db7ee7275b


- **LED toggles at a ~1.5 second interval**, repeating for 100 beats (~2.5 minutes total) before the program completes and the LED holds its final state.
  

---

## Directory Structure

```text
task6/
├── rtl/
│   └── riscv.v
│   └── timer_ip.v
├── test/
│   ├── hardware_demo.mp4
│   ├── timer.c
│   ├── waveform_led_toggle.png
│   ├── waveform_one_shot.png
│   ├── waveform_periodic.png
│   ├── waveform_register_write.png
│   └── waveform_w1c.png
└── README.md
```

---

## Design Decisions

- **Sticky status flag:** `TIMEOUT` is implemented as a level-held flag rather than a single-cycle pulse, matching the spec's poll-then-clear software flow and making it observable even by slow polling loops or a human watching an LED.
- **Load-on-enable:** `VALUE` is loaded from `LOAD` on the `EN` 0→1 edge (not just on periodic reload), preventing a spurious immediate timeout when the timer is first started from a post-reset `VALUE=0` state.
- **Word-aligned, 4-state register decode:** `addr` is a 2-bit word offset (`mem_addr[3:2]`), giving a simple, fully decoded 4-register map with no partial/byte-level complexity, consistent with the "Common Integration Rules" (32-bit, word-aligned registers; undefined offsets read 0 / ignore writes).
- **Prescaler as a separate counter:** implemented as an independent `presc_cnt` comparator against `presc_div`, gating the main countdown's `tick` signal — keeps the main countdown logic simple and unaffected when the prescaler is disabled.
