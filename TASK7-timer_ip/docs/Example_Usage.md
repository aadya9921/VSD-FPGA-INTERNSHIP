# Timer IP — Example Usage

## Software Programming Model

Typical sequence to use this IP from software:

1. Write `LOAD` — set the countdown starting value
2. Write `CTRL` — set `EN` (and `MODE`, `PRESC_EN`/`PRESC_DIV` if needed) to start counting
3. Poll `STATUS` — check bit 0 until it reads 1
4. Write `STATUS = 1` — clear the timeout flag (write-1-to-clear)
5. (Periodic mode only) Repeat step 3–4 for each subsequent auto-reloaded timeout — no need to rewrite `LOAD`/`CTRL` again

## Full Example (C)

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

#define TICK_COUNT     15000      // ~1.5s per beat @ 10kHz SB_LFOSC

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

    // ---- PERIODIC MODE (100 beats) ----
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

**Note on timing constant:** `TICK_COUNT = 15000` targets the 10 kHz `SB_LFOSC` fallback clock used for hardware validation (~1.5 seconds per beat). If integrating into a design running from a different clock, recalculate: `TICK_COUNT ≈ desired_seconds × clock_frequency_Hz`.

**Note on periodic loop count:** the periodic phase runs for a bounded **100 beats** rather than an unbounded `while(1)`. This is a deliberate choice — it produces ~2.5 minutes of continuous, repeating LED toggling on hardware (long enough to clearly demonstrate periodic auto-reload behavior), while still allowing the program — and simulation — to terminate cleanly and print a completion message. An unbounded `while(1)` would never reach `"=== Validation Complete ==="` in either environment.

---

## Expected UART Output

```
=== Timer IP Validation ===
[ONE-SHOT] Loading TIMER_LOAD, enabling EN=1 MODE=0
[ONE-SHOT] TIMEOUT detected and cleared. Timer stopped.
[PERIODIC] Loading TIMER_LOAD, enabling EN=1 MODE=1
[PERIODIC] TIMEOUT detected, STATUS cleared.
[PERIODIC] TIMEOUT detected, STATUS cleared.
[PERIODIC] TIMEOUT detected, STATUS cleared.
... (repeats 100 times total) ...
[PERIODIC] TIMEOUT detected, STATUS cleared.
=== Validation Complete ===
```

The `[PERIODIC] TIMEOUT detected, STATUS cleared.` line repeats once per beat — 100 times total — before the final `"=== Validation Complete ==="` line and program exit.

---

## Expected Board Behavior

*See `docs/hardware_demo/` for video evidence of this behavior on real hardware.*

In the reference integration, `timeout_o` is wired to toggle an onboard LED on every timeout event. With the example program above, at the 10 kHz `SB_LFOSC` fallback clock:

- The LED toggles **once** for the one-shot phase.
- The LED then toggles **once every ~1.5 seconds**, repeating for **100 beats** (~2.5 minutes total) during the periodic phase.
- After the program completes, the LED holds its final state (101 total toggles — an odd number — so it ends in the opposite state from where it started).

This LED-toggle behavior is implemented in the reference SoC's top-level module, reacting to `timeout_o`'s rising edge — it is not part of this IP itself, and is shown here only as a demonstration pattern for how a consumer might use `timeout_o`. If your integration uses a different clock frequency, recalculate the expected toggle interval as `TICK_COUNT ÷ clock_frequency_Hz`.

---

## Common Failure Symptoms

| Symptom | Likely Cause |
|---|---|
| No UART output at all | CPU not executing — check reset polarity/clock source reaches the design |
| `STATUS` never shows TIMEOUT set | `LOAD`/`CTRL` not written correctly, or `EN` never actually set |
| LED (or other consumer) stuck on/off, never toggles | Downstream toggle logic not correctly wired to `timeout_o` |
| Same `VALUE` read repeatedly with no decrement | `EN` not set, or clock not reaching the IP |
| Timeout fires immediately after enabling | `LOAD` not written before `EN` was set, or `LOAD=0` |
| LED toggles far faster or slower than expected | `TICK_COUNT` not recalculated for your actual clock frequency |
