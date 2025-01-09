module RAM 
#(parameter DATA_WIDTH=32, parameter SIZE = 6, parameter FILE_NAME="")
(	
	input             clk,
	input             wr_en,
	input      [31:0] data_in,
	output reg [31:0] data_out,
	input      [31:0] addr_wr,
	input      [31:0] addr_rd
);
	
	// Declare the RAM variable
	reg [0:DATA_WIDTH-1] mem [0:SIZE-1] /* synthesis ramstyle = "no_rw_check, M10K" */;
	
	integer i;
	
	initial begin
		if (FILE_NAME != "") $readmemb(FILE_NAME, mem);
	end

	always @ (posedge clk) begin
		if (wr_en == 1'b1) begin
			mem[addr_wr] <= data_in;
		end
      data_out <= mem[addr_rd];
	end
	
endmodule
