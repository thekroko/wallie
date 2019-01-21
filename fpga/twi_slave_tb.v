module twi_slave_tb();
  reg scl = 1'b1;
  reg sdaIn = 1'b1;
  wire sdaOut;  
  wire sdaOutEn;
  wire effectiveSda = sdaOutEn ? sdaOut : sdaIn;

  parameter ADDR = 7'b0111000;
  twi_slave #(.ADDR(ADDR)) INST(
	  .scl(scl),
	  .sdaIn(effectiveSda),
	  .sdaOut(sdaOut),
	  .sdaOutEn(sdaOutEn),
	  .dataOut(8'b10101010)
  );

  initial begin
	  $dumpfile("twi_slave_tb.vcd");
	  $dumpvars();

	  #10;

	  // Start bit
	  sdaIn = 0;

	  // Addr
	  #2 scl = 0; #1 sdaIn = ADDR[6]; #1 scl = 1;
	  #2 scl = 0; #1 sdaIn = ADDR[5]; #1 scl = 1;
	  #2 scl = 0; #1 sdaIn = ADDR[4]; #1 scl = 1;
	  #2 scl = 0; #1 sdaIn = ADDR[3]; #1 scl = 1;
	  #2 scl = 0; #1 sdaIn = ADDR[2]; #1 scl = 1;
	  #2 scl = 0; #1 sdaIn = ADDR[1]; #1 scl = 1;
	  #2 scl = 0; #1 sdaIn = ADDR[0]; #1 scl = 1;
	  #2 scl = 0; #1 sdaIn = 1 /* Req Data */; #1 scl = 1;

	  // Wait for Ack
	  #2 scl = 0; #2 scl = 1;

	  // See response 
	  #2 scl = 0; #10 scl = 1;
	  #2 scl = 0; #2 scl = 1;
	  #2 scl = 0; #2 scl = 1;
	  #2 scl = 0; #2 scl = 1;
	  #2 scl = 0; #2 scl = 1;
	  #2 scl = 0; #2 scl = 1;
	  #2 scl = 0; #2 scl = 1;
	  #2 scl = 0; #2 scl = 1; // NACK
	  #2 scl = 0; #2 scl = 1;
	  #2 scl = 0; #2 scl = 1;
	  #2 scl = 0; #2 scl = 1;
	  #2 scl = 0; #2 scl = 1;

	  #10 $finish;
  end
endmodule
