`ifdef TESTBENCH
module uart_format();
`endif
  function [8:1] hex;
    input[4:1] in;
    hex = in < 10 ? ("0" + in) : ( "A" + (in - 10)); 
  endfunction

  function [32:1] hex8;
    input[8:1] in;
    hex8 = {"0x", hex(in[8:5]), hex(in[4:1])};
  endfunction

  function [48:1] hex16;
    input[16:1] in;
    hex16 = {"0x", hex(in[16:13]), hex(in[12:9]), hex(in[8:5]), hex(in[4:1])};
  endfunction
`ifdef TESTBENCH
endmodule
`endif

module uart_tx_stream(
	input clk,
	output wire tx,
	output eol,
	input[(8*N)-1:0] dataStream
);
	parameter N = 32;
	parameter WIDTH = $clog2(N);
	parameter WAIT = 30;
	parameter WIDTH_WAIT = $clog2(WAIT);

	wire nextWord;
	wire[7:0] word;
	reg[WIDTH:1] counter = 0;
	wire hold;
	uart_tx UART_INST (.clk(clk), .tx(tx), .nextWord(nextWord), .wordIn(word), .hold(hold));

	reg[WIDTH_WAIT:1] holdCounter = 0;

	assign eol = counter >= N;
	assign word =  dataStream >> 8*(N-1-counter);
	always @ (posedge nextWord) begin
		if (eol) counter <= 0;
		else counter <= counter + 1;
	end
	always @ (posedge clk) begin
		if (holdCounter > 0) holdCounter <= holdCounter - 1;
		else if (eol) holdCounter <= WAIT;
	end
	assign hold = holdCounter > 0;
endmodule

module uart_tx( // no parity, 1 stop bit
	input clk,
	input hold,
	output tx,
	output nextWord,
	input[7:0] wordIn
);
	parameter STOP_BITS = 1;

	localparam STATE_STOP_BIT	= 2'b00;
	localparam STATE_START_BIT 	= 2'b01;
	localparam STATE_DATA 		= 2'b10;
	reg[1:0]  state = STATE_STOP_BIT;

	reg[7:0] bufferedPacket;
	reg[2:0] dataCounter = 3'd0;

	reg txState = 1'b1;
	assign tx = bufferedPacket == 8'h0 ? 1'b1 : txState;

	assign nextWord = (state == STATE_STOP_BIT);

	always @* case (state)
		default: txState <= 1'b1;
		STATE_START_BIT: txState <= 1'b0;
		STATE_DATA: txState <= bufferedPacket[dataCounter];
		STATE_STOP_BIT: txState <= 1'b1;
	endcase
	
	always @ (posedge clk) begin
		casez (state)
			STATE_STOP_BIT:
				if (dataCounter > 0)
					dataCounter <= dataCounter - 1;
				else if (!hold) 
					{state, bufferedPacket} <= {STATE_START_BIT, wordIn};
			STATE_START_BIT: {state, dataCounter} <= {STATE_DATA, 3'd0};
			STATE_DATA:
				if (dataCounter == 3'b111)
					{state, dataCounter} <= {STATE_STOP_BIT, STOP_BITS - 3'd1};
				else
					dataCounter <= dataCounter + 3'd1;

		endcase
	end
endmodule	
