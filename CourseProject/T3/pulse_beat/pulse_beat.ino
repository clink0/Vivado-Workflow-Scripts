// CourseProject T3 — Arduino heartbeat pulse generator
//
// Reads the analog pulse sensor on A0, detects peaks, and pulses
// pin 7 HIGH for 20 ms on each heartbeat. The Basys3 FPGA watches
// pin 7 (connected to JC1) for the rising edge.
//
// Wiring:
//   Pulse sensor Signal → Arduino A0
//   Pulse sensor VCC    → Arduino 3.3V (or 5V per sensor spec)
//   Pulse sensor GND    → Arduino GND
//   Arduino pin 7       → Basys3 JC1 (top-left pin of JC connector)
//   Arduino GND         → Basys3 GND (any GND pin on a Pmod connector)
//
// NOTE: Arduino digital pins output 5V; Basys3 JC is 3.3V LVCMOS.
// Add a 1k series resistor on the wire from pin 7 to JC1 to limit
// current through the FPGA's clamp diodes.

const int SENSOR_PIN    = A0;
const int BEAT_PIN      = 7;
const int REFRACTORY_MS = 300;  // min ms between beats (~200 BPM max)
const int PULSE_MS      = 20;   // pulse duration (FPGA only needs a few ns)
const int SAMPLE_MS     = 10;   // sampling interval -> ~100 Hz

int  peak_val   = 512;
int  trough_val = 512;
bool above      = false;
unsigned long last_beat_ms = 0;

void setup() {
  pinMode(BEAT_PIN, OUTPUT);
  digitalWrite(BEAT_PIN, LOW);
  Serial.begin(115200);
}

void loop() {
  int sig = analogRead(SENSOR_PIN);
  unsigned long now = millis();

  // Track running peak and trough; decay slowly toward midpoint
  if (sig > peak_val)   peak_val   = sig;
  if (sig < trough_val) trough_val = sig;
  int threshold = (peak_val + trough_val) / 2;
  peak_val--;
  trough_val++;

  // Rising edge across adaptive threshold with refractory guard
  if (sig > threshold && !above && (now - last_beat_ms) >= REFRACTORY_MS) {
    above = true;
    digitalWrite(BEAT_PIN, HIGH);
    delay(PULSE_MS);
    digitalWrite(BEAT_PIN, LOW);
    last_beat_ms = millis();
    Serial.println("BEAT");   // optional: visible in Serial Monitor
  }

  if (sig <= threshold) above = false;

  delay(SAMPLE_MS);
}
