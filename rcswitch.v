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
 * Also it should be noted, that a message needs to be sent multible times (2-10). 
 * Otherwise it is very likely that the switch will not work!
 *****************************************************************************
 * 
 * inputs:
 * 		clk			on the positive edge, the next bit is shifted to the radio
 * 					the clock needs to provide 350us per cycle (from rising 
 * 					edge to rising edge)
 *		rst			reset
 * 		send		if set to 1, the complete message (addr+chan+stat+sync) is send
 * 					over and over again until send is set back to 0
 *		addr		the address in tri-state wave-form
 * 					e.g. 40'b10001000_10001000_10001000_10001000_10001000 = 11111
 * 		chan		the channel identifier in tri-state wave-form 
 * 				 	e.g. 40'b10001000_10001110_10001110_10001110_10001110 = chan A 
 * 		stat		the status in tri-state wave-form
 * 					e.g. 16'b10001000_10001110 = ON 
 * outputs:
 * 		ready		1 if module is ready to send, 0 if sending is already in progrss
 * 		out			the bits shifted out to the radio
 */
module rcswitch_send(
	input clk, 
	input rst,
 	input send,
	input [39:0] addr,
	input [39:0] chan,
	input [15:0] stat,
	output ready,
	output out 
	);

	reg r_out;
	reg r_ready;
	reg [7:0] pos;
	reg [127:0] msg;

	initial begin
		r_ready <= 1;
		r_out 	<= 0;
		pos 	<= 0;
		msg     <= 0;
	end

	always @(posedge clk or posedge rst) begin
		if(rst) begin
			r_ready <= 1;
			r_out 	<= 0;
			pos 	<= 0;
		end
		else begin
			// start a new message
			if(send && pos == 0) begin
				pos <= 128;
				r_ready <= 0;
				msg[127:0] <= {addr[39:0], chan[39:0], stat[15:0], 32'b10000000_00000000_00000000_00000000};
			end
			// shift out the bits for the message
			else if(pos > 0) begin
				pos <= pos - 1;
				r_out <= msg >> pos;
				
				// message is done - prepare for repeat
				if(pos == 0) begin
					r_ready <= 1;
					r_out 	<= 0;
					pos 	<= 0;
				end
				else begin
					r_ready <= 0;
				end
			end
			else begin
				msg <= ~msg;
			end
		end
	end

	assign ready = r_ready;
	assign out 	 = r_out;

endmodule 

/**
 * Module to detect tri-state wave forms. 
 * 
 * The module will detect a combination of high/low and count the clk cycles for 
 * each of the two phases:
 * 
 *        +---------+         +--
 * 		__|         |_________|
 *          count_h   count_l
 * 
 * inputs:
 * 		clk			clock used for the counter of high/low times. the clock should be
 *					a lot faster then the clock of the wave form
 *		rst			reset
 *		in			the input from the radio
 * outputs:
 * 		count_h		clk counts for the time the wave-form was high 
 * 		count_l		clk counts for the time the wave-form was low 
 * 		detected	1 if tri-state was detected, 0 otherwise 
 */
module tri_state_detect (
	input clk, 
	input rst,
	input in,
	output [31:0] count_h,
	output [31:0] count_l,
	output detected
);

	reg [31:0] ticks;
	reg [31:0] t1;
	reg [31:0] t2;

	reg synced;

	reg [31:0] r_count_h;
	reg [31:0] r_count_l;


	initial begin
		ticks 		<= 0;
		t1 			<= 0;
		t2 			<= 0;
		synced		<= 0;
		r_count_h 	<= 0;
		r_count_l 	<= 0;
	end

	always @(posedge clk or posedge rst) begin
		if(rst) begin
			ticks <= 0;
		end
		else begin
			ticks <= ticks + 1;
		end
	end

	always @(negedge in or posedge rst) begin
		if(rst) begin
			t2 <= 0;
		end
		else begin
			if(t1 > 0) begin
				t2 <= ticks;
			end
		end
	end

	always @(posedge in or posedge rst) begin
		if(rst) begin
			t1 			<= 0;
			r_count_h 	<= 0;
			r_count_l 	<= 0;
			synced		<= 0;
		end
		else begin
			if(t2 > t1) begin
				r_count_h = t2 - t1;
				r_count_l = ticks - t2;
				synced <= 1;
			end
			else begin
				synced <= 0;
			end
			t1 <= ticks;
		end
	end
	
	assign count_h 	= r_count_h;
	assign count_l 	= r_count_l;
	assign detected = (synced & in);

endmodule

/**
 * Module to receive tri-state signals for RC switches send by a radio.
 * 
 * inputs:
 * 		clk			clock used for the counter of high/low times. the clock should be
 *					a lot faster then the clock of the wave form
 *		rst			reset
 *		in			the input from the radio
 * outputs:
 * 		addr		address received (see rcswitch_send)
 * 		chan		channel received (see rcswitch_send)
 * 		stat		status received  (see rcswitch_send)
 * 		ready		1 if complete message was received, 0 otherwise
 */
module rcswitch_receive(
	input clk, 
	input rst,
	input in,
	output [39:0] addr,
	output [39:0] chan,
	output [15:0] stat,
	output ready
);

	reg [8:0] count;
	reg [95:0] msg;

	reg [39:0] r_addr;
	reg [39:0] r_chan;
	reg [15:0] r_stat;

	reg r_ready;

	initial begin
		count	<= 0;
		msg		<= 0;
		r_addr	<= 0;
		r_chan	<= 0;
		r_stat	<= 0;
		r_ready	<= 0;
	end

	wire [31:0] count_h;
	wire [31:0] count_l;
	wire detected;

	tri_state_detect tsd_inst (
		.clk(clk),
		.rst(rst),
		.in(in),
		.count_h(count_h),
		.count_l(count_l),
		.detected(detected)
	);

	always @(posedge detected or posedge rst) begin

		if(rst) begin
			count 	<= 0;
			r_addr	<= 0;
			r_chan	<= 0;
			r_stat	<= 0;
			r_ready	<= 0;
		end
		else begin

			// detected SYNC
			if(count_h * 10 < count_l) begin
				count <= 0;
				msg <= 0;
			end 
			// detected 1000
			else if(count_h < count_l) begin
				msg <= (msg << 4) | 96'b1000;
				count <= count + 1;
			end 
			// detected 1110
			else if(count_l < count_h) begin
				msg <= (msg << 4) | 96'b1110;
				count <= count + 1;
			end

			// message complete?
			if(count == 24) begin	
				{r_addr[39:0], r_chan[39:0], r_stat[15:0]} <= msg;
				r_ready <= 1;
				count <= 0;
				msg <= 0;
			end	
			else begin
				r_ready <= 0;
			end
		end

	end

	assign ready = r_ready;
	assign addr  = r_addr;
	assign chan  = r_chan;
	assign stat  = r_stat;

endmodule
