# Timer IP — Register Map

Base address: assigned by the integrator (4KB-aligned recommended). Example used in reference integration: `TIMER_BASE = 0x2000_1000`.

All registers are 32-bit, word-aligned. Accesses to undefined offsets return 0 on read and are ignored on write.

| Offset | Name   | R/W | Reset Value | Description             |
|--------|--------|-----|--------------|--------------------------|
| 0x00   | CTRL   | R/W | 0x00000000   | Control bits             |
| 0x04   | LOAD   | R/W | 0x00000000   | Countdown start value    |
| 0x08   | VALUE  | R   | 0x00000000   | Current countdown value  |
| 0x0C   | STATUS | R/W | 0x00000000   | Timeout status / clear   |

---

## CTRL (0x00)

| Bits   | Field      | R/W | Description                                                |
|--------|------------|-----|--------------------------------------------------------------|
| 0      | EN         | R/W | 1 = enable counting, 0 = stop                                |
| 1      | MODE       | R/W | 0 = one-shot, 1 = periodic / auto-reload                     |
| 2      | PRESC_EN   | R/W | 0 = no prescale, 1 = prescale enabled                        |
| 15:8   | PRESC_DIV  | R/W | Prescaler divide value; effective divisor = (PRESC_DIV + 1)  |
| 31:16, 7:3 | —      | R   | Reserved, read as 0                                          |

**Reset value:** `0x00000000` (disabled, one-shot, no prescale)

**Behavior notes:**
- Writing `EN=1` while it was previously 0 causes `VALUE` to load from `LOAD` on the next clock edge (see `VALUE` below).
- `PRESC_DIV` and `PRESC_EN` take effect immediately on write; changing them mid-count is allowed but will affect the tick rate starting from the next tick evaluation.

---

## LOAD (0x04)

32-bit value the countdown loads from:
- On `EN` rising edge (0→1), and
- On every periodic auto-reload (when `MODE=1` and a timeout occurs)

**Reset value:** `0x00000000`

**Note:** Writing `LOAD` while the timer is already running does not immediately affect the current countdown — it only takes effect on the next load event (enable edge or periodic reload).

---

## VALUE (0x08)

Current countdown value. **Read-only** — writes to this offset are ignored.

**Reset value:** `0x00000000`

**Behavior:**
- Loads from `LOAD` when `EN` transitions 0→1.
- Decrements by 1 each tick while `EN=1` (a "tick" occurs every clock cycle if the prescaler is disabled, or every `PRESC_DIV + 1` cycles if enabled).
- Reaching 0 triggers `STATUS.TIMEOUT` to be set. In periodic mode, `VALUE` then reloads from `LOAD` automatically; in one-shot mode, `VALUE` remains at 0.

---

## STATUS (0x0C)

| Bit | Field   | R/W | Description                                                     |
|-----|---------|-----|--------------------------------------------------------------------|
| 0   | TIMEOUT | R/W | Set to 1 by hardware when countdown reaches 0. **Write 1 to clear.** Writing 0 has no effect. |
| 31:1 | —      | R   | Reserved, read as 0                                                 |

**Reset value:** `0x00000000`

**Behavior notes:**
- `TIMEOUT` is a **sticky** (level-held) flag — it remains set until explicitly cleared by software, even if multiple clock cycles pass between the hardware event and the software check. This makes it safe to poll infrequently without missing an event.
- Clearing is write-1-to-clear: writing `0x00000001` to `STATUS` clears bit 0; writing `0x00000000` does nothing.
- If a new timeout occurs on the exact same clock cycle as a clear write, the clear takes priority (flag ends the cycle cleared).
