import struct
import threading
import serial
import Queue

s = serial.Serial('/dev/ttyACM0', 57600, timeout=1)

def getpkts(ser) :
	p = ''
	while (len(p) < 17) :
		p += ser.read(17 - len(p))
	cnt, = struct.unpack('B', p[3:4])
	return {'cnt' : cnt}

#while True :
#	print getpkt(s)

class Reader(threading.Thread) :
	def __init__(self, serialport) :
		self.ser = serialport
		self.q = Queue.Queue()
		self.buf = ''
		self.stopped = False
		threading.Thread.__init__(self)

	def read(self, bytes) :
		self.buf += self.ser.read(bytes)

	def getpacket(self) :
		sz = len(self.buf)

		start_bound = '\xa5\x5a\x02'
		end_bound = '\x01\x02\x03\x04\x05\x06\x07\x08\x00'
		mid_bytes = 5

		pkt_bytes = len(start_bound) + mid_bytes + len(end_bound)

		if sz < pkt_bytes :
			return pkt_bytes - sz

		first_offset = self.buf.find(start_bound[0:1])
		if first_offset == -1 :
			self.buf = ''
			return pkt_bytes # we tossed everything, hopeless
		# line up on the first a5 we find.
		self.buf = self.buf[first_offset:]
		if len(self.buf) >= len(start_bound) and not self.buf.startswith(start_bound) :
			next_start = self.buf[1:].find(start_bound[0:1])
			if next_start == -1 :
				self.buf = '' # we found an a5
				# but it wasn't aligned and we had to toss the whole thing.
				return pkt_bytes
			self.buf = self.buf[next_start+1:]
			return pkt_bytes - len(self.buf)
		if (len(self.buf) < pkt_bytes) :
			return pkt_bytes - len(self.buf)

		# now we have framed and started the first 3 
		offset_end = len(start_bound) + mid_bytes
		if (self.buf[offset_end:offset_end+len(end_bound)] != end_bound) :
			# well that's pretty broken, re-align
			startbyte_again = self.buf[1:].find(start_bound[0:1])
			if (startbyte_again == -1) :
				# wow it is NOT our day is it?
				self.buf = ''
				return pkt_bytes
			self.buf = self.buf[startbyte_again+1:]
			return pkt_bytes - len(self.buf)

		# hooray! we have a packet! glory be!
		cnt, = struct.unpack('B', self.buf[3:4])
		self.buf = self.buf[pkt_bytes:]
		return {'cnt' : cnt}

	def run(self) :
		while not self.stopped :
			pkt = self.getpacket()
			if isinstance(pkt, int) :
				self.read(pkt)
			else :
				self.q.put(pkt)

if __name__ == '__main__' :
	r = Reader(s)
	try :
		r.start()
		while True :
			p = r.q.get()
			print p
	except KeyboardInterrupt :
		r.stopped = True
		r.ser.close()
