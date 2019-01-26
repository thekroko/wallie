`include "prescaler.v"
`include "twi_slave2.v"
`include "twi_proxy.v"
`include "uart_tx.v"
`include "clkdiv.v"
`include "rb_pol_110.v"

module top (
	input clk_100mhz,
	output led1,
	// I2C
	input io_scl,
	inout io_sda,
	output io_power_scl,
	inout io_power_sda,
	// P2 port (motor)
	output[7:0] pmod2,
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

	// Clocks
	wire clk_16hz;
	reg clk_8hz;
	reg clk_4hz;
	reg clk_2hz = 1'b0;
	prescaler #(.bits(21)) ps1(.clk_in(clk_16mhz), .clk_out(clk_16hz));
	always @ (posedge clk_16hz) clk_8hz <= ~clk_8hz;
	always @ (posedge clk_8hz) clk_4hz <= ~clk_4hz;
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

	reg[7:0] dbgHostSda = 0;
	reg[7:0] dbgPowerSda = 0;
	always @ (posedge hostSdaOutEn) dbgHostSda <= dbgHostSda + 1;
	always @ (posedge powerSdaOutEn) dbgPowerSda <= dbgPowerSda + 1;

	// Link all I2C buses together
	wire sdaLowLed, sdaLowSpeed;
	assign hostSdaOutEn = |{proxySdaLow, sdaLowMode, sdaLowSpeed};
	
	// 8-bit register controlling the mode
	reg[7:0] mode = 8'd1;
	localparam MODE_OFF = 8'd0;
	localparam MODE_RC = 8'd1;
	localparam MODE_ULTRASOUND = 8'd2;

	wire twiModeInClk;
	wire[7:0] twiModeIn;
	always @ (twiModeInClk) mode <= twiModeIn;
	twi_slave2 #(.ADDR(7'h33)) twiMode(
		.scl(io_scl), .sda(hostSdaIn), .sdaLow(sdaLowMode),
		.dataOut(twiModeIn), .dataIn(twiModeIn), .dataInClk(twiModeInClk)
	); 
	always @* begin
		case (mode)
			default: led1 <= 1'b0;
			MODE_RC: led1 <= clk_4hz;
			MODE_ULTRASOUND: led1 <= clk_16hz;
		endcase
	end

	// Motor Driver
	signed reg[7:0] motorSpeedA;
	signed reg[7:0] motorSpeedB;
	reg speedUpdateTick = 0;
	rb_pol_110 motorDriver(
		.pwmA(pmod2[2]),
		.pwmB(pmod2[7]),
		.aIn({pmod2[4], pmod2[6]}),
		.bIn({pmod2[5], pmod2[3]}),
		.active(pmod2[1]),

		.speedA(motorSpeedA),
		.speedB(motorSpeedB),
		.aliveStrobe(speedUpdateTick),
		.clk_16mhz(clk_16mhz)
	);
	
	// 16-bit register controlling motor speed (left, right)
	wire[7:0] twiSpeedAddr;
	wire[7:0] twiSpeedOut;
	wire[7:0] twiSpeedIn;
	wire twiSpeedInClk;
	twi_slave2 #(.ADDR(7'h34)) twiSpeed(
		.scl(io_scl), .sda(hostSdaIn), .sdaLow(sdaLowSpeed),
		.addr(twiSpeedAddr),
		.dataOut(twiSpeedOut), .dataIn(twiSpeedIn), .dataInClk(twiSpeedInClk)
	); 

	// Mode-based actionsb
	always @(posedge twiSpeedInClk) begin
		case (twiSpeedAddr)
			8'h00: motorSpeedA <= twiSpeedIn;
			8'h01: {motorSpeedB, speedUpdateTick} <= {twiSpeedIn, ~speedUpdateTick};
		endcase
	end

	always @* begin
		case (twiSpeedAddr)
			default: twiSpeedOut <= 8'hFF;
			8'h00: twiSpeedOut <= motorSpeedA;
			8'h01: twiSpeedOut <= motorSpeedB;
		endcase
	end



	// ---------------------------------------------------------------
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
	uart_tx_stream #(.N(100), .WAIT(9600 / 5)) uart_tx1 (
		.clk(clk_uart_9600), .tx(io_uart_tx),
		.dataStream({
			"[FPGA] hostSda=", hex8(dbgHostSda), 
			" powerSda=", hex8(dbgPowerSda), 
			" speedA=", hex8(motorSpeedA), 
			" speedB=", hex8(motorSpeedB), 
			" speedTick=", speedUpdateTick ? "Y" : "N", 
			8'h0D})
	);
	// */
endmodule
