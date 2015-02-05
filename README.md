RC Switch Send - Verilog Module to Operate 434MHz RC Switches
==============================================================
05.02.2015 Stefan Wendler
sw@kaltpost.de

Simple verilog module to operate a 434MHz RC switch from an FPGA. 

Basically this is a personyl exercize of mine to get familiar with Verilog HDL. 
If you interested in a more practical approach on operating a 434MHz switch, see
for example [this article] (http://gpio.kaltpost.de/?p=2163). 
 
For some theory on the protocol to operate the switches, you could 
have a look at [this article] (http://gpio.kaltpost.de/?paged=2), or read
the comment in `rcswitch.v`.

![MachXO2 with transmitter, RC switch and original remote] (./doc/setup.png)

Project Directory Layout
------------------------

The top-level directory structure of the project looks something like this:

* `sconstruct` 		SCons script to build icarus based Verilog simulation	
* `README.md`		this README
* `rcswitch.v`		Verilog of the mail logic to drive the switch
* `clockdiv.v`		Verilog for simple clock devider to send the bits at the right speed
* `top.v`			Top level module used on real FPGA
* `rcswitch_tb.v`	Testbench for simulation	


Requirements
------------

For simulation:

* [Icarus] (http://iverilog.icarus.com) (on Ubuntu like Linux: `apt-get install iverilog`)
* [GTKiWave] (http://gtkwave.sourceforge.net) (on Ubuntu like Linux: `apt-get install gtkwave`)
* [SCons] (http://www.scons.org) to build the simulation (on Ubuntu like Linux: `apt-get install scons`)

For the real thing (FPGA), I used the following setup:

* [Lattice MachXO2 breakout board] (http://www.latticesemi.com/en/Products/DevelopmentBoardsAndKits/MachXO2BreakoutBoard.aspx) (very afordable)
* [Lattice Diamond Software] (http://www.latticesemi.com/Products/DesignSoftwareAndIP/FPGAandLDS/LatticeDiamond.aspx), free license available (Installing this on Ubuntu is pain in the ass. But if you really like to do this, let me know and I could provide instructions)
* [RC switches] (http://www.pollin.de/shop/dt/MzMzOTQ0OTk-/Haustechnik/Funkschaltsysteme/Funksteckdosen_Set_mit_3_Steckdosen.html)
* [434MHz transmitter] (http://www.watterott.com/en/RF-Link-Transmitter-434MHz)


Wiring
------

	FPGA			Transmitter
	---------------------------
	3.3V			Vcc
	GND				GND
	Out (P1)		DATA


	FPGA			Buttons
	---------------------------
	P23				Button 1.1
	GND				Button 1.2
	P24				Button 2.1
	GND				Button 2.2
				
	Note: the buttons are low active, they are pulled up in the verilog.


Verilog
-------

For more details please see the sources. The netlist looks like so:

![Netlist] (./doc/netlist.png)


Running the Simulation
----------------------

Build the simulation in the project top-dir with:

	scons

Run it with:

	./rcswitch.vvp

This will produce `rcswitch.vcd` which could be loaded into GTKWave:

	gtkwave rcswitch.vcd

![Simulation result in GTKWave] (./doc/gtkwave.png)


Running on the MachXO2
----------------------

Open the `rcswitch.ldf` in Diamond. On the left side swich to "Process" tab, richt klick "JEDEC File/Rerun All". 
Then flash it to the FPGA by starting the programmer (Tools/Programmer).
