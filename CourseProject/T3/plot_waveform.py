#!/usr/bin/env python3
"""
Course Project T3 — Real-time pulse waveform plot
Reads raw XADC bytes from the Basys3 UART (115200 baud) and plots
them live using matplotlib.

Usage:
    python plot_waveform.py [COM_PORT]
    python plot_waveform.py COM3          # Windows
    python plot_waveform.py /dev/ttyUSB0  # Linux/Mac

The FPGA sends one byte per XADC sample (~1 kSPS), giving a live view
of the analog signal on JXADC pin VAUXP6/VAUXN6.

Install dependencies first:
    pip install pyserial matplotlib
"""

import sys
import serial
import collections
import matplotlib.pyplot as plt
import matplotlib.animation as animation

# ── Configuration ──────────────────────────────────────────────────────────
BAUD      = 115200
WINDOW    = 500        # samples to display at once
PORT      = sys.argv[1] if len(sys.argv) > 1 else "COM3"
VREF      = 3.3        # Basys3 XADC VREF in volts

# ── Open serial port ───────────────────────────────────────────────────────
try:
    ser = serial.Serial(PORT, BAUD, timeout=0.1)
    print(f"Connected to {PORT} at {BAUD} baud")
except serial.SerialException as e:
    print(f"ERROR: Cannot open {PORT}: {e}")
    print("Available ports:")
    import serial.tools.list_ports
    for p in serial.tools.list_ports.comports():
        print(f"  {p.device}  {p.description}")
    sys.exit(1)

# ── Circular buffer ────────────────────────────────────────────────────────
buf = collections.deque([0.0] * WINDOW, maxlen=WINDOW)

# ── Plot setup ─────────────────────────────────────────────────────────────
fig, ax = plt.subplots(figsize=(10, 4))
fig.patch.set_facecolor('#1a1a2e')
ax.set_facecolor('#16213e')
line, = ax.plot(range(WINDOW), list(buf), color='#00d4aa', linewidth=1.5)

ax.set_xlim(0, WINDOW)
ax.set_ylim(-0.1, VREF + 0.1)
ax.set_xlabel("Samples", color='white')
ax.set_ylabel("Voltage (V)", color='white')
ax.set_title("Course Project T3 — Pulse Sensor Waveform (live)", color='white', fontsize=12)
ax.tick_params(colors='white')
for spine in ax.spines.values():
    spine.set_edgecolor('#444444')

# Threshold line (visual reference at ~1.65V / midpoint)
threshold_line = ax.axhline(y=VREF / 2, color='red', linestyle='--',
                             linewidth=1, alpha=0.6, label='Threshold')
ax.legend(loc='upper right', facecolor='#1a1a2e', labelcolor='white')

plt.tight_layout()

# ── Animation update ────────────────────────────────────────────────────────
def update(frame):
    raw = ser.read(ser.in_waiting or 1)
    for b in raw:
        voltage = b / 255.0 * VREF
        buf.append(voltage)
    line.set_ydata(list(buf))
    return (line,)

ani = animation.FuncAnimation(fig, update, interval=30, blit=True, cache_frame_data=False)

try:
    plt.show()
finally:
    ser.close()
    print("Serial port closed.")
