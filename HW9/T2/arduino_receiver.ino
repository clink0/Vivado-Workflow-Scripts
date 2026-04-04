// HW9 T2 - Arduino SPI Follower Receiver
// Receives 8-bit ADC value from FPGA, prints to Serial for Serial Plotter
//
// Connections (FPGA JB -> Arduino):
//   JB1 (SCK)  -> Pin 2   (uses INT0 external interrupt for edge detection)
//   JB2 (SS)   -> Pin 12  (active low chip select)
//   JB3 (MOSI) -> Pin 13  (data from FPGA)
//   Basys3 GND -> Arduino GND
//
// Pin 11 = test/debug pulse (high while processing received byte)

const int PIN_SCK  = 2;
const int PIN_SS   = 12;
const int PIN_DATA = 13;
const int PIN_TEST = 11;

volatile uint8_t rxByte  = 0;
volatile uint8_t bitIdx  = 0;
volatile bool    newData = false;

// Called on every rising edge of SCK
void sck_rising() {
    if (digitalRead(PIN_SS) == LOW) {
        // Sample data bit on rising edge of SCK (MSB first)
        rxByte = (rxByte << 1) | digitalRead(PIN_DATA);
        bitIdx++;
        if (bitIdx == 8) {
            newData = true;
            bitIdx  = 0;
        }
    } else {
        // SS is high — idle, reset bit counter
        bitIdx = 0;
    }
}

void setup() {
    Serial.begin(115200);
    pinMode(PIN_SCK,  INPUT);
    pinMode(PIN_SS,   INPUT);
    pinMode(PIN_DATA, INPUT);
    pinMode(PIN_TEST, OUTPUT);
    digitalWrite(PIN_TEST, LOW);
    attachInterrupt(digitalPinToInterrupt(PIN_SCK), sck_rising, RISING);
}

void loop() {
    if (newData) {
        digitalWrite(PIN_TEST, HIGH);
        // Print raw 8-bit value (0-255); Serial Plotter will graph it
        Serial.println(rxByte);
        digitalWrite(PIN_TEST, LOW);
        newData = false;
    }
}
