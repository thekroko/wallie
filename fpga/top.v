`include "prescaler.v"
`include "twi_slave2.v"
`include "twi_proxy.v"
`include "uart_tx.v"
`include "uart_rx.v"
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
	input pmod1_0,
	input pmod1_1,
	input pmod1_6,
	input pmod1_7,
	output gpio_19,
	// Debugging
	output io_uart_tx,
	output pmod3_0,
	output pmod3_1
);
	// Clock Generator
	wire clk_14mhz, pll_locked;
`ifdef TESTBENCH
	assign clk_14mhz = clk_100mhz, pll_locked = 1;
`else
	SB_PLL40_PAD #(
		.FEEDBACK_PATH("SIMPLE"),
		.DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
		.DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
		.PLLOUT_SELECT("GENCLK"),
		.FDA_FEEDBACK(4'b1111),
		.FDA_RELATIVE(4'b1111),
		//  Fin=100, Fout=14.7456;
		.DIVR(4'b1000),		// DIVR =  3
		.DIVF(7'b1010100),	// DIVF = 40
		.DIVQ(3'b110),		// DIVQ =  6
		.FILTER_RANGE(3'b001)	// FILTER_RANGE = 2

	) pll (
		.PACKAGEPIN   (clk_100mhz),
		.PLLOUTGLOBAL (clk_14mhz ),
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
	prescaler #(.bits(21)) ps1(.clk_in(clk_14mhz), .clk_out(clk_16hz));
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
		.clk(clk_14mhz),
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
	localparam MODE_AI = 8'd2;

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
			MODE_AI: led1 <= clk_16hz;
		endcase
	end


	// Touch sensors
	wire ioTouchLeftIn, ioTouchRightIn;
	SB_IO #(
		.PIN_TYPE(6'b1010_01),
		.PULLUP(1'b1)
	) ioTouchLeft (
		.PACKAGE_PIN(pmod1_6),
		.OUTPUT_ENABLE(1'b0),
		.D_OUT_0(1'b0),
		.D_IN_0(ioTouchLeftIn)
        );
	SB_IO #(
		.PIN_TYPE(6'b1010_01),
		.PULLUP(1'b1)
	) ioTouchRight (
		.PACKAGE_PIN(pmod1_7),
		.OUTPUT_ENABLE(1'b0),
		.D_OUT_0(1'b0),
		.D_IN_0(ioTouchRightIn)
        );
	wire leftPressed = !ioTouchLeftIn;
	wire rightPressed = !ioTouchRightIn;

	// UART Clks
	wire clk_uart_115200;
	//prescaler #(.bits(7)) uart_lidar_prescaler(
	//	.clk_in(clk_14mhz),
	//	.clk_out(clk_uart_115200)
	//);
	clkdiv #(.DIV(128)) uart_lidar_clk_div(
		.clkIn(clk_14mhz),
		.clkOut(clk_uart_115200)
	);

	// Lidar
	wire[9*8:1] lidarPacket;
	wire lidarByteClk;
        uart_rx_buffer #(.N(9)) lidar_uart(
		.uartClk(clk_uart_115200),
		.rx(pmod1_1),
		.buffer(lidarPacket),
		.byteClk(lidarByteClk)
	);
	
	wire[7:0] lidarHeader1 = lidarPacket[9*8:8*8+1];
	wire[7:0] lidarHeader2 = lidarPacket[8*8:7*8+1];
	wire[7:0] lidarDistL = lidarPacket[7*8:6*8+1];
	wire[7:0] lidarDistH = lidarPacket[6*8:5*8+1];
	wire[7:0] lidarStrL = lidarPacket[5*8:4*8+1];
	wire[7:0] lidarStrH = lidarPacket[4*8:3*8+1];
	wire[7:0] lidarReserved = lidarPacket[3*8:2*8+1];
	wire[7:0] lidarQual = lidarPacket[2*8:1*8+1];
	wire[7:0] lidarChecksum = lidarPacket[1*8:0*8+1];

	wire[7:0] calculatedLidarChecksum = lidarHeader1 + lidarHeader2 + lidarDistL + lidarDistH + lidarStrL + lidarStrH + lidarReserved + lidarQual;

	wire isValidLidarPacket = (lidarHeader1 == 8'h59) && (lidarHeader2 == 8'h59) && (lidarChecksum == calculatedLidarChecksum);

	reg[16:1] lidarDist = 0;
	always @ (posedge isValidLidarPacket) begin
		lidarDist <= {lidarDistH, lidarDistL};
	end

	// Beeper
	reg beeperEnabled = 1'b0;
	reg[7:0] beeperMax = 8'd0; // << controlled by mode
	reg[7:0] beeperCur = 8'd0;
	reg beeperAudio = 1'b0;

	reg[7:0] lBeeperMax = 8'd0;

	wire clk_audio;
     	clkdiv #(.DIV(14_745_600 / 22_000)) audio_clk_div(
		.clkIn(clk_14mhz),
		.clkOut(clk_audio)
	);

	always @ (posedge clk_audio) begin
		if (beeperCur == 0) begin
			beeperAudio <= ~beeperAudio;
			lBeeperMax <= beeperMax;
		end
		beeperCur <= (beeperCur >= lBeeperMax) ? 8'd0 : beeperCur + 1;
	end

	assign gpio_19 = beeperEnabled ? beeperAudio : 1'b0;

	always @* begin
		if (leftPressed) {beeperEnabled, beeperMax} <= {1'b1, 8'd50};
		else if (rightPressed) {beeperEnabled, beeperMax} <= {1'b1, 8'd20};
		else if (lidarDist < 16'h0020) {beeperEnabled, beeperMax} <= {1'b1, 8'd36};
		else if (mode == MODE_AI) {beeperEnabled, beeperMax} <= {clk_4hz, 8'd90};
		else beeperEnabled <= 1'b0;
	end


	// Motor Driver
	signed reg[7:0] motorSpeedA = 0;
	signed reg[7:0] motorSpeedB = 0;
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
		.clk_16mhz(clk_14mhz)
	);
	
	// TWI Speed 16-bit register
	wire[7:0] twiSpeedAddr;
	wire[7:0] twiSpeedOut;
	wire[7:0] twiSpeedIn;
	signed reg[7:0] twiMotorSpeedA = 0;
	signed reg[7:0] twiMotorSpeedB = 0;
	wire twiSpeedInClk;
	wire twiSpeedUpdateTick;
	twi_slave2 #(.ADDR(7'h34)) twiSpeed(
		.scl(io_scl), .sda(hostSdaIn), .sdaLow(sdaLowSpeed),
		.addr(twiSpeedAddr),
		.dataOut(twiSpeedOut), .dataIn(twiSpeedIn), .dataInClk(twiSpeedInClk)
	); 

	always @(posedge twiSpeedInClk) begin
		case (twiSpeedAddr)
			8'h00: twiMotorSpeedA <= twiSpeedIn;
			8'h01: {twiMotorSpeedB, twiSpeedUpdateTick} <= {twiSpeedIn, ~twiSpeedUpdateTick};
		endcase
	end

	always @* begin
		case (twiSpeedAddr)
			default: twiSpeedOut <= 8'hFF;
			8'h00: twiSpeedOut <= twiMotorSpeedA;
			8'h01: twiSpeedOut <= twiMotorSpeedB;
		endcase
	end

	// AI
	signed reg[7:0] aiMotorLeft, aiMotorRight;
	reg aiUpdateTick = 1'b0;
	reg backingOff = 1'b0;
	reg colLeft = 1'b0;
	reg colRight = 1'b0;
	reg[22:0] backoffCounter = 0;
	reg[22:0] turnCounter = 0;
	reg turnRequested = 0;
	reg isTurning = 0;
	reg currentTurnDir = 0;

	signed wire[7:0] aiFwdSpeed = 44;
	signed wire[7:0] aiTurnSpeed = 44;
	wire nextTurnDir;
	reg[15*8:1] aiDebug = "$init";
	assign nextTurnDir = ^lidarDist;

	always @(posedge clk_14mhz) begin
		// Check immediate collisions
		if (leftPressed) {colLeft, backoffCounter} <= {1'b1, 23'd0};
		if (rightPressed) {colRight, backoffCounter} <= {1'b1, 23'd0};	

		if (colLeft || colRight) begin
			aiDebug <= "colLR";
			// Back off for a while
			if (backoffCounter < 8388607) begin
				aiMotorLeft <= -aiFwdSpeed;
				aiMotorRight <= -aiFwdSpeed;
				aiUpdateTick <= ~aiUpdateTick;
				if (!leftPressed && !rightPressed)
					backoffCounter <= backoffCounter + 1;
			end
			else
				{colLeft, colRight, turnRequested} <= 3'b001;
		end
		else if (!isTurning && (turnRequested || lidarDist < 25)) begin
			aiDebug <= "initTurn";
			turnRequested <= 1'b0;
			isTurning <= 1'b1;
			currentTurnDir <= nextTurnDir;
			turnCounter <= 23'd8_000_000;
		end
		else if (isTurning) begin
			aiDebug <= "Turning";
			turnRequested <= 1'b0;
			if (turnCounter == 0) begin
				isTurning <= 1'b0;
				aiMotorLeft <= 0;
				aiMotorRight <= 0;
			end
			else begin
				turnCounter <= turnCounter - 1;
				aiUpdateTick <= ~aiUpdateTick;
				if (currentTurnDir) begin
					aiMotorLeft <= aiTurnSpeed;
					aiMotorRight <= -aiTurnSpeed;
				end
				else begin
					aiMotorLeft <= -aiTurnSpeed;
					aiMotorRight <= aiTurnSpeed;
				end
			end
		end
		else begin
			aiDebug <= "FWD";
			aiMotorLeft <= aiFwdSpeed;
			aiMotorRight <= aiFwdSpeed;
			aiUpdateTick <= ~aiUpdateTick;
		end
		
	end

	// Mode-based actions..
	always @* begin
		case (mode)
			default: {motorSpeedA, motorSpeedB} <= 16'h0;
			MODE_RC: {motorSpeedA, motorSpeedB, speedUpdateTick} <= {twiMotorSpeedA, twiMotorSpeedB, twiSpeedUpdateTick};
			MODE_AI: {motorSpeedA, motorSpeedB, speedUpdateTick} <= {aiMotorLeft, aiMotorRight, aiUpdateTick};
		endcase
	end

	// ---------------------------------------------------------------
	// Debug signals
	assign pmod3_0 = pmod1_1;
	assign pmod3_1 = lidarByteClk;

	// Debugging via UART
	/*wire clk_uart_9600;
	clkdiv #(.DIV(14_745_600 / 9600)) uart_dbg_clk_div(
		.clkIn(clk_14mhz),
		.clkOut(clk_uart_9600)
	);*/
	uart_tx_stream #(.N(130), .WAIT(115200 / 10)) uart_tx1 (
		.clk(clk_uart_115200), .tx(io_uart_tx),
		.dataStream({
			"[FPGA]", 
			" power=", hex8(dbgPowerSda), 
			" spdA=", hex8(motorSpeedA), 
			" spdB=", hex8(motorSpeedB), 
			" spdT=", speedUpdateTick ? "Y" : "N",
			" aiL=", hex8(aiMotorLeft), 
			" aiD=", aiDebug, 
			" lr=", leftPressed ? "L" : "_", rightPressed ? "R" : "_",
		        " lidar=", hex16(lidarDist),
			"      ",	
			8'h0D})
	);
	// */
endmodule
