import struct
import threading
import serial
import Queue
import sys
import time
try :
	import simplejson as json
except ImportError :
	import json

import tornado.ioloop
import tornado.web

NCHAN = 6

class Reader(threading.Thread) :
	def __init__(self, serialport) :
		self.ser = serialport
		self.q = Queue.Queue()
		self.buf = ''
		self.stopped = False
		threading.Thread.__init__(self)

	def read(self, bytes) :
		self.buf += self.ser.read(bytes)
		print "self.buf: "
		print self.buf

	def getpacket(self) :
		sz = len(self.buf)
		print "self.buf.len: "
		print sz

		start_bound = '\xa5\x5a\x02'
		#end_bound = '\x01\x02\x03\x04\x05\x06\x07\x08\x00'
		#end_bound = '\x07\x08\x00'
		end_bound = '\x00'
		mid_bytes = 5 + 6 + 2

		pkt_bytes = len(start_bound) + mid_bytes + len(end_bound)

		if sz < pkt_bytes :
			print "return pkt_bytes - sz"
			return pkt_bytes - sz

		first_offset = self.buf.find(start_bound[0:1])
		if first_offset == -1 :
			self.buf = ''
			print "return pkt_bytes" # we tossed everything, hopeless
			return pkt_bytes # we tossed everything, hopeless
		print "line up on the first a5 we find."
		self.buf = self.buf[first_offset:]
		if len(self.buf) >= len(start_bound) and not self.buf.startswith(start_bound) :
			next_start = self.buf[1:].find(start_bound[0:1])
			if next_start == -1 :
				self.buf = '' # we found an a5
				print "but it wasn't aligned and we had to toss the whole thing."
				return pkt_bytes
			self.buf = self.buf[next_start+1:]
			return pkt_bytes - len(self.buf)
		if (len(self.buf) < pkt_bytes) :
			return pkt_bytes - len(self.buf)

		print "now we have framed and started the first 3"
		offset_end = len(start_bound) + mid_bytes
		if (self.buf[offset_end:offset_end+len(end_bound)] != end_bound) :
			print "well that's pretty broken, re-align"
			startbyte_again = self.buf[1:].find(start_bound[0:1])
			if (startbyte_again == -1) :
				print "wow it is NOT our day is it?"
				self.buf = ''
				return pkt_bytes
			self.buf = self.buf[startbyte_again+1:]
			return pkt_bytes - len(self.buf)

		print "hooray! we have a packet! glory be!"
		cnt, = struct.unpack('B', self.buf[3:4])
		chans = []
		for i in range(NCHAN) :
			fmt = '>H'
			#believe arduino sketch used to have incorrect byte ordering for 1st channel -drew
			#if i == 0 :
				#fmt = '<H'
			o = 4 + 2 * i
			print o
			v, = struct.unpack(fmt, self.buf[o:o+2])
			print v
			chans.append(v)
		self.buf = self.buf[pkt_bytes:]
		print "cnt"
		print cnt
		print "chans"
		print chans
		return {'cnt' : cnt, 'chans' : chans}

	def run(self) :
		while not self.stopped :
			pkt = self.getpacket()
			if isinstance(pkt, int) :
				self.read(pkt)
			else :
				self.q.put(pkt)

class Writer(threading.Thread) :
	def __init__(self, r) :
		self.r = r
		self.stopped = False
		self.len = 300
		self.data = []
		for i in range(NCHAN) :
			self.data.append([0] * self.len)
		threading.Thread.__init__(self)

	def run(self) :
		while not self.stopped :
			try :
				pkt = self.r.q.get(timeout=0.05)
				for chan in range(NCHAN) :
					data = self.data[chan][1:]
					data.append(pkt['chans'][chan])
					self.data[chan] = data
			except Queue.Empty :
				pass
	
	def write(self) :
		d = []
		for dat in self.data :
			d.append(zip(range(self.len), dat))
		return json.dumps(d)

class MainHandler(tornado.web.RequestHandler):
	def get(self):
		htmlf = open('interface.html')
		html = htmlf.read()
		htmlf.close()
		self.write(html)

class FlotHandler(tornado.web.RequestHandler):
	def get(self, fn) :
		# TODO file security!
		fn = 'flot/%s' % fn
		fh = open(fn, 'r')
		try :
			self.write(fh.read())
		finally :
			fh.close()

class DataHandler(tornado.web.RequestHandler):
	def initialize(self, writer):
		self.writer = writer

	def get(self):
		self.write(self.writer.write())

def sec() :
	return int(time.time())

if __name__ == "__main__":
	port_number = None
	try :
		port_number = int(sys.argv[1])
	except :
		port_number = sys.argv[1]
	s = serial.Serial(port_number, 9600, timeout=1)

	r = Reader(s)
	r.start()
	w = Writer(r)
	w.start()

	application = tornado.web.Application([
		(r"/$", MainHandler),
		(r'/flot/(.*)', FlotHandler),
		(r"/a", DataHandler, dict(writer=w)),
	])
	application.listen(8888)

	try :
		tornado.ioloop.IOLoop.instance().start()
	except KeyboardInterrupt :
		r.stopped = True
		w.stopped = True
		r.ser.close()
