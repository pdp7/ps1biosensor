
int ledPin = 13;      // pin for the LED
int chan1 = 0;      // analog pin for chan 1
int chan2 = 1;       // analog pin for chan 2
int ledStatus = LOW;  // we use a variable to toggle the LEDs state
int val, val2 = 0;          // variable to store the potentiometer's reading
char cnt =0;
int i;

byte packet[17] = {0xa5, 0x5a, 0x02, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6,
7, 8, 0 };

void setup() {
 pinMode(ledPin, OUTPUT);  // declare the ledPin as an output
 Serial.begin(57600);        // initialize the serial port
}

void loop() {
 // read the potentiometer's value and store it
 val = analogRead(chan1);
 val2 = analogRead(chan2);

 // send the value over the port

 packet [3] = cnt;
 packet [5] = val;
 packet [4] = val>>8;
 packet [7] = val2;
 packet [6] = val2 >>8;

for (i=0; i< 17; i++) {
   Serial.print ( packet [i], BYTE);
    }

cnt++;


 delayMicroseconds (1120);

 // change the state of the LED (if HIGH, then LOW, and viceversa)
 ledStatus = cnt >> 7;
 digitalWrite(ledPin, ledStatus);
}

