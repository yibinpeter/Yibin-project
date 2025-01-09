module PClogic(
	input clk,
	input rstn,
	input prev_taken,
	input [6:0] exmemop,
    input [31:0] current_pc,
    input [31:0] instr,
    output flush,
    output [31:0] predict_pc,
    output [31:0] correct_pc,
	output reg [15:0] TotalBranches, timeswrong
);

localparam B_I   = 7'b110_0011;

wire               should_take;
wire signed [31:0] PCOffset;
wire               ISBLT;
wire               take;
wire        [31:0] PC_plus_four, PC_plus_offset;

reg         [31:0] PC_plus_offset_R, PC_plus_offset_R1;
reg         [31:0] PC_plus_four_R, PC_plus_four_R1;
reg                IDEXtake, EXMEMtake;

assign PCOffset = {{22{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
assign ISBLT    = (instr[6:0] == B_I);
assign take     = ISBLT && should_take;

assign PC_plus_offset = current_pc + PCOffset - 4;
assign   PC_plus_four = current_pc + 4;

assign correct_pc = prev_taken ? PC_plus_offset_R1 : (PC_plus_four_R1 - 4);
assign predict_pc =       take ? PC_plus_offset    : PC_plus_four;

assign      flush = EXMEMtake ^ prev_taken;

BranchPredictor BP(
    .clk(clk),
    .rstn(rstn),
    .prev_taken(prev_taken),
    .exmemop(exmemop),
    .should_take(should_take)
);

always @(posedge clk) begin
	PC_plus_offset_R  <= PC_plus_offset;
	PC_plus_offset_R1 <= PC_plus_offset_R;
	PC_plus_four_R  <= PC_plus_four;
	PC_plus_four_R1 <= PC_plus_four_R;
	IDEXtake  <= take;
	EXMEMtake <= IDEXtake;
	if (!rstn) begin 
        PC_plus_offset_R  <= 0;
		PC_plus_offset_R1 <= 0;
        PC_plus_four_R  <= 0;
        PC_plus_four_R1 <= 0;
        IDEXtake   <= 0;
        EXMEMtake  <= 0;
    end 
end

always @(flush or instr) begin
	timeswrong = flush ? timeswrong + 1 : timeswrong;
	TotalBranches = ISBLT ? TotalBranches + 1 : TotalBranches;
	if (!rstn) begin
		timeswrong = 0;
		TotalBranches = 0;
	end
end

endmodule
