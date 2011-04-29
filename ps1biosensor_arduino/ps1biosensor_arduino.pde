/* Analog Packet to PC 
 * --------------------------- 
 * This program sends data from multiple sensor analog inputs to the 
 PC over the serial port 
 * The code reads analog inputs and sends the data in an Open EEG 
 * Modular EEG 17 byte packet format back to the computer. 
 */

#include <TimerOne.h> //from http://www.arduino.cc/playground/Code/Timer1

int ledPin = 13;      // pin for the LED 
int chan1 = 0;      // analog pin for chan 1 
int chan2 = 1;       // analog pin for chan 2 
int ledStatus = LOW;  // we use a variable to toggle the LEDs state 
int ekg, oxy = 0;          // variable to store the analog reading 
char cnt =0; 
int i; 

byte packet[17] = {
  0xa5, 0x5a, 0x02, cnt, 0, 0, 0, 0, 1, 2, 3, 4, 5, 
  6, 7, 8, 0 }; 

void setup() { 
  pinMode(ledPin, OUTPUT);  // declare the ledPin as an output 
  Serial.begin(57600);        // initialize the serial port 
  analogWrite(10, 150); 
  Timer1.initialize(3906); 
  Timer1.pwm(9, 512); 
  Timer1.attachInterrupt(ReadData); 
} 

void loop () {
} 

void ReadData() { 
  // read the analog value from A/D convertor and store it 
  ekg = analogRead(chan1); 
  oxy = analogRead(chan2); 
  // send the value over the port 
  packet [3] = cnt; 
  packet [5] = ekg; 
  packet [4] =  ekg>>8; 
  packet [7] = oxy; 
  packet [6] =  oxy >>8; 
  for (i=0; i< 17; i++) { 
    Serial.print ( packet [i], BYTE); 
  } 
  cnt++; 
  //  delayMicroseconds (1120); 
  // change the state of the LED (if HIGH, then LOW, and viceversa) 
  ledStatus = cnt >> 7; 
  digitalWrite(ledPin, ledStatus); 

}
