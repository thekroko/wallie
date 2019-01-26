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

  always @(posedge clk_16mhz) clk_8mhz <= ~clk_8mhz;
  always @(posedge clk_8mhz) pwmTicker <= pwmTicker+1;
  always @(posedge clk_16mhz) begin
	  if (lastAliveStrobe != aliveStrobe) begin
		  lastAliveStrobe <= aliveStrobe;
		  timeoutTicker <= -1;
	  end
	  else if (timeoutTicker != 0)
		  timeoutTicker <= timeoutTicker - 1;
  end

  assign isAlive = (timeoutTicker != 0);
  assign ticksA = speedA < 0 ? ~speedA[6:0] : speedA[6:0];
  assign ticksB = speedB < 0 ? ~speedB[6:0] : speedB[6:0];
  
  // Outputs:
  assign active = isAlive && (speedA != 0 || speedB != 0);
  assign aIn = (speedA == 0 ? 2'b00 : (speedA > 0 ? 2'b01 : 2'b10));
  assign bIn = (speedB == 0 ? 2'b00 : (speedB > 0 ? 2'b01 : 2'b10));
  assign pwmA = pwmTicker < ticksA;
  assign pwmB = pwmTicker < ticksB;
endmodule
