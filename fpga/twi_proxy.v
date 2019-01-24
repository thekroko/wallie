// Proxies I2C from one set of pins to another. Will introduce a slight
// propagation delay.
module twi_proxy(
		input clk,

		// Host wires (not to be controlled by us)
		input hostScl,
		input hostSdaIn,
		output hostSdaLow,

		// Mirror ports (we're driving these)
		output mirrorScl,
		input mirrorSdaIn,
		output mirrorSdaLow
	);

	reg hostToMirror = 1'b0;
	reg mirrorToHost = 1'b0;
	reg hostRecovery = 1'b0;
	reg mirrorRecovery = 1'b0;

	assign mirrorScl = hostScl;
	
	assign hostSdaLow = mirrorToHost;
	assign mirrorSdaLow = hostToMirror;

	always @* begin
		casez ({hostRecovery,mirrorRecovery,hostSdaIn,mirrorSdaIn,hostToMirror,mirrorToHost})
             	  // Waiting for recovery
		  6'b1?_?1_00: hostRecovery <= 0;
		  6'b?1_1?_00: mirrorRecovery <= 0;
		  // Enabling the mirror
		  6'b00_01_00: {hostToMirror, hostRecovery} <= 2'b11;
		  6'b00_10_00: {mirrorToHost, mirrorRecovery} <= 2'b11;
		  // Disabling the mirror
		  6'b??_1?_1?: hostToMirror <= 0;
		  6'b??_?1_?1: mirrorToHost <= 0;
		endcase
		/*if (!waitForRecovery) begin
			if (!hostSdaIn && !mirrorToHost)
				{hostToMirror, waitForRecovery} <= 2'b11;
			else if (!mirrorSdaIn && !hostToMirror)
				{mirrorToHost, waitForRecovery} <= 2'b11;
		end
		else begin
			if (hostSdaIn && mirrorSdaIn)
				waitForRecovery <= 0;
			if (hostSdaIn)
				hostToMirror <= 1'b0;
			if (mirrorSdaIn)
				mirrorToHost <= 1'b0;
		end;*/
	end
endmodule
