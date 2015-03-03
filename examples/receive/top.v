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
 * Top module receiving commands from remote control. Each channel (A..D) of 
 * the remote switches a LED (0..3). 
 * 
 * inputs:
 * 	clk_12M		12MHz input clock
 * 	in			input from radio	
 * 
 * outputs:
 * 	LED			all the 7 LEDs from the MachXO2 eval board
 *	ready		the ready state from the rcswitch_receive module
 */	
module top(
	input clk_12M,
	input in,
	output [7:0] LED,
	output ready
	);

	reg [7:0] r_led;
	reg [1:0] chan_id;	

	initial begin
		r_led[7:0] = 0;
		chan_id = 0;
	end
	
	wire clk_rcswitch;

	clockdiv #(1000) clockdiv_inst1 (
		.clk_i(clk_12M),
		.clk_o(clk_rcswitch)
	);

	wire [39:0] addr;
	wire [39:0] chan;
	wire [15:0] stat;

	// the receive instance
	rcswitch_receive rcswitch_receive_inst1 (
		.clk(clk_rcswitch),
		.in(in),
		.rst(1'b0),		// no reset
		.addr(addr),
		.chan(chan),
		.stat(stat),
		.ready(ready)
	);

	// ready indicates a new message was received
	always @(posedge ready) begin
		
		// check if the message matches our addresss
		if(addr == 40'h8888888888) begin

			// see which channel is addressed (A, B, C or D) 
			if(chan == 40'h888E8E8E8E) begin
				chan_id = 0;
			end
			else if(chan == 40'h8E888E8E8E) begin
				chan_id = 1;
			end
			else if(chan == 40'h8E8E888E8E) begin
				chan_id = 2;
			end
			else if(chan == 40'h8E8E8E888E) begin
				chan_id = 3;
			end

			// see what state is requested (ON or OFF)
			if(stat == 16'h8E88) begin
				r_led[chan_id] = 1'b0;
			end
			else  if(stat == 16'h888E) begin
				r_led[chan_id] = 1'b1;
			end
		end
	end

	assign LED = ~r_led;	

endmodule
