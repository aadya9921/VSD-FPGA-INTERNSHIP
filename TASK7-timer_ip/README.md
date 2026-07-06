# Timer IP

A minimal, memory-mapped countdown timer for the VSDSquadron RISC-V SoC. Programs a countdown value, counts down, and raises a status flag on expiry — supporting both one-shot and periodic (auto-reload) operation.

## What it does

- Programmable 32-bit countdown (`LOAD` → `VALUE` → 0)
- One-shot mode (fires once, stops) and periodic mode (auto-reloads and repeats)
- Optional prescaler for slower tick rates
- Sticky, write-1-to-clear status flag — safe for polling loops
- On the VSDSquadron board, drives an onboard LED heartbeat on every timeout

## Clock Source Used

This reference integration runs on the iCE40 internal **`SB_LFOSC`** oscillator (~10 kHz), used as a fallback since the board's external 12 MHz crystal input could not be reliably routed to the design in this environment:

```verilog
wire clk_lf;
SB_LFOSC lfosc (
    .CLKLFPU(1'b1),
    .CLKLFEN(1'b1),
    .CLKLF(clk_lf)
);
assign clk = clk_lf;
```

The Timer IP itself is clock-agnostic — this only affects the `LOAD` timing constant used in the example firmware (scaled for 10 kHz). If you integrate this into a design running from a different clock, just recalculate `LOAD` for your actual frequency. See `docs/IP_User_Guide.md` for full details.

## Known Limitations

- No interrupt output — only a polled status flag (`STATUS.TIMEOUT` / `timeout_o`)
- Single countdown channel per instance — no multi-timer support built in
- Prescaler counter itself is not readable — only the configured `PRESC_DIV` value is
- Hardware validation was performed at a 10 kHz fallback clock (`SB_LFOSC`), not the board's intended 12 MHz — see "Clock Source Used" above

## Quick integration

1. Copy `rtl/timer_ip.v` into your project.
2. Instantiate it on your bus at a 4KB-aligned base address (see `docs/Integration_Guide.md`).
3. Wire `timeout_o` to whatever you want to react to a timeout (LED, interrupt, flag).

Full wiring instructions, signal list, and address decode example: **[`docs/Integration_Guide.md`](docs/Integration_Guide.md)**

## Register map

4 registers, 32-bit, word-aligned: `CTRL`, `LOAD`, `VALUE`, `STATUS`.

Full bit-level definitions: **[`docs/Register_Map.md`](docs/Register_Map.md)**

## Try it

Ready-to-run example firmware is in `software/timer.c` — programs the timer, polls for timeout, clears it, and demonstrates both modes.

```c
TIMER_LOAD = 15000;                // scaled for 10kHz SB_LFOSC (~1.5s per beat)
TIMER_CTRL = CTRL_EN | CTRL_MODE;  // enable, periodic mode
while ((TIMER_STAT & 1) == 0) ;    // wait for timeout
TIMER_STAT = 1;                    // clear (write-1-to-clear)
```

Full example, expected UART output, and expected LED behavior: **[`docs/Example_Usage.md`](docs/Example_Usage.md)**

## Validation Evidence

- **Simulation waveforms** (GTKWave screenshots covering register writes, one-shot mode, write-1-to-clear, periodic auto-reload, and LED toggle): **[`docs/waveforms/`](docs/waveforms/)**
- **Hardware demo video** (continuous LED blinking on real VSDSquadron FPGA): **[`docs/hardware_demo/`](docs/hardware_demo/)**

## Docs index

| Document | Contents |
|---|---|
| [`docs/IP_User_Guide.md`](docs/IP_User_Guide.md) | What this IP is, use cases, features, limitations |
| [`docs/Register_Map.md`](docs/Register_Map.md) | Full register/bit definitions, reset values |
| [`docs/Integration_Guide.md`](docs/Integration_Guide.md) | How to wire this into your own SoC |
| [`docs/Example_Usage.md`](docs/Example_Usage.md) | Software walkthrough, expected output, board demo |

## Folder structure

```
timer_ip/
├── rtl/
│   └── timer_ip.v
├── software/
│   └── timer.c
├── docs/
│   ├── IP_User_Guide.md
│   ├── Register_Map.md
│   ├── Integration_Guide.md
│   ├── Example_Usage.md
│   ├── waveforms/
│   │   ├── waveform_register_write.png
│   │   ├── waveform_one_shot.png
│   │   ├── waveform_w1c.png
│   │   ├── waveform_periodic.png
│   │   └── waveform_led_toggle.png
│   └── hardware_demo/
│       └── hardware_demo.mp4
└── README.md
```
