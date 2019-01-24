module twi_proxy_tb();
	reg hostScl = 1'b0;
	reg hostSdaWanted = 1'b1;
	wire effectiveHostSda, hostSdaLow;
	assign effectiveHostSda = hostSdaLow ? 1'b0 : hostSdaWanted;

	reg mirrorSdaWanted = 1'b1;
	wire mirrorScl, effectiveMirrorSda, mirrorSdaLow;
	assign effectiveMirrorSda = mirrorSdaLow ? 1'b0 : mirrorSdaWanted;

	twi_proxy INST (
		.hostScl(hostScl),
		.hostSdaIn(effectiveHostSda),
		.hostSdaLow(hostSdaLow),
		.mirrorScl(mirrorScl),
		.mirrorSdaIn(effectiveMirrorSda),
		.mirrorSdaLow(mirrorSdaLow)
	);

	always #1 hostScl <= ~hostScl;

	initial begin
		$dumpfile("twi_proxy_tb.vcd");
		$dumpvars;
		
		#5 hostSdaWanted <= 1'b0;
		#10 hostSdaWanted <= 1'b1;
		
		#20 mirrorSdaWanted <= 1'b0;
		#25 mirrorSdaWanted <= 1'b1;
		
		#30 hostSdaWanted <= 1'b0;
		#35 hostSdaWanted <= 1'b1;

		#40 mirrorSdaWanted <= 1'b0;
		#45 hostSdaWanted <= 1'b0;
		#50 mirrorSdaWanted <= 1'b1;
		#55 hostSdaWanted <= 1'b1;

		#60 $finish;
	end
endmodule
