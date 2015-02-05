/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2015 Stefan Wendler
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

/**
 * Module to send tri-state signals to a radio for operation a RC switch.
 * 
 * The following wavefroms are used for the tri-states (each pulse is 350us):
 *
 * Tri-state "0" Bit
 *            _     _
 *           | |___| |___
 *            1  3  1  3
 *
 * Tri-state "1" Bit
 *            ___   ___
 *           |   |_|   |_
 *             3  1  3  1
 *
 * Tri-state "F" Bit
 *            _     ___
 *           | |___|   |_
 *            1  3   3  1
 *
 * "Sync" Bit
 *            _
 *           | |_______________________________
 *            1 31
 * 
 * A message to an RC switch has the following format:
 * 
 * 	<address><channel><status>
 * 
 * 	<address> is a 5 bit field. Most switches use 11111 as default. 
 * 	<channel> is A, B, C, D 
 * 	<status>  is 0 (off) or 1 (on)
 * 
 * To turn channel A on the switch at address 11111 ON, the message would look like this:
 * 
 * 	11111A1
 * 
 * For the module, this needs to be translated to tri-state wave form like so:
 * 
 *  0 in tri-state is F => 10001110
 * 	1 in tri-state is 0 => 10001000
 * 	
 * Thus, the address 11111 is in tri-state: 10001000_10001000_10001000_10001000_10001000  
 * 
 * The channel translates like this:
 * 
 * 	A in tri-state is 0FFFF => 10001000_10001110_10001110_10001110_10001110
 * 	B in tri-state is F0FFF => 10001110_10001000_10001110_10001110_10001110
 *  C in tri-state is FF0FF => 10001110_10001110_10001000_10001110_10001110
 * 	D in tri-state is FFF0F => 10001110_10001110_10001110_10001000_10001110
 * 
 * Then the state could be mapped like this:
 * 
 * 	0/off in tri-state is 0F => 10001000_10001110
 * 	1/on  in tri-state is F0 => 10001110_10001000
 * 
 * And finally the sync bit is a constant:
 * 
 * 	sync => 10000000_00000000_00000000_00000000
 * 
 *****************************************************************************
 * Also it shold be noted, that a message needs to be sent multible times (2-10). 
 * Otherwise it is very likely that the switch will not work!
 *****************************************************************************
 * 
 * inputs:
 * 		clk			on the positive edge, the next bit is shifted to the radio
 * 					the clock needs to provide 350us per cycle (from rising 
 * 					edge to rising edge)
 * 		send		if set to 1, the complete message (addr+chan+stat+sync) is send
 * 					over and over again until send is set back to 0
 *		addr		the address in tri-state wave-form
 * 					e.g. 40'b10001000_10001000_10001000_10001000_10001000 = 11111
 * 		chan		the channel identifier in tri-state wave-form 
 * 				 	e.g. 40'b10001000_10001110_10001110_10001110_10001110 = chan A 
 * 		stat		the status in tri-state wave-form
 * 					e.g. 16'b10001000_10001110 = ON 
 * 		sync		the sync bit in tri-state wave-form
 * 					e.g. 32'b10000000_00000000_00000000_00000000
 * outputs:
 * 		ready		1 if module is ready to send, 0 if sending is already in progrss
 * 		out			the bits shifted out to the radio
 */
module rcswitch_send(
	input clk, 
 	input send,
	input [39:0] addr,
	input [39:0] chan,
	input [15:0] stat,
	input [31:0] sync,
	output ready,
	output out 
	);

	reg r_out;
	reg r_ready;
	reg [7:0] pos;

	initial begin
		r_ready = 1;
		r_out 	= 0;
		pos 	= 0;
	end

	always @(posedge clk) begin
		
		// start a new message
		if(send && pos == 0) begin
			pos = 128;
			r_ready = 0;
		end
		// shift out the bits for the message
		else if(pos > 0) begin
			pos = pos - 1;
			
			if(pos < 128 && pos > 87) 
				r_out = (addr >> (pos - 88));
			else if(pos < 88 && pos > 47) 
				r_out = (chan >> (pos - 48));
			else if(pos < 48 && pos > 31) 
				r_out = (stat >> (pos - 32));
			else
				r_out = (sync >> pos) & 1'b1;
				
			// message is done - prepare for repeat
			if(pos == 0) begin
				r_ready = 1;
				r_out 	= 0;
				pos 	= 0;
			end
		end
	end

	assign ready = r_ready;
	assign out 	 = r_out;

endmodule 
