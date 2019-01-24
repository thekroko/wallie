module clkdiv(
		input clkIn,
		output reg clkOut = 1'b0
	);

	parameter DIV = 2;
	localparam RDIV = DIV / 2;

        reg[$clog2(RDIV):1] counter = 0;

        always @ (posedge clkIn) begin
                if (counter >= RDIV-1) begin
                        clkOut <= ~clkOut;
                        counter <= 0;
                end
                else
                        counter <= counter + 1;
        end
endmodule
