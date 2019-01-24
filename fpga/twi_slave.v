// Prescaler that slows down the incoming clock by a specified value
module twi_slave (
		// Outside I/Os
		input scl,
		input sdaIn,
		output reg sdaOutEn = 1'b0,

		// Internal wiring
		input [7:0] dataOut,
		output reg [7:0] dataIn
	);
	parameter ADDR = 7'h11;

	// State registers
	reg hasValidStartBit = 1'b0;
	reg hasValidStopBit = 1'b0;
	reg stopRequested = 1'b0;
	reg stopHandled = 1'b0;
	
	reg[2:0] state  = 3'b0;
	localparam STATE_WAITING_FOR_START_BIT  = 3'b000;
	localparam STATE_READING_ADDR 		= 3'b001;
	localparam STATE_WRITING_ACK 		= 3'b010;
	localparam STATE_READING_ACK 		= 3'b011;
	localparam STATE_READ_DATA		= 3'b100;
	localparam STATE_WRITE_DATA		= 3'b101;
	reg[2:0] bitCounter = 3'd0;
	reg masterRead = 1'b0;

	reg[7:0] dataToWrite = 0; // Latched copy of data to write
	reg[7:0] dataRead = 0; // Data (WIP)
	reg addrMatches = 1'b0;

	// Start & Stop bits:
	// "The address and the data bytes are sent most significant bit
	// first. The start bit is indicated by a high-to-low transition of
	// SDA with SCL high; the stop bit is indicated by a low-to-high
	// transition of SDA with SCL high. All other transitions of SDA take
	// place with SCL low."
	always @ (negedge sdaIn) hasValidStartBit <= scl;
	always @ (posedge sdaIn) hasValidStopBit <= scl;
	always @ (posedge sdaIn) begin
		if (stopRequested)
			stopRequested <= 1'b0;
		else if (scl && state != STATE_WAITING_FOR_START_BIT) begin
			stopRequested <= ~stopRequested;
		end
	end

	// Address & Data transmission: (Read happens on pos edge)
	// "Transmitting a data bit consists of pulsing the clock line high
	// while holding the data line steady at the desired level.
	always @ (posedge scl) begin
	  if (state == STATE_WAITING_FOR_START_BIT) begin
            stopHandled <= 1'b0;
            if (hasValidStartBit) 
		{state, bitCounter, addrMatches} <= {STATE_READING_ADDR, 3'd1, sdaIn == ADDR[6]};
	    else
		{state, addrMatches} <= {STATE_WAITING_FOR_START_BIT, 1'b0};
          end
	  else if (stopRequested && !stopHandled)
		  {state, addrMatches, stopHandled} <= {STATE_WAITING_FOR_START_BIT, 1'b0, 1'b1};
	  else if (state == STATE_READING_ADDR) begin
	  	// Only proceed if addr matches (MSB first)
	    	if (bitCounter == 3'b111) begin
			if (addrMatches) begin
  	       		  state <= STATE_WRITING_ACK;
			  masterRead <= sdaIn;
			  bitCounter <= 0;
			end
			else
			  state <= STATE_WAITING_FOR_START_BIT;
	        end
		else begin
			if (sdaIn != ADDR[6 - bitCounter]) // Not our addr
	       			addrMatches <= 1'b0;
			bitCounter <= bitCounter + 1;
		end
          end
	  else if (state == STATE_WRITING_ACK) begin
	 	{state, bitCounter} <= {masterRead ? STATE_WRITE_DATA : STATE_READ_DATA, 3'd0};
		dataToWrite <= dataOut;
	  end
          else if (state == STATE_READING_ACK)
	 	{state, bitCounter} <= {sdaIn ? STATE_WAITING_FOR_START_BIT : STATE_WRITE_DATA, 3'd0};
	  else if (state == STATE_READ_DATA) begin
		dataRead[7 - bitCounter] <= sdaIn;
		if (bitCounter == 3'b111) begin
			state <= STATE_WRITING_ACK;
			dataIn <= {dataRead[7:1], sdaIn};
		end
         	else
			bitCounter <= bitCounter + 1;
          end
	  else if (state == STATE_WRITE_DATA) begin
		if (bitCounter == 3'b111)
			state <= STATE_READING_ACK;
		else
         		bitCounter <= bitCounter + 1;
          end
	  else
		state <= STATE_WAITING_FOR_START_BIT;
        end
	
	// Write happens on negative edge
	always @ (negedge scl) begin
	  if (state == STATE_WRITING_ACK)
	  	sdaOutEn <= 1'b1;
	  else if (state == STATE_WRITE_DATA)
		sdaOutEn <= ~dataToWrite[7 - bitCounter];
	  else
		sdaOutEn <= 1'b0;
	end
endmodule
