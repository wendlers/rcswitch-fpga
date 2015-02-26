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
 * Testbench for rcswitch_reveive.
 * 
 * I use this with iverilog and gtkwave:
 * 
 * 	iverilog -o rcswitch.vvp clockdiv.v rcswitch.v rcswitch_receive_tb.v 	
 * 	./rcswitch_receive.vvp
 * 	gtkwace rcswitch_receive.vcd
 */
module rcswitch_test;

	reg in; 

	initial begin
		#0 	 in = 1;

		// Garbage
		#30	 in = 1;	// 1000 - 1
		#10	 in = 0;
		#22	 in = 1;	// 1000 
		#10	 in = 0;
		#30	 in = 1;	// 1000 - 2
		#10	 in = 0;
		#30	 in = 1;	// 1000
		#11	 in = 0;

		// Sync 10000000_00000000_00000000_00000000
		#30	 in = 1;	// 1000 - 1
		#10	 in = 0;
		#30	 in = 0;	// 0000 
		#30	 in = 0;
		#10	 in = 0;	// 0000 - 2
		#30	 in = 0;
		#10	 in = 0;	// 0000 
		#30	 in = 0;
		#10	 in = 0;	// 0000 - 3
		#30	 in = 0;
		#10	 in = 0;	// 0000 
		#30	 in = 0;
		#10	 in = 0;	// 0000 - 4
		#30	 in = 0;
		#10	 in = 0;	// 0000 
		#30	 in = 0;
	
		// Address 10001000_10001000_10001000_10001000_10001000
		#10	 in = 1;	// 1000 - 1
		#18	 in = 0;
		#30	 in = 1;	// 1000
		#08	 in = 0;
		#30	 in = 1;	// 1000 - 2
		#10	 in = 0;
		#25	 in = 1;	// 1000
		#10	 in = 0;
		#30	 in = 1;	// 1000 - 3
		#10	 in = 0;
		#22	 in = 1;	// 1000 
		#10	 in = 0;
		#30	 in = 1;	// 1000 - 4
		#10	 in = 0;
		#30	 in = 1;	// 1000
		#11	 in = 0;
		#30	 in = 1;	// 1000 - 5
		#10	 in = 0;
		#30	 in = 1;	// 1000
		#10	 in = 0;

		// Channel 10001000_10001110_10001110_10001110_10001110
		#30	 in = 1;	// 1000 - 1
		#17	 in = 0;
		#30	 in = 1;	// 1000
		#10	 in = 0;
		#30	 in = 1;	// 1000 - 2
		#10	 in = 0;
		#30	 in = 1;	// 1110 
		#30	 in = 0;
		#10	 in = 1;	// 1000 - 3
		#10	 in = 0;
		#30	 in = 1;	// 1110 
		#30	 in = 0;
		#10	 in = 1;	// 1000 - 4
		#10	 in = 0;
		#30	 in = 1;	// 1110 
		#30	 in = 0;
		#10	 in = 1;	// 1000 - 5
		#10	 in = 0;
		#30	 in = 1;	// 1110 
		#30	 in = 0;

		// Stat 10001110_10001000
		#10	 in = 1;	// 1000 - 1
		#10	 in = 0;
		#30	 in = 1;	// 1110 
		#30	 in = 0;
		#10	 in = 1;	// 1000 - 2
		#10	 in = 0;
		#30	 in = 1;	// 1000
		#10	 in = 0;

		// Sync 10000000_00000000_00000000_00000000
		#30	 in = 1;	// 1000 - 1
		#10	 in = 0;
		#30	 in = 0;	// 0000 
		#30	 in = 0;
		#10	 in = 0;	// 0000 - 2
		#30	 in = 0;
		#10	 in = 0;	// 0000 
		#30	 in = 0;
		#10	 in = 0;	// 0000 - 3
		#30	 in = 0;
		#10	 in = 0;	// 0000 
		#30	 in = 0;
		#10	 in = 0;	// 0000 - 4
		#30	 in = 0;
		#10	 in = 0;	// 0000 
		#30	 in = 0;

		#100 $finish;
	end

	// clock 
	reg clk = 0;
	always #1 clk = !clk;

	wire [31:0] count_h;
	wire [31:0] count_l;
	wire detected;

	tri_state_detect tsd_inst (
		.clk(clk),
		.rst(1'b0),
		.in(in),
		.count_h(count_h),
		.count_l(count_l),
		.detected(detected)
	);

	initial
	begin
    	$dumpfile("rcswitch_pt.vcd");
		$dumpvars(0, tsd_inst);
	end

	always @(posedge detected) begin
		$display("Pulse with H=%d, L=%d detected.", count_h, count_l);
	end

endmodule
