module uart_tx_tb();
	reg clk = 1'b0;
	wire tx, eol;

	reg[7:0] num = 8'hA5;

	uart_tx_stream #(.N(32), .WAIT(20)) INST (
		.clk(clk),
		.tx(tx),
		.eol(eol),
		.dataStream({"Hello World: ", uart_format.hex8(num) , "\n"})
		//.dataStream({"Hello", "World: \n"})

	);

	always #1 clk <= ~clk;

	initial begin
		$dumpfile("uart_tx_tb.vcd");
		$dumpvars;
		#2000 $finish;
	end
endmodule
