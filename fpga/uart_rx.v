module uart_rx_buffer( // Most recent byte is in LSB
		input uartClk,
		input rx,
		output reg[N*8:1] buffer = 0,
		output byteClk
	);
	parameter N = 10;

	wire currentClk;
	wire[7:0] currentData;

	assign byteClk = ~currentClk;

	uart_rx rx_inst(
		.uartClk(uartClk),
		.rx(rx),
		.dataOut(currentData),
		.dataOutClk(currentClk)
	);

	always @ (posedge currentClk)
		buffer <= { buffer[8*(N-1):1] , currentData };
endmodule

module uart_rx(
		input uartClk,
		input rx,
		output reg[7:0] dataOut,
		output reg dataOutClk
	);

	// (1 start) + (8 data) + (1 stop) = 10 bit
	reg abandoned;
	reg startBit;
	reg[7:0] data;
	reg stopBit;
	reg resetRequested = 1'b0;
	wire hasValidStartBit = (startBit == 1'b0);
	wire hasValidStopBit = (stopBit == 1'b1);

	function [7:0] reverseBitOrder (input [7:0] data);
  		integer i;
		begin
			for (i=0; i < 8; i=i+1) begin : reverse
			    reverseBitOrder[7-i] = data[i];
		end
	end
	endfunction

	//reg[10:0] shiftData = -11'd1;
	always @(posedge uartClk) begin
		if (hasValidStartBit && hasValidStopBit) begin
			{dataOut, dataOutClk} <= {reverseBitOrder(data[7:0]), 1'b1};
			resetRequested <= 1'b1;
		end
		else
			{resetRequested, dataOutClk} <= 2'b00;
	end

	always @(negedge uartClk) begin
		if (resetRequested)
			{startBit, data [7:0], stopBit} <= {9'b111111111, rx};
		else begin
			// Shift data
			{abandoned, startBit, data[7:0], stopBit} <= {startBit, data[7:0], stopBit, rx};
		end
	end
endmodule
