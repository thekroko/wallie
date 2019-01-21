`include "prescaler.v"
`include "twi_slave.v"

module top (
	input clk_100mhz,
	output led1,
	// I2C
	input io_scl,
	inout io_sda
);
	// Clock Generator
	wire clk_16mhz, pll_locked;
`ifdef TESTBENCH
	assign clk_16mhz = clk_100mhz, pll_locked = 1;
`else

	SB_PLL40_PAD #(
		.FEEDBACK_PATH("SIMPLE"),
		.DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
		.DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
		.PLLOUT_SELECT("GENCLK"),
		.FDA_FEEDBACK(4'b1111),
		.FDA_RELATIVE(4'b1111),
		.DIVR(4'b0011),		// DIVR =  3
		.DIVF(7'b0101000),	// DIVF = 40
		.DIVQ(3'b110),		// DIVQ =  6
		.FILTER_RANGE(3'b010)	// FILTER_RANGE = 2
	) pll (
		.PACKAGEPIN   (clk_100mhz),
		.PLLOUTGLOBAL (clk_16mhz ),
		.LOCK         (pll_locked),
		.BYPASS       (1'b0      ),
		.RESETB       (1'b1      )
	);
`endif

	// Blink LED with ~2 Hz
	//wire clk_2hz;
	//prescaler #(.bits(24)) ps1(.clk_in(clk_16mhz), .clk_out(clk_2hz));
	//assign led1 = clk_2hz;

	// I2C
	wire sdaIn, sdaOut, sdaOutEn;
	SB_IO #(
		.PIN_TYPE(6'b1010_01),
		.PULLUP(1'b1)
	) io_block_instance (
		.PACKAGE_PIN(io_sda),
		.OUTPUT_ENABLE(sdaOutEn),
		.D_OUT_0(sdaOut),
		.D_IN_0(sdaIn)
        );
	wire sdaOut1, sdaOut2, sdaOut3;
	wire sdaOutEn1, sdaOutEn2, sdaOutEn3;
	assign sdaOut = (sdaOutEn1 && sdaOut1) || (sdaOutEn2 && sdaOut2) || (sdaOutEn3 && sdaOut3);
	assign sdaOutEn = sdaOutEn1 || sdaOutEn2 || sdaOutEn3;
	
	// 1-bit register controlling LED
	reg ledState = 1'b1;
	wire[7:0] ledOut;
	always @ (ledOut) ledState <= ledOut[0];
	assign led1 = ledState;
	twi_slave #(.ADDR(7'h33)) twi1(
		.scl(io_scl), .sdaIn(sdaIn), .sdaOut(sdaOut1), .sdaOutEn(sdaOutEn1),
		.dataOut({7'b0, ledState[0]}), .dataIn(ledOut)
	); 

	// Constant 0x88 output register
	twi_slave #(.ADDR(7'h44)) twi2(
		.scl(io_scl), .sdaIn(sdaIn), .sdaOut(sdaOut2), .sdaOutEn(sdaOutEn2),
		.dataOut(8'h88)
	); 
	
	
	// Simple R/W register
	reg[7:0] mem = 8'h55;
	wire[7:0] newMem;
	always @ (newMem) mem <= newMem;
	twi_slave #(.ADDR(7'h55)) twi3(
		.scl(io_scl), .sdaIn(sdaIn), .sdaOut(sdaOut3), .sdaOutEn(sdaOutEn3),
		.dataOut(mem), .dataIn(newMem)
	); 


endmodule
