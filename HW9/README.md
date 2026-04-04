# HW9 — XADC + SPI to Arduino

## Overview

HW9 integrates the XADC block with an SPI leader transmitter to stream analog data from the Basys 3 to an Arduino.

| Task | What it does |
|------|-------------|
| **T1** | XADC runs but SPI outputs constant `8'b00001111` — verify SPI waveform on oscilloscope |
| **T2** | XADC reads Easy Pulse Sensor (0–1V), sends real ADC data to Arduino Serial Plotter |

The only difference between T1 and T2 is one line in `XADCdemo.v`:
- **T1:** `data_latch <= 8'b00001111;` (constant)
- **T2:** `data_latch <= data[15:8];` (real ADC data)

---

## Hardware Setup

### Analog input (both tasks)

The Easy Pulse Sensor output (0–1V) connects to the JXADC header on the bottom-left of the Basys 3.

| JXADC Pin | Signal | Connect to |
|-----------|--------|-----------|
| 1 (J3) | vauxp6 | Easy Pulse Sensor AO (or pot wiper) |
| 5 (K3) | vauxn6 | GND |
| All others | — | GND (prevents noise) |

> The XADC input range is **0–1V max**. Do not exceed 1V on vauxp6.

### SPI to Arduino (T2 only)

The FPGA is the leader transmitter. It outputs 3.3V logic to the Arduino's 5V pins — no level shifter needed since 3.3V is above the Arduino's logic HIGH threshold.

| Basys 3 JB pin | Signal | Arduino pin |
|----------------|--------|-------------|
| JB1 (A14) | SCK | Pin 2 |
| JB2 (A16) | SS (active low) | Pin 12 |
| JB3 (B15) | MOSI | Pin 13 |
| GND | GND | GND |

> Connect GND between the Basys 3 and Arduino. Do **not** connect Arduino 5V to the Basys 3.

---

## Task 1 — Constant SPI Output (Oscilloscope)

### Step 1: Build

From the **repo root** in PowerShell:

```powershell
.\HW9\T1\build.ps1
```

This creates the XADC IP via `create_ip`, synthesizes, implements, and writes the bitstream (~10–15 min).

### Step 2: Program the board

1. Open **Vivado Hardware Manager → Auto Connect**
2. Click **Program Device**
3. Bitstream:
   ```
   HW9\T1\vivado_project\T1.runs\impl_1\XADCdemo.bit
   ```

### Step 3: Test with oscilloscope

Connect the oscilloscope:
- **Ch1 → JB1** (SCK)
- **Ch2 → JB3** (MOSI)
- **GND probe → JB GND** (pin 5)

Expected waveform:
- SCK toggles at **500 Hz** (clkdiv = 100,000 cycles at 100MHz)
- SS goes LOW at the start of each 8-bit transmission
- MOSI carries the pattern `00001111` (MSB first: 0, 0, 0, 0, 1, 1, 1, 1)
- 8 SCK rising edges per byte, then SS goes HIGH
- Transmissions repeat continuously

The `led[15:8]` bar on the board will also reflect whatever the XADC is reading (even though constant data is sent via SPI).

---

## Task 2 — Easy Pulse Sensor to Arduino Serial Plotter

### Step 1: Build

From the **repo root** in PowerShell:

```powershell
.\HW9\T2\build.ps1
```

Same flow as T1 (~10–15 min).

### Step 2: Program the board

1. Open **Vivado Hardware Manager → Auto Connect**
2. Click **Program Device**
3. Bitstream:
   ```
   HW9\T2\vivado_project\T2.runs\impl_1\XADCdemo.bit
   ```

### Step 3: Upload Arduino code

1. Open `HW9\T2\arduino_receiver.ino` in the Arduino IDE
2. Select board: **Arduino Uno** (or your board)
3. Select the correct COM port
4. Upload

### Step 4: Test

1. Wire the Easy Pulse Sensor AO → JXADC pin 1, GND → JXADC pin 5
2. Wire JB1→Pin 2, JB2→Pin 12, JB3→Pin 13, GND→GND
3. Open **Serial Plotter** in Arduino IDE at **9600 baud**
4. You should see the pulse waveform graphed in real time

Pin 11 on the Arduino pulses HIGH each time a byte is received and printed — you can probe it to verify the timing.

---

## How the Arduino Code Works

The Arduino polls the SS line for a falling edge, then busy-waits on SCK to receive 8 bits:

```
SS goes LOW → start reception
  Loop 7 times:
    wait for SCK HIGH → sample MOSI → shift data left
    wait for SCK LOW
  Read 8th bit (no shift)
Print to Serial
SS goes HIGH → wait for next transmission
```

The for loop runs 7 times (`i < 7`) and handles bits 7–1. The 8th bit (LSB) is read outside the loop without a final left-shift, giving the correct byte value.

This polling approach works because SCK is only 500 Hz — the Arduino at 16 MHz has thousands of cycles between edges to catch every transition.

---

## File Reference

### T1
| File | Purpose |
|------|---------|
| `T1/XADCdemo.v` | Top module — XADC + SPI, sends constant `8'b00001111` |
| `T1/SPI_leader_transmitter.v` | SPI leader, 500Hz SCK, 8-bit MSB-first |
| `T1/constraints.xdc` | Pin constraints (JB1=sck, JB2=ss, JB3=mosi, JXADC) |
| `T1/build.ps1` | Build script — creates XADC IP via `create_ip` |

### T2
| File | Purpose |
|------|---------|
| `T2/XADCdemo.v` | Same top module — sends `data[15:8]` (real ADC value) |
| `T2/SPI_leader_transmitter.v` | Same SPI leader |
| `T2/constraints.xdc` | Same constraints |
| `T2/build.ps1` | Same build script |
| `T2/arduino_receiver.ino` | Arduino follower — polls SS/SCK, prints to Serial Plotter |

---

## Key Concepts for Report

### XADC data path
```
vauxp6/vauxn6 → xadc_wiz_0 → data[15:0]
data[15:8] → data_latch → SPI_leader_transmitter → JB1/JB2/JB3
```
The XADC output is left-aligned in 16 bits: `data[15:4]` = 12-bit result. Sending `data[15:8]` gives the top 8 bits (most significant portion of the conversion).

### SPI timing
- SCK idles **low**, SS idles **high**
- At the start of each byte: SS and SCK both go low on the same `negedge sck` (START state)
- Data is placed on MOSI at each subsequent `negedge sck`
- Arduino samples MOSI on each **rising edge** of SCK
- After 8 bits: SS goes high (STOP state), then immediately starts again when SPI_busy goes low

### T1 vs T2 one-line difference

| | T1 | T2 |
|--|----|----|
| `data_latch` source | `8'b00001111` (constant) | `data[15:8]` (live ADC) |
| Purpose | Verify SPI chain on oscilloscope | Stream sensor data to Arduino |

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| No waveform on oscilloscope | Wrong JB pin or GND not connected | JB1=SCK, JB3=MOSI, JB pin 5=GND |
| Serial Plotter shows flat line / zeros | Arduino not receiving data | Check JB1→Pin2, JB2→Pin12, JB3→Pin13, common GND |
| Serial Plotter shows random spikes | Floating MOSI or noise | Confirm all JXADC unused pins tied to GND |
| Sensor signal too noisy in plotter | Sensor AO > 1V | Scale sensor output to 0–1V range |
| Bitstream not found after build | Synthesis/impl error | Check `HW9\T1\vivado.log` or `HW9\T2\vivado.log` |
