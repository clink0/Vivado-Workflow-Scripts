# HW10 — PicoBlaze Interrupts and Edge Detection

## Overview

HW10 uses a PicoBlaze (KCPSM6) soft-core processor to respond to external events via interrupts rather than polling. Each task builds on the previous one.

| Task | Trigger | What it does |
|------|---------|--------------|
| **T1** | Push button (btnC) | ISR toggles LED[0] on each press |
| **T2** | Push button (btnC) | ISR toggles LED[0] **and** counts presses 0–F on the 7-segment display |
| **T3** | Function generator on JA[0] | ISR counts rising edges 0–F on the 7-segment display |

---

## How to Build

The build script assembles the PicoBlaze program (`prog.psm → prog.v`) then runs Vivado synthesis, implementation, and bitstream generation automatically.

From the **repo root** in PowerShell:

```powershell
.\HW10\T1\build.ps1   # Task 1
.\HW10\T2\build.ps1   # Task 2
.\HW10\T3\build.ps1   # Task 3
```

Each build takes ~5–10 minutes. The bitstream is written to:
```
HW10\T1\vivado_project\T1.runs\impl_1\interrupt_top.bit
HW10\T2\vivado_project\T2.runs\impl_1\interrupt_top.bit
HW10\T3\vivado_project\T3.runs\impl_1\interrupt_top.bit
```

### Program the Board

1. Open **Vivado Hardware Manager → Auto Connect**
2. Click **Program Device**
3. Select the `.bit` file from the path above

---

## Task 1 — Button Press Toggles LED[0]

### Hardware Connections

No external wiring needed beyond the Basys 3 itself.

| Control | Location |
|---------|----------|
| Interrupt button | **btnC** (center button on Basys 3) |
| LED output | **LED[0]** (rightmost LED) |

### How It Works

1. Press **btnC** → the Verilog debouncer filters bounces (~10ms window)
2. A rising edge is detected on the debounced signal → `interrupt_reg` goes high
3. PicoBlaze jumps to the ISR at address `0x3FF`
4. ISR: fetches LED state from scratchpad → XORs bit 0 → writes back → outputs to port `0x00`
5. PicoBlaze asserts `interrupt_ack` → Verilog clears `interrupt_reg`

### Expected Behavior

- LED[0] toggles on every button press
- LED[1..15] remain off

---

## Task 2 — Button Press Counter on 7-Segment Display

### Hardware Connections

No external wiring needed.

| Control | Location |
|---------|----------|
| Interrupt button | **btnC** (center button) |
| LED output | **LED[0]** (toggles each press) |
| Count display | **Rightmost 7-segment digit** |

### How It Works

Same interrupt path as T1. The ISR does two things:
1. Toggles LED[0] (port `0x00`) using scratchpad state
2. Increments a 4-bit counter in scratchpad → masks to 0–F with `AND s1, 0F` → outputs to port `0x01`

The Verilog 7-segment decoder converts the 4-bit value to active-low segment patterns.

### Expected Behavior

- LED[0] toggles on every press
- Rightmost 7-segment digit counts: `0 → 1 → 2 → ... → F → 0 → ...`
- Other three digits remain blank (anode `an = 4'b1110`)

---

## Task 3 — Function Generator Rising Edge Counter

### Hardware Connections

Connect a **0.5 Hz, 0–3.3V square wave** from the function generator to the Basys 3 JA header.

> **Do not exceed 3.3V on JA pins.** The Basys 3 I/O is 3.3V — a 5V signal will damage the FPGA.

| Function Generator | Basys 3 JA Pin | Signal |
|--------------------|----------------|--------|
| Signal output (0–3.3V) | **JA1 (J1)** | JA[0] — pulse input |
| GND | **JA GND (pin 5)** | Common ground |

The JA header pinout (looking at the board, top row left to right):

```
JA1  JA2  JA3  JA4
JA7  JA8  JA9  JA10
GND  GND  VCC  VCC      <- bottom row
```

Connect the function generator signal to **JA1** (top-left pin) and GND to **GND** (bottom-left).

### Function Generator Settings

| Parameter | Value |
|-----------|-------|
| Waveform | Square wave |
| Frequency | 0.5 Hz |
| Amplitude | 0–3.3V (or 3.3Vpp with 0V offset) |
| DC offset | 1.65V (so signal swings 0V to 3.3V) |

### How It Works

Instead of a debouncer, T3 uses a **3-stage synchronizer** — a shift register that clocks the external signal through three flip-flops before the edge detector sees it. This prevents metastability from the asynchronous external input.

```
JA[0] → ja_sync[0] → ja_sync[1] → ja_sync[2]
                          ↑              ↑
                     Rising edge detected here:
                     ja_sync[1]=1 AND ja_sync[2]=0
```

The synchronizer adds 2 clock cycles of latency (~20ns at 100MHz), which is negligible for a 0.5Hz signal.

### Expected Behavior

- LED[0] toggles on every rising edge of the function generator signal
- Rightmost 7-segment digit increments twice per second (once per rising edge at 0.5Hz)
- Counter wraps: `0 → 1 → ... → F → 0 → ...`

---

## File Reference

### T1
| File | Purpose |
|------|---------|
| `T1/interrupt_top.v` | Top module: debouncer, edge detect, interrupt handshake, kcpsm6, ROM |
| `T1/prog.psm` | PicoBlaze assembly: ISR toggles LED[0] |
| `T1/constraints.xdc` | Pin constraints: CLK, btnC, led[15:0] |
| `T1/build.ps1` | Build script: assemble + Vivado |

### T2
| File | Purpose |
|------|---------|
| `T2/interrupt_top.v` | Same as T1 + seg_out_reg, 7-segment decoder, seg/an/dp ports |
| `T2/prog.psm` | ISR toggles LED[0] and increments counter to seg port |
| `T2/constraints.xdc` | Adds seg[6:0], dp, an[3:0] to T1 constraints |
| `T2/build.ps1` | Build script |

### T3
| File | Purpose |
|------|---------|
| `T3/interrupt_top.v` | Replaces debouncer with 3-stage synchronizer on JA[0] |
| `T3/prog.psm` | Same ISR as T2 (LED toggle + counter) |
| `T3/constraints.xdc` | Replaces btnC with JA[0..7] |
| `T3/build.ps1` | Build script |

---

## Architecture

```
                    T1 / T2                         T3
                    ───────                         ──
btnC ──→ Debouncer ──→ Edge Detect ──┐     JA[0] ──→ 3-Stage Sync ──→ Edge Detect ──┐
                                     │                                                │
                              interrupt_reg                                    interrupt_reg
                                     │                                                │
                             ┌───────▼───────┐                             ┌──────────▼──────────┐
                             │   PicoBlaze   │                             │      PicoBlaze       │
                             │   (KCPSM6)    │◄── prog.v (ROM) ──────────►│      (KCPSM6)        │
                             └──┬────────────┘                             └──┬───────────────────┘
                                │ port 0x00                                   │ port 0x00
                                ▼                                             ▼
                           led_out_reg ──→ led[7:0]                     led_out_reg ──→ led[7:0]
                                │ port 0x01 (T2 only)                        │ port 0x01
                                ▼                                             ▼
                           seg_out_reg ──→ 7-seg decoder ──→ seg/an     seg_out_reg ──→ 7-seg decoder ──→ seg/an
```

---

## Key Concepts

### Interrupt Handshake
The 3-step handshake prevents double-triggering:
1. **Set**: rising edge on button/JA[0] sets `interrupt_reg = 1`
2. **Ack**: PicoBlaze detects the interrupt, pulses `interrupt_ack` for one clock cycle
3. **Clear**: Verilog clears `interrupt_reg = 0` on `interrupt_ack`

Without step 3, PicoBlaze would re-enter the ISR immediately after returning.

### Debouncer vs. Synchronizer
| | Debouncer (T1/T2) | Synchronizer (T3) |
|--|---|---|
| Purpose | Remove mechanical bounce (~1–10ms) | Prevent metastability from async input |
| Method | Count stable time before accepting change | 3 flip-flop pipeline |
| Latency | ~10ms | ~20ns (2 clock cycles) |
| Use when | Mechanical button | Clean digital signal |

### 7-Segment Encoding (active-low)
Segments are ordered **A B C D E F G** (seg[6:0]). A `0` bit turns a segment **on**.

```
 _
|_|   =  0x00  (digit '8', all segments on)
|_|
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| LED[0] doesn't toggle on button press | Bounce exceeds 10ms window | Hold button briefly; don't tap quickly |
| Counter skips values | Button bouncing triggers multiple ISRs | Normal — debouncer handles most; very fast taps may still skip |
| 7-segment shows nothing | `an` not driven correctly | Confirm `an = 4'b1110` (active-low, rightmost digit) |
| T3 counter doesn't increment | JA[0] signal too low or wrong pin | Check JA1 (J1) connection and verify signal is 0–3.3V |
| T3 counts twice per expected edge | Function generator duty cycle not 50% | Adjust to 50% duty cycle so each period has exactly one rising edge |
| Build fails: `prog.v not generated` | `kcpsm6.exe` not found or ROM_form.v missing | Confirm `Lab8/kcpsm6_files/` contains `kcpsm6.exe` and `ROM_form.v` |
