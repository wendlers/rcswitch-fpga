#!/usr/bin/python
import serial
import subprocess

def get_vol():

	vol = int(filter(lambda l: l.startswith('set-sink-volume'),
    	      subprocess.check_output(["pacmd","dump"])
        	  .split('\n'))[0]
         	 .split()[-1],16) / (65536 / 100) 

	return vol

def set_vol(vol):

	subprocess.call(["pactl", "set-sink-volume", "0", "%d%%" % vol])
 
	print("Setting volume to: %03d%%" % vol)

def up_vol(up):

	vol = get_vol() + up

	if vol > 100:
		vol = 100

	set_vol(vol)

	
def down_vol(down):

	vol = get_vol() - down

	if vol < 0:
		vol = 0

	set_vol(vol)


s = serial.Serial(port='/dev/ttyUSB1', baudrate=9600);

while True:

	c = s.read(1)

	if c == 'A':
		set_vol(0);
	elif c == 'a': 
		set_vol(12);
	elif c == 'B':
		set_vol(25)
	elif c == 'b': 
		set_vol(37);
	elif c == 'C':
		set_vol(50)
	elif c == 'c': 
		set_vol(62);
	elif c == 'D':
		set_vol(75)
	elif c == 'd': 
		set_vol(100);
