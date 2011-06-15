/* Analog Packet to PC 
 * --------------------------- 
 * This program sends data from multiple sensor analog inputs to the 
 PC over the serial port 
 * The code reads analog inputs and sends the data in an Open EEG 
 * Modular EEG 17 byte packet format back to the computer. 
 */

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include "WProgram.h"
#include "HardwareSerial.h"
#include "LCD_driver.h"
#include <TimerOne.h> //from http://www.arduino.cc/playground/Code/Timer1 
#include <Wire.h> 

int num = 1;
int xposPrev, xpos = 0;
int ain, ainPrev = 0;
int inc = 1;
int i = 1;
int ledPin = 2;      // pin for the LED 
int chan1 = 0;      // analog pin for chan 1 
int chan2 = 1;      // analog pin for chan 2
int chan3 = 2;      // analog pin for chan 3
int chan4 = 3;      // analog pin for chan 4
int chan5 = 4;      // analog pin for chan 5
int chan6 = 5;      // analog pin for chan 6
int ledStatus = LOW;  // we use a variable to toggle the LEDs state 
int curCh = 1;
int ch1, ch2, ch3, ch4, ch5, ch6 = 0;          // generic channel variable to store the analog reading 
char cnt =0; 
int temperature; 
int sensorAddress = 0x91 >> 1;  // From datasheet temp sensor address is 0x91 

//char *chMsgPtr;
char *chMsg = "Biosensor Array";
//char *chMsg1 = "Biosensor: Ch1";
//char *chMsg2 = "Biosensor: Ch2";
//char *chMsg3 = "Biosensor: Ch3";

// shift the address 1 bit right, the Wire library only needs the 7 
// most significant bits for the address 
byte packet[17] = { 
  0xa5, 0x5a, 0x02, cnt, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0 }; 
byte msb; 
byte lsb; 

void setup() { 
  pinMode(ledPin, OUTPUT);  // declare the ledPin as an output 

  ioinit();           //Initialize I/O
  LCDInit();	    //Initialize the LCD
  LCDContrast(44);
  LCDClear(WHITE);    // Clear LCD to a solid color
  LCDPutStr(chMsg, 0, 4, ORANGE, WHITE); // Write information on display

  Serial.begin(57600);        // initialize the serial port 
  // Set Timer1 to run at 255Hz
  Timer1.initialize(3906); 
  //we don't really need pwm output from the timer so commenting out
  //Timer1.pwm(3, 512);
  Timer1.attachInterrupt(ReadData); 

  //Wire.begin();        // join i2c bus (address optional for master) 
} 

void loop () { 

  int     s1, s2, s3;
  s1      =       !digitalRead(kSwitch1_PIN);
  s2      =       !digitalRead(kSwitch2_PIN);
  s3      =       !digitalRead(kSwitch3_PIN);


  /*Wire.requestFrom(sensorAddress,2); 
   if (2 <= Wire.available())  // if two bytes were received 
   { 
   msb = Wire.receive();  // receive high byte (full degrees) 
   lsb = Wire.receive();  // receive low byte (fraction degrees) 
   temperature = ((msb) << 4);  // MSB 
   temperature |= (lsb >> 4);   // LSB 
   //temperature = temperature * 0.0625; 
   }*/

  if(s1) {
    curCh = 1;
  }
  if(s2) {
    curCh = 2;
  }
  if(s3) {
    curCh = 3;
  }

  if(curCh == 1) {
    ain = ch1;
  }

  if(curCh == 2) {
    ain = ch2;
  }

  if(curCh == 3) {
    ain = ch3;
  }

  ain = 128-map(ain, 0, 1024, 0, 128);

  //don't draw diagonal line across screen from end to beginning
  if(xposPrev!=127)
    LCDSetLine( ainPrev,  xposPrev, ain, xpos ,BLACK);


  ainPrev=ain;
  xposPrev=xpos;
  xpos++;
  if(xpos > 127) {
    xpos = 0;
    LCDClear(WHITE);    // Clear LCD to a solid color
    LCDPutStr(chMsg, 0, 4, ORANGE, WHITE); // Write information on display
  }

  // 40 ms * 128 pixels = ~5 seconds screen view
  delay(40); 
} 

void ReadData() { 
  digitalWrite(4, HIGH); //output PWM signal with pulse width equal to this routine's processing time

  // toggle pin to view frequency easily on DMM (it will be timer isr freq/2)
  if(ledStatus == 0)
    ledStatus = 1;
  else
    ledStatus = 0;

  digitalWrite(ledPin, ledStatus);

  // read the analog value from A/D convertor and store it 
  ch1 = analogRead(chan1); //ecg
  ch2 = analogRead(chan2); //oximeter
  ch3 = analogRead(chan3); //gsr
  ch4 = analogRead(chan4); //co2
  ch5 = analogRead(chan5); //respitory rate
  ch6 = 0; //temperature [digital]
  // send the value over the port 
  packet [3] = cnt; 
  packet [5] = ch1; 
  packet [4] = ch1>>8; 
  packet [7] = ch2; 
  packet [6] = ch2>>8; 
  packet [9] = ch3; 
  packet [8] = ch3>>8; 
  packet [11] = ch4; 
  packet [10] = ch4>>8; 
  packet [13] = ch5; 
  packet [12] = ch5>>8; 
  packet [15] = ch6; 
  packet [14] = ch6>>8; 

  for (i=0; i< 17; i++) { 
    Serial.print ( packet [i], BYTE); 
  } 

  if(cnt<255)
    cnt++;
  else 
    cnt=0;
  //  delayMicroseconds (1120); 
  // change the state of the LED (if HIGH, then LOW, and viceversa) 
  //ledStatus = cnt >> 7; 
  digitalWrite(4, LOW);
}


