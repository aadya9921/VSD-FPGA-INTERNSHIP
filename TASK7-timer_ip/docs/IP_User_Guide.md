# Timer IP — IP User Guide

## What Is This IP?

The Timer IP is a minimal, memory-mapped countdown timer peripheral for the VSDSquadron RISC-V SoC. It counts down from a software-programmed value to zero and signals completion via a status flag, optionally repeating automatically.

### Typical Use Cases

- Generating a periodic "heartbeat" signal (e.g., blinking an LED at a fixed interval)
- Implementing software delays without burning CPU cycles on a manual counting loop
- Timing out an operation (e.g., "wait up to N cycles for a response, then give up")
- Driving any downstream logic that needs a repeating or one-time timed event

### Why / When to Use It

Use this IP whenever your design needs to know "has X amount of time passed?" without dedicating custom counter logic every time. It's a general-purpose building block — instantiate one per independent timing need.

---

## Feature Summary

- **Modes:** One-shot (fires once, then stops — `VALUE` stays at 0, `EN` remains set) and Periodic (auto-reloads from `LOAD` and repeats indefinitely without software intervention)
- **Countdown width:** 32-bit (`LOAD`, `VALUE` registers)
- **Prescaler:** Optional, 8-bit divide value (`CTRL.PRESC_DIV`); effective divisor = `PRESC_DIV + 1`, enabled via `CTRL.PRESC_EN`
- **Status:** Sticky (level-held) `TIMEOUT` flag, cleared by software via write-1-to-clear — safe for polling loops, won't be missed even if software checks late
- **Load-on-enable:** `VALUE` is loaded from `LOAD` the moment `EN` transitions 0→1, avoiding a false immediate timeout from a post-reset `VALUE=0` state
- **Bus interface:** Simple synchronous memory-mapped interface (`sel` / `wr_en` / `rd_en` / `addr` / `wdata` / `rdata`), 32-bit word-aligned registers, 2-bit word-offset addressing
- **Reset:** Active-low, asynchronous (`resetn`); all internal registers clear to 0 on reset

### Clock Assumption

The IP itself is clock-agnostic — it operates correctly on whatever `clk` is supplied, with no internal clock generation or PLL requirement of its own. Timing constants (the value written to `LOAD`) must be chosen relative to whatever system clock frequency the host SoC actually runs at.

In the reference integration, the SoC targets the VSDSquadron board's onboard 12 MHz oscillator. During hardware bring-up, the external clock input could not be reliably routed to the design in this environment, so the internal iCE40 **`SB_LFOSC`** (~10 kHz) oscillator was used as a fallback system clock for hardware validation:

```verilog
wire clk_lf;
SB_LFOSC lfosc (
    .CLKLFPU(1'b1),
    .CLKLFEN(1'b1),
    .CLKLF(clk_lf)
);
assign clk = clk_lf;
```

All register-level Timer IP behavior (correctness, mode switching, sticky status, write-1-to-clear) is independent of clock source and was fully verified both in simulation and on hardware using the 10 kHz `SB_LFOSC` fallback clock, with `TICK_COUNT = 15000` (~1.5 seconds per beat). If you integrate this IP into a design with a different clock, simply recalculate your `LOAD` value for your actual frequency — no RTL changes are needed.

### Limitations

- **No interrupt output.** This IP only exposes a level status flag (`timeout_o` / `STATUS.TIMEOUT`) — there is no dedicated interrupt request line. If your SoC needs an interrupt on timeout, generate it externally from `timeout_o`.
- **Single instance per timing need.** Each instantiation provides exactly one independent countdown; there is no built-in multi-channel/multi-timer support.
- **No read-back of prescaler counter.** The internal `presc_cnt` is not exposed via any register — only the configured `PRESC_DIV` value (via `CTRL`) is readable.
- **Assumes a stable, free-running clock.** No clock-gating or dynamic frequency scaling is accounted for internally.
- **Hardware-validated at a fallback clock speed.** See "Clock Assumption" above — functional correctness was proven at both the intended and fallback frequencies, but only the fallback (10 kHz `SB_LFOSC`) was used for the physical board demo.

---

## Block Diagram

```
                    ┌─────────────────────┐
                    │      CPU Bus        │
                    │  (sel, wr_en, addr, │
                    │   wdata, rdata)     │
                    └──────────┬──────────┘
                               │
                               v
                    ┌─────────────────────┐
                    │  Register Decode    │
                    │  (addr → CTRL/LOAD/ │
                    │   VALUE/STATUS)     │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              v                v                v
      ┌───────────────┐ ┌──────────────┐ ┌──────────────┐
      │  CTRL / LOAD   │ │  Prescaler   │ │   STATUS     │
      │  (en, mode,    │ │  (presc_cnt  │ │ (write-1-to- │
      │  presc_en,     │ │   vs         │ │  clear logic)│
      │  presc_div)    │ │  presc_div)  │ │              │
      └───────┬────────┘ └──────┬───────┘ └──────┬───────┘
              │                 │                │
              └────────┬────────┘                │
                       v                         │
              ┌──────────────────────┐            │
              │   Counter / FSM      │            │
              │   (value_reg         │            │
              │    countdown,        │            │
              │    load-on-enable,   │            │
              │    one-shot/periodic │            │
              │    reload logic)     │            │
              └──────────┬───────────┘            │
                         │                         │
                         v                         │
              ┌──────────────────────┐             │
              │  timeout_flag        │<────────────┘
              │  (sticky, set on     │
              │   VALUE == 0)        │
              └──────────┬───────────┘
                         │
                         v
              ┌──────────────────────┐
              │   timeout_o          │
              │   (output to top-    │
              │    level SoC / LED)  │
              └──────────────────────┘
```

See `docs/Register_Map.md` for full register definitions and `docs/Integration_Guide.md` for exact wiring into your SoC.
