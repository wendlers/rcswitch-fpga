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
 * Simple UART TX module to send bytes via UART.
 * 
 * inputs:
 * 	clk			clock maintaining the correct slots for the desired baudrate	
 * 	send		enable sending with 1, disable with 0
 *	data		data byte to transmit
 * 
 * outputs:
 * 	tx			bits to send to the UART line	
 *	ready		set to 1 if data byte is transmitted, 0 otherwise	
 */	
module uart_tx(
	input clk,
	input send,
	input [7:0] data,
	output tx,
	output ready
);
	reg [7:0] bit_count;
	reg [10:0] msg;

	reg r_tx; 
	reg r_ready; 

	initial begin
		bit_count 	<= 0;
		msg 		<= 0;
		r_tx 		<= 0;
		r_ready 	<= 0;
	end

	always @(posedge clk) begin
		if(send && !msg) begin
			// add start bit and stop bit + pause
			msg <= {2'b11, data, 1'b0}; 
		end
		if(msg) begin
			r_tx <= msg[0];
			msg  <= msg >> 1;
		end
	end
	
	assign tx = r_tx;
	assign ready = !msg;

endmodule
	
/**
 * Top module receiving commands from remote control. Each channel (A..D) of 
 * the remote switches a LED (0..3). For each received state, the following 
 * character is send to the UART:
 * 
 * 	A	- channel A, ON
 *  a	- channel A, OFF
 * 	B	- channel B, ON
 *  b	- channel B, OFF
 * 	C	- channel C, ON
 *  c	- channel C, OFF
 * 	D	- channel D, ON
 *  d	- channel D, OFF
 * 
 * Each state is reportet only once. Repeated presses regarding the same state
 * are not send. 
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
	output tx,
	output ready
	);

	reg [7:0] r_led;
	reg [1:0] chan_id;	
	reg [7:0] tx_data;
	reg [7:0] tx_data_prev;

	initial begin
		r_led[7:0] = 0;
		chan_id = 0;
		tx_data = 8'd78;
		tx_data_prev = 8'd78;
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

	wire clk_uart;
	
	// we need a clock with a cycle of 104us for   9600Baud (1/  9600 * 1000000)
	// we need a clock with a cycle of 8.7us for 115200Baud (1/115200 * 1000000)
	// 12MHz ~ 12us, the devider is then <baud-us>*12/2
	// - for   9600:  104 * 12 / 2 = 624
	// - for 115200: 8.68 * 12 / 2 = 52
	// clockdiv #(624) clockdiv_inst2 (
	clockdiv #(52) clockdiv_inst2 (
		.clk_i(clk_12M),
		.clk_o(clk_uart)
	);

	wire send;
	wire uart_ready;

	uart_tx uart_tx_inst(
		.clk(clk_uart),
		.send(send),
		.data(tx_data),
		.tx(tx),
		.ready(uart_ready)
	);

	always @(posedge uart_ready) begin
		// send each received state only once
		tx_data_prev <= tx_data;
	end

	assign send = (tx_data != tx_data_prev);

	// ready indicates a new message was received
	always @(posedge ready) begin
		
		// check if the message matches our addresss
		if(addr == 40'h8888888888) begin

			// see which channel is addressed (A, B, C or D) 
			if(chan == 40'h888E8E8E8E) begin
				chan_id = 0;
				tx_data = 8'd65;		// ASCII A
			end
			else if(chan == 40'h8E888E8E8E) begin
				chan_id = 1;
				tx_data = 8'd66;		// ASCII B
			end
			else if(chan == 40'h8E8E888E8E) begin
				chan_id = 2;
				tx_data = 8'd67;		// ASCII C
			end
			else if(chan == 40'h8E8E8E888E) begin
				chan_id = 3;
				tx_data = 8'd68;		// ASCII D
			end

			// see what state is requested (ON or OFF)
			if(stat == 16'h8E88) begin
				r_led[chan_id] = 1'b0;
				tx_data = tx_data + 32; 	// a, b, c or d
			end
			else  if(stat == 16'h888E) begin
				r_led[chan_id] = 1'b1;
			end
		end
	end

	assign LED = ~r_led;	

endmodule
