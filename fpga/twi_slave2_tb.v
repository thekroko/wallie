module twi_slave2_tb();
  reg scl = 1'b1;
  reg sdaIn = 1'b1;
  wire sdaOutEn;
  wire effectiveSda = sdaOutEn ? 1'b0 : sdaIn;

  parameter ADDR = 7'b1000100;
  twi_slave2 #(.ADDR(ADDR)) INST(
	  .scl(scl),
	  .sda(effectiveSda),
	  .sdaLow(sdaOutEn),
	  .dataOut(8'b10101010)
  );

  initial begin
	  $dumpfile("twi_slave2_tb.vcd");
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

	  #20;

          // Addr (one bit off
	  #2 scl = 0; #1 sdaIn = ADDR[6]; #1 scl = 1;
	  #2 scl = 0; #1 sdaIn = ADDR[5]; #1 scl = 1;
	  #2 scl = 0; #1 sdaIn = ADDR[4]; #1 scl = 1;
	  #2 scl = 0; #1 sdaIn = ADDR[3]; #1 scl = 1;
	  #2 scl = 0; #1 sdaIn = ADDR[2]; #1 scl = 1;
	  #2 scl = 0; #1 sdaIn = ADDR[1]; #1 scl = 1;
	  #2 scl = 0; #1 sdaIn = 1'b1; #1 scl = 1;
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


	  #9000 $finish;
  end
endmodule

module twi_slave2_tb2();
  wire scl;
  wire sda;
  wire sdaOutEn;
  wire wentWrong;

  twi_slave2 #(.ADDR(7'b1010101)) INST2(
	  .scl(scl),
	  .sda(sda),
	  .sdaLow(sdaOutEn),
	  .dataOut(8'b10101010)
  );

  reg[$clog2(182):0] counter = 0;
  reg[7:0] rec;
  reg regClk = 1'b0;

  assign scl = rec[0];
  assign (weak1, weak0) sda = rec[1];
  assign wentWrong = rec[3];

  always @* #1 regClk <= !regClk;
  always @(posedge regClk) counter <= counter+1;
  always @* begin
	  case (counter)
		  0: rec <= 8'b11111000; // 1.8041805625
		  1: rec <= 8'b11111100; // 1.80418125
		  2: rec <= 8'b11111110; // 1.8041813125
		  3: rec <= 8'b11111111; // 1.804185625
		  4: rec <= 8'b11111110; // 1.8041905625
		  5: rec <= 8'b11111000; // 1.8041911875
		  6: rec <= 8'b11111001; // 1.804195625
		  7: rec <= 8'b11111000; // 1.8042005625
		  8: rec <= 8'b11111100; // 1.804203125
		  9: rec <= 8'b11111110; // 1.8042031875
		  10: rec <= 8'b11111111; // 1.804205625
		  11: rec <= 8'b11111110; // 1.8042105625
		  12: rec <= 8'b11111000; // 1.8042111875
		  13: rec <= 8'b11111001; // 1.804215625
		  14: rec <= 8'b11111101; // 1.804220625
		  15: rec <= 8'b11111111; // 1.8042206875
		  16: rec <= 8'b11111001; // 1.8043410625
		  17: rec <= 8'b11111000; // 1.8043460625
		  18: rec <= 8'b11111001; // 1.8043560625
		  19: rec <= 8'b11111000; // 1.8043610625
		  20: rec <= 8'b11111001; // 1.8043660625
		  21: rec <= 8'b11111000; // 1.8043710625
		  22: rec <= 8'b11111100; // 1.8043716875
		  23: rec <= 8'b11111110; // 1.8043718125
		  24: rec <= 8'b11111111; // 1.8043760625
		  25: rec <= 8'b11111110; // 1.8043810625
		  26: rec <= 8'b11111000; // 1.8043816875
		  27: rec <= 8'b11111001; // 1.8043860625
		  28: rec <= 8'b11111000; // 1.8043910625
		  29: rec <= 8'b11111001; // 1.8043960625
		  30: rec <= 8'b11111000; // 1.8044010625
		  31: rec <= 8'b11111100; // 1.8044016875
		  32: rec <= 8'b11111110; // 1.8044018125
		  33: rec <= 8'b11111111; // 1.8044060625
		  34: rec <= 8'b11111110; // 1.8044110625
		  35: rec <= 8'b11111000; // 1.8044116875
		  36: rec <= 8'b11111001; // 1.8044160625
		  37: rec <= 8'b11111000; // 1.8044210625
		  38: rec <= 8'b11111001; // 1.8044260625
		  39: rec <= 8'b11111000; // 1.8044310625
		  40: rec <= 8'b11111100; // 1.8044335625
		  41: rec <= 8'b11111110; // 1.8044336875
		  42: rec <= 8'b11111111; // 1.8044360625
		  43: rec <= 8'b11111110; // 1.8044410625
		  44: rec <= 8'b11111000; // 1.8044416875
		  45: rec <= 8'b11111001; // 1.8044460625
		  46: rec <= 8'b11111101; // 1.8044510625
		  47: rec <= 8'b11111111; // 1.8044511875
		  48: rec <= 8'b11111011; // 1.804575125
		  49: rec <= 8'b11111001; // 1.8045751875
		  50: rec <= 8'b11111000; // 1.804580125
		  51: rec <= 8'b11111001; // 1.8045901875
		  52: rec <= 8'b11111000; // 1.804595125
		  53: rec <= 8'b11111001; // 1.8046001875
		  54: rec <= 8'b11111000; // 1.804605125
		  55: rec <= 8'b11111100; // 1.8046058125
		  56: rec <= 8'b11111110; // 1.804605875
		  57: rec <= 8'b11111111; // 1.8046101875
		  58: rec <= 8'b11111110; // 1.8046151875
		  59: rec <= 8'b11111000; // 1.8046158125
		  60: rec <= 8'b11111001; // 1.8046201875
		  61: rec <= 8'b11111000; // 1.8046251875
		  62: rec <= 8'b11111001; // 1.8046301875
		  63: rec <= 8'b11111000; // 1.8046351875
		  64: rec <= 8'b11111100; // 1.8046358125
		  65: rec <= 8'b11111110; // 1.804635875
		  66: rec <= 8'b11111111; // 1.8046401875
		  67: rec <= 8'b11111110; // 1.8046451875
		  68: rec <= 8'b11111111; // 1.8046501875
		  69: rec <= 8'b11111110; // 1.8046551875
		  70: rec <= 8'b11111000; // 1.8046558125
		  71: rec <= 8'b11111001; // 1.8046601875
		  72: rec <= 8'b11111000; // 1.8046651875
		  73: rec <= 8'b11111100; // 1.8046676875
		  74: rec <= 8'b11111110; // 1.80466775
		  75: rec <= 8'b11111111; // 1.8046701875
		  76: rec <= 8'b11111110; // 1.8046751875
		  77: rec <= 8'b11111000; // 1.8046758125
		  78: rec <= 8'b11111001; // 1.8046801875
		  79: rec <= 8'b11111101; // 1.8046851875
		  80: rec <= 8'b11111111; // 1.80468525
		  81: rec <= 8'b11111001; // 1.80477925
		  82: rec <= 8'b11111000; // 1.80478425
		  83: rec <= 8'b11111001; // 1.8047943125
		  84: rec <= 8'b11111000; // 1.80479925
		  85: rec <= 8'b11111001; // 1.8048043125
		  86: rec <= 8'b11111000; // 1.80480925
		  87: rec <= 8'b11111100; // 1.8048099375
		  88: rec <= 8'b11111110; // 1.80481
		  89: rec <= 8'b11111111; // 1.8048143125
		  90: rec <= 8'b11111110; // 1.80481925
		  91: rec <= 8'b11111000; // 1.804819875
		  92: rec <= 8'b11111001; // 1.8048243125
		  93: rec <= 8'b11111000; // 1.80482925
		  94: rec <= 8'b11111100; // 1.8048299375
		  95: rec <= 8'b11111110; // 1.80483
		  96: rec <= 8'b11111111; // 1.8048343125
		  97: rec <= 8'b11111110; // 1.80483925
		  98: rec <= 8'b11111000; // 1.804839875
		  99: rec <= 8'b11111001; // 1.8048443125
		  100: rec <= 8'b11111000; // 1.80484925
		  101: rec <= 8'b11111001; // 1.8048543125
		  102: rec <= 8'b11111000; // 1.80485925
		  103: rec <= 8'b11111001; // 1.8048643125
		  104: rec <= 8'b11111000; // 1.80486925
		  105: rec <= 8'b11111100; // 1.8048718125
		  106: rec <= 8'b11111110; // 1.804871875
		  107: rec <= 8'b11111111; // 1.8048743125
		  108: rec <= 8'b11111110; // 1.80487925
		  109: rec <= 8'b11111010; // 1.804879875
		  110: rec <= 8'b11111000; // 1.8048799375
		  111: rec <= 8'b11111001; // 1.8048843125
		  112: rec <= 8'b11111101; // 1.8048893125
		  113: rec <= 8'b11111111; // 1.804889375
		  114: rec <= 8'b11111011; // 1.80497625
		  115: rec <= 8'b11111001; // 1.8049763125
		  116: rec <= 8'b11111000; // 1.8049813125
		  117: rec <= 8'b11111001; // 1.8049913125
		  118: rec <= 8'b11111000; // 1.8049963125
		  119: rec <= 8'b11111001; // 1.8050013125
		  120: rec <= 8'b11111000; // 1.8050063125
		  121: rec <= 8'b11111100; // 1.8050069375
		  122: rec <= 8'b11111110; // 1.805007
		  123: rec <= 8'b11111111; // 1.8050113125
		  124: rec <= 8'b11111110; // 1.8050163125
		  125: rec <= 8'b11111000; // 1.8050169375
		  126: rec <= 8'b11111001; // 1.8050213125
		  127: rec <= 8'b11111000; // 1.8050263125
		  128: rec <= 8'b11111100; // 1.8050269375
		  129: rec <= 8'b11111110; // 1.805027
		  130: rec <= 8'b11111111; // 1.8050313125
		  131: rec <= 8'b11111110; // 1.8050363125
		  132: rec <= 8'b11111000; // 1.8050369375
		  133: rec <= 8'b11111001; // 1.8050413125
		  134: rec <= 8'b11111000; // 1.8050463125
		  135: rec <= 8'b11111100; // 1.8050469375
		  136: rec <= 8'b11111110; // 1.805047
		  137: rec <= 8'b11111111; // 1.8050513125
		  138: rec <= 8'b11111110; // 1.8050563125
		  139: rec <= 8'b11111000; // 1.8050569375
		  140: rec <= 8'b11111001; // 1.8050613125
		  141: rec <= 8'b11111000; // 1.8050663125
		  142: rec <= 8'b11111100; // 1.8050688125
		  143: rec <= 8'b11111110; // 1.805068875
		  144: rec <= 8'b11111111; // 1.8050713125
		  145: rec <= 8'b11111110; // 1.8050763125
		  146: rec <= 8'b11111000; // 1.8050769375
		  147: rec <= 8'b11111001; // 1.8050813125
		  148: rec <= 8'b11111101; // 1.8050863125
		  149: rec <= 8'b11111111; // 1.805086375
		  150: rec <= 8'b11111001; // 1.8051785625
		  151: rec <= 8'b11110000; // 1.8051835625
		  152: rec <= 8'b11110001; // 1.8051935625
		  153: rec <= 8'b11111000; // 1.8051985625
		  154: rec <= 8'b11111001; // 1.8052035625
		  155: rec <= 8'b11111000; // 1.8052085625
		  156: rec <= 8'b11111100; // 1.8052091875
		  157: rec <= 8'b11111110; // 1.80520925
		  158: rec <= 8'b11111111; // 1.8052135625
		  159: rec <= 8'b11111110; // 1.8052185625
		  160: rec <= 8'b11111000; // 1.8052191875
		  161: rec <= 8'b11111001; // 1.8052235625
		  162: rec <= 8'b11111000; // 1.8052285625
		  163: rec <= 8'b11111100; // 1.8052291875
		  164: rec <= 8'b11111110; // 1.80522925
		  165: rec <= 8'b11111111; // 1.8052335625
		  166: rec <= 8'b11111110; // 1.8052385625
		  167: rec <= 8'b11111111; // 1.8052435625
		  168: rec <= 8'b11111110; // 1.8052485625
		  169: rec <= 8'b11111000; // 1.8052491875
		  170: rec <= 8'b11111001; // 1.8052535625
		  171: rec <= 8'b11111000; // 1.8052585625
		  172: rec <= 8'b11111001; // 1.8052635625
		  173: rec <= 8'b11111000; // 1.8052685625
		  174: rec <= 8'b11111100; // 1.8052710625
		  175: rec <= 8'b11111110; // 1.805271125
		  176: rec <= 8'b11111111; // 1.8052735625
		  177: rec <= 8'b11111110; // 1.8052785625
		  178: rec <= 8'b11111000; // 1.8052791875
		  179: rec <= 8'b11111001; // 1.8052835625
		  180: rec <= 8'b11111101; // 1.8052885625
		  181: rec <= 8'b11111111; // 1.805288625
		  182: rec <= 8'b11111001; // 1.8053798125
	  endcase
  end

endmodule


module twi_slave2_tb3();
  wire scl;
  wire sda;
  wire sdaOutEn;
  wire wentWrong;

  twi_slave2 #(.ADDR(7'b1000100)) INST2(
	  .scl(scl),
	  .sda(sda),
	  .sdaLow(sdaOutEn),
	  .dataOut(8'b10101010)
  );

  reg[7:0] rec;

  assign scl = rec[0];
  assign (weak1, weak0) sda = rec[1];
  assign wentWrong = rec[3];

  initial begin
	  #1; rec = 8'b11111000;
	  #5; rec = 8'b11111001;
	  #7; rec = 8'b11111000;
	  #4; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #4; rec = 8'b11111111;
	  #7; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111101;
	  #2; rec = 8'b11111111;
	  #122; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #7; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #6; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #7; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #7; rec = 8'b11111000;
	  #2; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #7; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #4; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #4; rec = 8'b11111111;
	  #6; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #7; rec = 8'b11111101;
	  #2; rec = 8'b11111111;
	  #162; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #7; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #7; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #7; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #7; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #2; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #6; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #6; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #7; rec = 8'b11111000;
	  #4; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #4; rec = 8'b11111111;
	  #6; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111101;
	  #2; rec = 8'b11111111;
	  #131; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #7; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #6; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #7; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #7; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #2; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #6; rec = 8'b11111110;
	  #2; rec = 8'b11111010;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #7; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #7; rec = 8'b11110000;
	  #6; rec = 8'b11110001;
	  #7; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111101;
	  #2; rec = 8'b11111111;
	  #213; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #7; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #6; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #7; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #7; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #2; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #6; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #2; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #7; rec = 8'b11110000;
	  #6; rec = 8'b11110001;
	  #6; rec = 8'b11111000;
	  #4; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #4; rec = 8'b11111111;
	  #6; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #7; rec = 8'b11111101;
	  #2; rec = 8'b11111111;
	  #125; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #7; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #7; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #7; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #2; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #7; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #6; rec = 8'b11110000;
	  #6; rec = 8'b11110001;
	  #6; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #7; rec = 8'b11111000;
	  #4; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #4; rec = 8'b11111111;
	  #6; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111101;
	  #2; rec = 8'b11111111;
	  #159; rec = 8'b11111001;
	  #7; rec = 8'b11111000;
	  #7; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #6; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #7; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #7; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #2; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #6; rec = 8'b11111110;
	  #2; rec = 8'b11110000;
	  #6; rec = 8'b11110001;
	  #6; rec = 8'b11110000;
	  #2; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #6; rec = 8'b11111110;
	  #2; rec = 8'b11111010;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #4; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #4; rec = 8'b11111111;
	  #6; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111101;
	  #2; rec = 8'b11111111;
	  #110; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #7; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #7; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #7; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #2; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #6; rec = 8'b11111111;
	  #6; rec = 8'b11110000;
	  #6; rec = 8'b11110001;
	  #6; rec = 8'b11111000;
	  #7; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #7; rec = 8'b11111000;
	  #4; rec = 8'b11111100;
	  #2; rec = 8'b11111110;
	  #4; rec = 8'b11111111;
	  #6; rec = 8'b11111110;
	  #2; rec = 8'b11111000;
	  #6; rec = 8'b11111001;
	  #6; rec = 8'b11111101;
	  #2; rec = 8'b11111111;
  end
  endmodule

module twi_slave2_tb4();
  wire scl;
  wire sda;
  wire sdaLow;
  wire wentWrong;
  wire realSda;
  assign realSda = sdaLow ? 1'b0 : sda;

  twi_slave2 #(.ADDR(7'h33)) INST2(
	  .scl(scl),
	  .sda(realSda),
	  .sdaLow(sdaLow),
	  .dataOut(8'b10101010)
  );

  reg[7:0] rec;

  assign scl = rec[0];
  assign (weak1, weak0) sda = rec[1];
  assign wentWrong = rec[3];

  initial begin
#1; rec = 8'b11111111;
#100; rec = 8'b11111001;
#7; rec = 8'b11111000;
#11; rec = 8'b11111001;
#7; rec = 8'b11111000;
#2; rec = 8'b11111100;
#2; rec = 8'b11111110;
#6; rec = 8'b11111111;
#7; rec = 8'b11111110;
#6; rec = 8'b11111111;
#7; rec = 8'b11111110;
#2; rec = 8'b11111000;
#6; rec = 8'b11111001;
#7; rec = 8'b11111000;
#7; rec = 8'b11111001;
#6; rec = 8'b11111000;
#2; rec = 8'b11111100;
#2; rec = 8'b11111110;
#6; rec = 8'b11111111;
#6; rec = 8'b11111110;
#7; rec = 8'b11111111;
#6; rec = 8'b11111110;
#7; rec = 8'b11111111;
#7; rec = 8'b11111110;
#6; rec = 8'b11111111;
#7; rec = 8'b11111110;
#2; rec = 8'b11111000;
#6; rec = 8'b11111001;
#7; rec = 8'b11111101;
#2; rec = 8'b11111111;
#100; rec = 8'b11111001;
#6; rec = 8'b11111000;
#12; rec = 8'b11111001;
#6; rec = 8'b11111000;
#2; rec = 8'b11111100;
#2; rec = 8'b11111110;
#6; rec = 8'b11111111;
#6; rec = 8'b11111110;
#6; rec = 8'b11111111;
#7; rec = 8'b11111110;
#2; rec = 8'b11111000;
#6; rec = 8'b11111001;
#7; rec = 8'b11111000;
#6; rec = 8'b11111001;
#7; rec = 8'b11111000;
#2; rec = 8'b11111100;
#2; rec = 8'b11111110;
#6; rec = 8'b11111111;
#7; rec = 8'b11111110;
#7; rec = 8'b11111111;
#6; rec = 8'b11111110;
#7; rec = 8'b11111111;
#6; rec = 8'b11111110;
#7; rec = 8'b11111111;
#6; rec = 8'b11111110;
#2; rec = 8'b11111000;
#6; rec = 8'b11111001;
#6; rec = 8'b11111101;
#2; rec = 8'b11111111;
#100; rec = 8'b11111001;
#7; rec = 8'b11111000;
#12; rec = 8'b11111001;
#6; rec = 8'b11111000;
#2; rec = 8'b11111100;
#2; rec = 8'b11111110;
#6; rec = 8'b11111111;
#6; rec = 8'b11111110;
#7; rec = 8'b11111111;
#6; rec = 8'b11111110;
#2; rec = 8'b11111000;
#6; rec = 8'b11111001;
#6; rec = 8'b11111000;
#7; rec = 8'b11111001;
#6; rec = 8'b11111000;
#2; rec = 8'b11111100;
#2; rec = 8'b11111110;
#6; rec = 8'b11111111;
#6; rec = 8'b11111110;
#7; rec = 8'b11111111;
#6; rec = 8'b11111110;
#7; rec = 8'b11111111;
#6; rec = 8'b11111110;
#7; rec = 8'b11111111;
#6; rec = 8'b11111110;
#2; rec = 8'b11111000;
#6; rec = 8'b11111001;
#6; rec = 8'b11111101;
#2; rec = 8'b11111111;	  
  end
  endmodule
