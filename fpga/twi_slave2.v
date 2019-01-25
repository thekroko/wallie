// Prescaler that slows down the incoming clock by a specified value
module twi_slave2(
		// Outside I/Os
		input scl,
		input sda,
		input rst,
		output sdaLow,

		// Internal wiring
		output [7:0] addr,
		output reg [7:0] dataIn,
		output dataInClk,
		input [7:0] dataOut 
	);
	parameter ADDR = 7'h11;

	// From: https://dlbeer.co.nz/articles/i2c.html

	// Start Detector
	reg  start_detect;
	reg  start_resetter;
	wire start_rst = rst | start_resetter;

	always @ (posedge start_rst or negedge sda)
	begin
		if (start_rst)
			start_detect <= 1'b0;
		else
			start_detect <= scl;
	end

	always @ (posedge rst or posedge scl)
	begin
		if (rst)
			start_resetter <= 1'b0;
		else
			start_resetter <= start_detect;
	end

	// Stop Detector
	reg             stop_detect;
	reg             stop_resetter;
	wire            stop_rst = rst | stop_resetter;

	always @ (posedge stop_rst or posedge sda)
	begin   
		if (stop_rst)
			stop_detect <= 1'b0;
		else
			stop_detect <= scl;
	end

	always @ (posedge rst or posedge scl)
	begin   
	if (rst)
		stop_resetter <= 1'b0;
	else
		stop_resetter <= stop_detect;
	end	 

	// Latched Inputs
	reg [3:0] bit_counter;

	wire lsb_bit = (bit_counter == 4'h7) && !start_detect;
	wire ack_bit = (bit_counter == 4'h8) && !start_detect;

	always @ (negedge scl)
	begin
        	if (ack_bit || start_detect)
               		bit_counter <= 4'h0;
        	else
                	bit_counter <= bit_counter + 4'h1;
	end

	reg [7:0] input_shift;
	wire address_detect = (input_shift[7:1] == ADDR);
	wire read_write_bit = input_shift[0];

	always @ (posedge scl)
        	if (!ack_bit)
                	input_shift <= {input_shift[6:0], sda};

	reg master_ack;
	always @ (posedge scl)
        	if (ack_bit)
                	master_ack <= ~sda;

        // State Machine
	parameter [2:0] STATE_IDLE      = 3'h0,
		STATE_DEV_ADDR  = 3'h1,
		STATE_READ      = 3'h2,
		STATE_IDX_PTR   = 3'h3,
		STATE_WRITE     = 3'h4;

	reg [2:0] state;
	wire  write_strobe = (state == STATE_WRITE) && ack_bit;

	always @ (posedge rst or negedge scl)
	begin
		if (rst)
			state <= STATE_IDLE;
		else if (start_detect)
			state <= STATE_DEV_ADDR;
		else if (ack_bit)
		begin
			case (state)
				STATE_IDLE:
					state <= STATE_IDLE;

				STATE_DEV_ADDR:
					if (!address_detect)
						state <= STATE_IDLE;
					else if (read_write_bit)
						state <= STATE_READ;
					else
						state <= STATE_IDX_PTR;

				STATE_READ:
					if (master_ack)
						state <= STATE_READ;
					else
						state <= STATE_IDLE;

				STATE_IDX_PTR:
					state <= STATE_WRITE;

				STATE_WRITE:
					state <= STATE_WRITE;
			endcase
		end
	end

 	// Register Transfers
	reg[7:0] index_pointer = 8'h0;
	assign addr = index_pointer;
	always @ (posedge rst or negedge scl)
	begin
		if (rst)
			index_pointer <= 8'h00;
		else if (stop_detect)
			index_pointer <= 8'h00;
		else if (ack_bit)
		begin
			if (state == STATE_IDX_PTR)
				index_pointer <= input_shift;
			else
				index_pointer <= index_pointer + 8'h01;
		end
	end

	always @ (posedge rst or negedge scl) // Register Writes
	begin
		if (rst)
			dataIn <= 8'h00;
		else if (write_strobe)
			dataIn <= input_shift;
	end

	assign dataInClk = write_strobe;

        reg [7:0] output_shift;

	always @ (negedge scl) begin // Register reads  
		if (lsb_bit) begin   
			output_shift <= dataOut;
		end
		else
			output_shift <= {output_shift[6:0], 1'b0};
	end

	// Output Driver
	reg output_control = 1'b1;
	assign sdaLow = !output_control;

	always @ (posedge rst or negedge scl)
	begin   
	if (rst)
		output_control <= 1'b1;
	else if (start_detect)
		output_control <= 1'b1;
	else if (lsb_bit)
	begin   
	output_control <=
		!(((state == STATE_DEV_ADDR) && address_detect) ||
		(state == STATE_IDX_PTR) ||
		(state == STATE_WRITE));
	end
	else if (ack_bit)
	begin
		// Deliver the first bit of the next slave-to-master
		// transfer, if applicable.
		if (((state == STATE_READ) && master_ack) ||
			((state == STATE_DEV_ADDR) &&
			address_detect && read_write_bit))
			output_control <= output_shift[7];
			else
				output_control <= 1'b1;
		end
		else if (state == STATE_READ)
			output_control <= output_shift[7];
		else
			output_control <= 1'b1;
	end

endmodule
