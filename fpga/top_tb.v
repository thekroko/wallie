`define TESTBENCH

module top_tb();
	reg clk_100mhz = 1'b0, io_scl = 1'b0;
	wire led1, io_power_scl, gpio_21;
	inout io_power_sda, io_sda;
	reg hostSdaReq = 1'b1;
	reg powerSdaReq = 1'b1;

	assign (pull1, pull0) io_sda = 1'b1;
	assign (pull1, pull0) io_power_sda = 1'b1;
	assign io_sda = !hostSdaReq ? 1'b0 : 1'bZ;
	assign io_power_sda = !powerSdaReq ? 1'b0 : 1'bZ;

	top INST (
		.clk_100mhz(clk_100mhz),
		.io_scl(io_scl),
		.io_sda(io_sda),
		.io_power_sda(io_power_sda)
	);

	always #1 clk_100mhz <= ~clk_100mhz;
	always #5 io_scl <= ~io_scl;

	initial begin
		$dumpfile("top_tb.vcd");
		$dumpvars;
		
		#30 hostSdaReq <= 1'b0;
		#40 hostSdaReq <= 1'b1;
		
		#80 powerSdaReq <= 1'b0;
		#90 powerSdaReq <= 1'b1;

		#3000 $finish;
	end
endmodule
