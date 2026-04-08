# HW11 — Pulse Sensor ASIC: Pmod OLED + XADC + Picoblaze

CE433 Spring 2026 — Course Project

---

## Overview

| Task | What it does | Key IPs / Modules |
|------|-------------|-------------------|
| **T1** | Drives Pmod OLED, displays static text | OledSPI · OledInit · OledEX · charLib |
| **T2** | Reads XADC analog input, displays binary on LEDs | XADC IP · Picoblaze (kcpsm6) |
| **T3** | Full pipeline: pulse sensor → BPM on OLED + UART waveform | All of T1 & T2 + UART TX · OledEX_t3 |

---

## Hardware Setup

### Pmod OLED (Digilent SSD1306, 128×32) — used in T1 & T3

Plug the Pmod OLED into the **JB** connector on the Basys3.

| Pmod OLED pin | Signal | JB header pin | Basys3 FPGA pin |
|---------------|--------|---------------|-----------------|
| 1  | CS  (chip select) | JB1 | A14 |
| 2  | MOSI / SDIN       | JB2 | A16 |
| 3  | NC                | JB3 | B15 |
| 4  | SCLK              | JB4 | B16 |
| 5  | GND               | JB5 | GND |
| 6  | VCC (3.3V)        | JB6 | 3V3 |
| 7  | D/C               | JB7 | A15 |
| 8  | RES               | JB8 | A17 |
| 9  | VBAT              | JB9 | C15 |
| 10 | VDD               | JB10 | C16 |

> **Note**: VDD and VBAT are driven LOW to enable power (active-low FETs on the Pmod board).  Press **btnC** to reset and restart the OLED init sequence.

---

### Analog Input (T2 & T3) — JXADC connector

The analog signal (0–1V amplified pulse sensor output, or any 0–3.3V signal for T2) connects to the **JXADC** differential pair VAUXP6 / VAUXN6.

| Signal | JXADC pin | Basys3 FPGA pin |
|--------|-----------|-----------------|
| Signal+  | JXADC1 (VAUXP6) | J3 |
| GND / Signal− | JXADC2 (VAUXN6) | K3 |
| GND      | JXADC5  | GND |

> **For T2 (testing)**: Connect a potentiometer or function generator (0–3.3V) between JXADC1 and GND.  The 8 MSBs appear on `led[7:0]`.
>
> **For T3**: Connect the Easy Pulse Sensor amplified output (0–1V typical).  The signal is amplified off-chip and then connected to JXADC1. Connect the sensor's GND to JXADC GND.

---

### UART (T3 only) — waveform plot

T3 transmits XADC samples at **115200 baud** over the Basys3 USB-UART bridge.  The TX pin is FPGA pin **A18** (connected to the Basys3's on-board USB-to-serial chip — no external wiring needed).

---

## Building

All build scripts must be run from the **repository root** in a PowerShell terminal.

### Task 1 — Pmod OLED static text

```powershell
.\HW11\T1\build.ps1
```

Uses `run_hardware.py` to create the Vivado project, synthesize, implement, and program the Basys3.  No assembler step needed.

### Task 2 — XADC + Picoblaze → LEDs

```powershell
.\HW11\T2\build.ps1
```

The script:
1. Assembles `prog.psm` → `prog.v` using `kcpsm6.exe`
2. Creates a Vivado project with the **XADC Wizard IP** configured for VAUXP6/VAUXN6
3. Synthesizes, implements, and generates the bitstream

### Task 3 — Full Heart Rate Monitor

```powershell
.\HW11\T3\build.ps1
```

Same steps as T2 plus all OLED and UART modules.

---

## Running the Waveform Plot (T3)

After programming the FPGA:

```bash
# Install dependencies (once)
pip install pyserial matplotlib

# Run the live plot (replace COM3 with your port)
python HW11/T3/plot_waveform.py COM3

# Linux/Mac
python HW11/T3/plot_waveform.py /dev/ttyUSB0
```

The plot shows 500 samples of the analog waveform in real time.  The dashed red line marks the detection threshold (50% of VREF by default).

---

## Architecture

### T1 — OLED controller

```
CLK100MHZ ─┐
            ├─ PmodOLEDCtrl_top ─┬─ OledInit ─── OledSPI ──► JB (CS/SDIN/SCLK/DC)
btnC ───────┘                    │              controls ──► RES / VBAT / VDD
                                 └─ OledEX ──── charLib (font ROM)
                                      │
                                      └─ sends 4 pages × 128 bytes via SPI
```

**OledSPI**: 2 MHz SPI (Mode 0), serializes one byte at a time.  
**OledInit**: SSD1306 power-up + 15-command init sequence (100 ms VBAT ramp).  
**OledEX**: Iterates page 0–3, char 0–15, col 0–7; looks up each column byte in charLib.  
**charLib**: 2048-entry synchronous BRAM; address = `{ASCII_code[7:0], col[2:0]}`.

### T2 — XADC + Picoblaze

```
JXADC ──► XADC IP ──► xadc_latch ──► Picoblaze (port IN 0x00)
                                      │
                                      └─ OUTPUT 0x00 ──► led[7:0]
```

Picoblaze assembly (`prog.psm`): single loop — read XADC, write LEDs.

### T3 — Full system

```
Pulse sensor ──► JXADC ──► XADC IP ──► xadc_hi
                                         │          ┌─ UART TX ──► USB serial ──► PC plot
                                         ├──────────┤
                                     ms_timer        │
                                     peak_detect      └─ Picoblaze ──► BPM digits ──► OledEX_t3
                                                                                          │
                                                                              OledSPI ──► JB OLED
```

**Picoblaze algorithm** (see `prog.psm`):
1. Poll hardware `peak_flag` (set by comparator on XADC rising edge above threshold).
2. On new peak: read ms timer, compute `period = now − prev_time`.
3. `BPM = 6000 / (period_ms / 10)` via iterative subtraction.
4. Convert to ASCII, output tens/units digits to OLED driver.

**OledEX_t3**: Same as OledEX but row 2 columns 8–9 are driven by Picoblaze output registers (BPM tens and units digits) instead of a static character buffer.

---

## Key Constants & Tuning

| Item | Default | Where to change |
|------|---------|-----------------|
| SPI clock | 2 MHz | `OledSPI.v` `HALF = 25` |
| OLED contrast | 0xCF | `OledInit.v` step 38 |
| Detection threshold | 0x80 (128/255 × 3.3V ≈ 1.65V) | `hw11_t3_top.v` initial value of `threshold` |
| UART baud | 115200 | `uart_tx.v` parameter `BAUD` |
| BPM display chars | row 2, cols 8-9 | `OledEX_t3.v` |

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| OLED blank after programming | Init sequence not completing | Press btnC to reset; check JB connector seating |
| OLED shows garbage | Incorrect SPI timing or wrong D/C level | Verify JB pin mapping in XDC matches Pmod orientation |
| LEDs all zero (T2) | No signal on JXADC, or XADC IP config wrong | Verify VAUXP6/VAUXN6 pins; check vivado.log for IP errors |
| BPM reads "- -" (T3) | Signal too slow, or threshold too high | Lower threshold via Picoblaze port 0x03, or check sensor connection |
| `prog.v` not generated | kcpsm6.exe race condition | The build script already handles this with polling; check prog.log |
| Synthesis error: port not found | Wrong XDC package pin | Verify constraints.xdc against Basys3 master XDC |
| UART plot not updating | Wrong COM port or baud | Check Device Manager (Windows) or `ls /dev/tty*` (Linux) |
