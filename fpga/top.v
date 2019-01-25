`include "prescaler.v"
`include "twi_slave2.v"
`include "twi_proxy.v"
`include "uart_tx.v"
`include "clkdiv.v"

module top (
	input clk_100mhz,
	output led1,
	// I2C
	input io_scl,
	inout io_sda,
	output io_power_scl,
	inout io_power_sda,
	// Debugging
	output io_uart_tx,
	output gpio_18,
	output gpio_19,
	output gpio_20,
	output gpio_21
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
	wire clk_4hz;
	reg clk_2hz = 1'b0;
	prescaler #(.bits(23)) ps1(.clk_in(clk_16mhz), .clk_out(clk_4hz));
	always @ (posedge clk_4hz) clk_2hz <= ~clk_2hz;

	// I2C
	wire hostSdaIn,hostSdaOutEn;
`ifdef TESTBENCH
	assign io_sda = hostSdaOutEn ? 1'b0 : 1'bZ;
	assign hostSdaIn = io_sda;
`else
	SB_IO #(
		.PIN_TYPE(6'b1010_01),
		.PULLUP(1'b1)
	) hostTwi (
		.PACKAGE_PIN(io_sda),
		.OUTPUT_ENABLE(hostSdaOutEn),
		.D_OUT_0(1'b0),
		.D_IN_0(hostSdaIn)
        );
`endif

	// Link to Power I2C chip
	wire powerSdaOutEn, powerSdaIn, proxySdaLow;
`ifdef TESTBENCH
	assign io_power_sda = powerSdaOutEn ? 1'b0 : 1'bZ; 
	assign powerSdaIn = io_power_sda;
`else
	SB_IO #(
		.PIN_TYPE(6'b1010_01),
		.PULLUP(1'b1)
	) powerTwi (
		.PACKAGE_PIN(io_power_sda),
		.OUTPUT_ENABLE(powerSdaOutEn),
		.D_OUT_0(1'b0),
		.D_IN_0(powerSdaIn)
        );
`endif
        twi_proxy twiProxy (
		.clk(clk_16mhz),
		.hostScl(io_scl),
		.hostSdaIn(hostSdaIn),
		.hostSdaLow(proxySdaLow),
		.mirrorScl(io_power_scl),
		.mirrorSdaIn(powerSdaIn),
		.mirrorSdaLow(powerSdaOutEn)
	);

	// For debugging twi_proxy bypass:
        //assign powerSdaOutEn = !hostSdaIn; // No mirror, just one-way proxy
	//assign proxySdaLow = 1'b0;
	//assign io_power_scl = io_scl;

	reg[7:0] dbgHostSda = 0;
	reg[7:0] dbgPowerSda = 0;
	always @ (posedge hostSdaOutEn) dbgHostSda <= dbgHostSda + 1;
	always @ (posedge powerSdaOutEn) dbgPowerSda <= dbgPowerSda + 1;

	// Link all I2C buses together
	wire sdaLow1, sdaLow2, sdaLow3;
	assign hostSdaOutEn = |{proxySdaLow, sdaLow1, sdaLow2, sdaLow3};
	
	// 1-bit register controlling LED
	reg ledState = 1'b1;
	wire[7:0] ledOut;
	always @ (ledOut) ledState <= ledOut[0];
	assign led1 = ledState && clk_4hz;
	twi_slave2 #(.ADDR(7'h33)) twi1(
		.scl(io_scl), .sda(hostSdaIn), .sdaLow(sdaLow1),
		.dataOut({7'b0, ledState}), .dataIn(ledOut)
	); 

	// Constant 0x88 output register
	twi_slave2 #(.ADDR(7'h44)) twi2(
		.scl(io_scl), .sda(hostSdaIn), .sdaLow(sdaLow2),
		.dataOut(8'h88)
	); 
	
	
	// Simple R/W register
	reg[7:0] mem = 8'h55;
	wire[7:0] newMem;
	always @ (newMem) mem <= newMem;
	twi_slave2 #(.ADDR(7'h55)) twi3(
		.scl(io_scl), .sda(hostSdaIn), .sdaLow(sdaLow3),
		.dataOut(mem), .dataIn(newMem)
	); 

	// Debug signals
	assign gpio_20 = io_power_scl;
	assign gpio_19 = hostSdaIn;
	assign gpio_21 = powerSdaIn;
	assign gpio_18 = !hostSdaOutEn;

	// Debugging via UART
	wire clk_uart_9600;
	clkdiv #(.DIV(16000000 / 9600)) uart_clk_div(
		.clkIn(clk_16mhz),
		.clkOut(clk_uart_9600)
	);
	uart_tx_stream #(.N(60), .WAIT(9600 / 5)) uart_tx1 (
		.clk(clk_uart_9600), .tx(io_uart_tx),
		.dataStream({
			"[FPGA] hostSda=", hex8(dbgHostSda), 
			" powerSda=", hex8(dbgPowerSda), 
			8'h0D})
	);
	//wire uart_clock_g;
        //SB_GB gb1 (
 	//  .USER_SIGNAL_TO_GLOBAL_BUFFER(uart_clk),
	//  .GLOBAL_BUFFER_OUTPUT(uart_clock_g)
	//);
	//assign io_power_scl = uart_clk_g;

        // */
endmodule
