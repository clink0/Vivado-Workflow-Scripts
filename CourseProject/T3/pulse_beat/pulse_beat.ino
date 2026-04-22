// CourseProject T3 — Arduino Serial Plotter for pulse sensor
//
// The FPGA handles all peak detection and BPM calculation via XADC.
// This sketch just streams the raw A0 value so you can watch the
// waveform in the Arduino Serial Plotter (Tools > Serial Plotter).
//
// Wiring:
//   Pulse sensor Signal → Arduino A0
//   Pulse sensor VCC    → Arduino 3.3V (or 5V per sensor spec)
//   Pulse sensor GND    → Arduino GND
//
// Open Serial Plotter at 115200 baud to see the live waveform.

void setup() {
  Serial.begin(115200);
}

void loop() {
  Serial.println(analogRead(A0));
  delay(10);  // 100 Hz
}
