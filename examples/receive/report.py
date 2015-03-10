#!/usr/bin/python
import serial

s = serial.Serial(port='/dev/ttyUSB1', baudrate=9600);

while True:

	c = s.read(1)

	if c == 'A':
		print("Button A, ON")
	elif c == 'a': 
		print("Button A, OFF")
	elif c == 'B':
		print("Button B, ON")
	elif c == 'b': 
		print("Button B, OFF")
	elif c == 'C':
		print("Button C, ON")
	elif c == 'c': 
		print("Button C, OFF")
	elif c == 'D':
		print("Button D, ON")
	elif c == 'd': 
		print("Button D, OFF")
