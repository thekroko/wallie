module rb_pol_110(
	output pwmA,
	output pwmB,
	output[1:0] aIn,
	output[1:0] bIn,
        output active,
	
	input signed [7:0] speedA,
	input signed [7:0] speedB,
	input aliveStrobe,
	input clk_16mhz
  );


  reg[6:0] pwmTicker = 0;
  reg[23:1] timeoutTicker = 0;
  reg lastAliveStrobe = 0;
  reg clk_8mhz = 0;

  wire isAlive;
  wire[6:0] ticksA, ticksB;

  reg[7:0] lspeedA = 0;
  reg[7:0] lspeedB = 0;

  always @(posedge clk_16mhz) clk_8mhz <= ~clk_8mhz;
  always @(posedge clk_8mhz) begin
	  pwmTicker <= pwmTicker+1;
	  if (pwmTicker + 7'd1 == 7'd0) begin
		  lspeedA <= speedA;
		  lspeedB <= speedB;
	  end
  end
  always @(posedge clk_16mhz) begin
	  if (lastAliveStrobe != aliveStrobe) begin
		  lastAliveStrobe <= aliveStrobe;
		  timeoutTicker <= -1;
	  end
	  else if (timeoutTicker != 0)
		  timeoutTicker <= timeoutTicker - 1;
  end

  assign isAlive = (timeoutTicker != 0);
  assign ticksA = lspeedA[7] ? (~lspeedA[6:0]+7'b1) : lspeedA[6:0];
  assign ticksB = lspeedB[7] ? (~lspeedB[6:0]+7'b1) : lspeedB[6:0];
  
  // Outputs:
  assign active = isAlive && (lspeedA != 0 || lspeedB != 0);
  assign aIn = (lspeedA == 0 ? 2'b00 : (lspeedA[7] ? 2'b01 : 2'b10));
  assign bIn = (lspeedB == 0 ? 2'b00 : (lspeedB[7] ? 2'b01 : 2'b10));
  assign pwmA = pwmTicker < ticksA;
  assign pwmB = pwmTicker < ticksB;
endmodule
