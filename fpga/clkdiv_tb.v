module clkdiv_tb();
	reg clkIn = 1'b0;
	wire clkOut1, clkOut2, clkOut4, clkOut5;
	clkdiv #(.DIV(1)) INST1 (.clkIn(clkIn), .clkOut(clkOut1));
	clkdiv #(.DIV(2)) INST2 (.clkIn(clkIn), .clkOut(clkOut2));
	clkdiv #(.DIV(4)) INST4 (.clkIn(clkIn), .clkOut(clkOut4));
	clkdiv #(.DIV(5)) INST5 (.clkIn(clkIn), .clkOut(clkOut5));

	always #1 clkIn <= ~clkIn;
	
	initial begin
		$dumpfile("clkdiv_tb.vcd");
		$dumpvars();
		#50 $finish;
	end
endmodule
