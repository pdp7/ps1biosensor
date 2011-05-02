/* Analog Packet to PC 
 * --------------------------- 
 * This program sends data from multiple sensor analog inputs to the 
 PC over the serial port 
 * The code reads analog inputs and sends the data in an Open EEG 
 * Modular EEG 17 byte packet format back to the computer. 
 */
#include <TimerOne.h> //from http://www.arduino.cc/playground/Code/Timer1 
#include <Wire.h> 
int ledPin = 13;      // pin for the LED 
int chan1 = 0;      // analog pin for chan 1 
int chan2 = 1;       // analog pin for chan 2 
int ledStatus = LOW;  // we use a variable to toggle the LEDs state 
int ekg, oxy = 0;          // variable to store the analog reading 
char cnt =0; 
int i; 
int temperature; 
int sensorAddress = 0x91 >> 1;  // From datasheet temp sensor address is 0x91 
// shift the address 1 bit right, the Wire library only needs the 7 
// most significant bits for the address 
byte packet[17] = { 
  0xa5, 0x5a, 0x02, cnt, 0, 0, 0, 0, 1, 2, 3, 4, 5, 
  6, 7, 8, 0 }; 
byte msb; 
byte lsb; 
void setup() { 
  pinMode(ledPin, OUTPUT);  // declare the ledPin as an output 
  Serial.begin(57600);        // initialize the serial port 
  analogWrite(10, 150); 
  Timer1.initialize(3906); 
  Timer1.pwm(9, 512); 
  Timer1.attachInterrupt(ReadData); 
  Wire.begin();        // join i2c bus (address optional for master) 
} 

void loop () { 
  Wire.requestFrom(sensorAddress,2); 
  if (2 <= Wire.available())  // if two bytes were received 
  { 
    msb = Wire.receive();  // receive high byte (full degrees) 
    lsb = Wire.receive();  // receive low byte (fraction degrees) 
    temperature = ((msb) << 4);  // MSB 
    temperature |= (lsb >> 4);   // LSB 
    //temperature = temperature * 0.0625; 
  } 
  delay(500); 
} 

void ReadData() { 
  // read the analog value from A/D convertor and store it 
  ekg = analogRead(chan1); 
  oxy = analogRead(chan2); 
  // send the value over the port 
  packet [3] = cnt; 
  packet [5] = ekg; 
  packet [4] =  ekg>>8; 
  packet [6] =  temperature; 
  packet [7] =  temperature>>8; 
  //packet [8] =  oxy; 
  //packet [9] =  oxy >>8; 
  for (i=0; i< 17; i++) { 
    Serial.print ( packet [i], BYTE); 
  } 
  cnt++; 
  //  delayMicroseconds (1120); 
  // change the state of the LED (if HIGH, then LOW, and viceversa) 
  ledStatus = cnt >> 7; 
  digitalWrite(ledPin, ledStatus); 
}

