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
 * Trigger sending a message to the RC switch based on two input buttons.
 * The message is repeated as long as the button is pressed. 
 * Button 0 turns ON, button 1 turns OFF.
 * 
 * inputs:
 * 	buttons		two buttons 0 - to send on message, 1 to send off message
 * 	ready		ready state from rcswitch_send
 * 
 * outputs:
 * 	send		send to rcswtich_send
 *	stat		tri-state wave-form for the status (on/off) connecetd to rcswitch_send
 *	led			a status led turned on when one of the buttons is pressed	
 */
module button_trigger(
	input [1:0] buttons,
	input ready,
	output send,
	output [15:0] stat,
	output led
	);
	reg r_led;
	reg r_send;
	reg [15:0] r_stat;

	initial begin
		r_led = 1;
		r_send = 0;
		r_stat = 0;
	end

	// on any button state change (press/release)
	always @ (posedge buttons[0:0] or negedge buttons[0:0] or posedge buttons[1:1] or negedge buttons[1:1]) begin
		
		// button 0 pressen - load ON message, start sending
		if(buttons[0:0] == 0) begin
			r_stat[15:0] = 16'b10001000_10001110;
			r_send = 1;
			r_led = 0;
		end
		// button 1 pressen - load OFF message, start sending
		else if(buttons[1:1] == 0) begin
			r_stat[15:0] = 16'b10001110_10001000;			
			r_send = 1;
			r_led = 0;
		end
		// buttons released - stop sending
		else begin
			r_stat[15:0] = 0;
			r_send = 0;
			r_led = 1;
		end
		
	end

	assign send = r_send;
	assign stat = r_stat;
	assign led = r_led;

endmodule

/**
 * The top module.
 * 
 * inputs:
 * 	clk_12M		12MHz input clock
 * 	buttons		two input buttons
 * 
 * outputs:
 * 	LED			all the 7 LEDs from the MachXO2 eval board
 *	ready		the reade state from the rcswitch_send module
 * 	out			the output from the rcswitch_send - goes to the radio
 */	
module top(
	input clk_12M,
	input [1:0] buttons,
	output [7:0] LED,
	output ready,
	output out
	);

	reg [7:0] leds;
	
	reg [39:0] addr;
	reg [39:0] chan;
	reg [31:0] sync;

	initial begin
		leds[7:1] = 7'b0111111;	
	
		// this is kept constant in this example - only the state is changed		
		addr  = 40'b10001000_10001000_10001000_10001000_10001000;	// 11111 
		chan  = 40'b10001000_10001110_10001110_10001110_10001110; 	// 0FFFF = A
		sync  = 32'b10000000_00000000_00000000_00000000; 			// SYNC
	end
	
	wire clk_rcswitch;

	// we need a clock wich a cycle of 350us
	clockdiv #(2100) clockdiv_inst1 (
		.clk_i(clk_12M),
		.clk_o(clk_rcswitch)
	);

	wire send;
	wire [15:0] stat;

	// the send instance
	rcswitch_send rcswitch_send_inst1 (
		.clk(clk_rcswitch),
		.send(send),
		.addr(addr),
		.chan(chan),
		.stat(stat),
		.sync(sync),
		.ready(ready),
		.out(out)
	);

	// the button based send trigger
	button_trigger button_trigger_inst1 (
		.buttons(buttons),
		.ready(ready),
		.send(send),
		.stat(stat),
		.led(LED[0:0])
	);

	assign LED = leds;
	
endmodule
