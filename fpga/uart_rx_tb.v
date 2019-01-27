module uart_rx_tb();
	reg clk = 1'b0;
	reg rx = 1'b1;
	uart_rx_buffer INST(
		.uartClk(clk),
		.rx(rx)
	);

	always #2 clk = ~clk;

	initial begin
		$dumpfile("uart_rx_tb.vcd");
		$dumpvars;

		#9; rx = 1'b0; // Start bit
		#4; rx = 1'b1; // Data 1
		#4; rx = 1'b1; // Data 2
		#4; rx = 1'b1; // Data 3
		#4; rx = 1'b1; // Data 4
		#4; rx = 1'b0; // Data 5
		#4; rx = 1'b0; // Data 6
		#4; rx = 1'b0; // Data 7
		#4; rx = 1'b0; // Data 8
		#4; rx = 1'b1; // Stop 1
	
		#4; rx = 1'b0; // Start bit
		#4; rx = 1'b1; // Data 1
		#4; rx = 1'b0; // Data 2
		#4; rx = 1'b0; // Data 3
		#4; rx = 1'b1; // Data 4
		#4; rx = 1'b0; // Data 5
		#4; rx = 1'b0; // Data 6
		#4; rx = 1'b1; // Data 7
		#4; rx = 1'b1; // Data 8
		#4; rx = 1'b1; // Stop 1
	
		#10 $finish;
	end
endmodule
