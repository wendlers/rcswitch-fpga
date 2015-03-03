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
 * Testbench for rcswitch_send.
 * 
 * I use this with iverilog and gtkwave:
 * 
 * 	iverilog -o rcswitch.vvp clockdiv.v rcswitch.v rcswitch_send_tb.v 	
 * 	./rcswitch_send.vvp
 * 	gtkwace rcswitch_send.vcd
 */
module rcswitch_test;

	reg [39:0] addr;
	reg [39:0] chan;
	reg [15:0] stat;
	reg send;

	initial begin
		#0   addr = 40'b10001000_10001000_10001000_10001000_10001000;	// 11111 
		#0   chan = 40'b10001000_10001110_10001110_10001110_10001110; 	// 0FFFF = A
		#0   stat = 16'b10001110_10001000;								// F0 = ON 
		#2   send = 1;
		#100 send = 0;
		#300 $finish;
	end

	// clock 
	reg clk = 0;
	always #1 clk = !clk;

	wire ready;
	wire out;

	rcswitch_send rcswitch_send_inst (
		.clk(clk),
		.rst(1'b0),
		.send(send),
		.addr(addr),
		.chan(chan),
		.stat(stat),
		.ready(ready),
		.out(out)
	);

	initial
	begin
    	$dumpfile("rcswitch_send.vcd");
		$dumpvars(0, rcswitch_send_inst);
	end

endmodule
