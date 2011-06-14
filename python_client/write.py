import serial
import struct
import time
import sys
ser = serial.Serial(sys.argv[1])  # open first serial port
cnt = 1
while True:
	#print ser.portstr       # check which port was really used
	msg = '\xa5\x5a\x02' + struct.pack('B', cnt) + struct.pack('B', cnt / 32) + '\x00' + struct.pack('B', cnt / 16) + '\x00' + struct.pack('B', cnt / 8) + '\x00' + struct.pack('B', cnt / 4) + '\x00' + struct.pack('B', cnt / 2) + '\x00' + struct.pack('B', cnt) + '\x00' + '\x00\n' 
	ser.write(msg)
	print cnt
	time.sleep(0.005)
	if cnt == 255:
		cnt = 0
	else:
		cnt=cnt+1
ser.close()             # close port
