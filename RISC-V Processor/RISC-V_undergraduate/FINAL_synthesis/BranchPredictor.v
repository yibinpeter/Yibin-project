module BranchPredictor(
	input clk,
	input rstn,
	input prev_taken,
	input [6:0] exmemop,
	output should_take
);

localparam STRONGTAKEN    = 2'b11,
		   WEAKTAKEN      = 2'b10,
		   WEAKNOTTAKEN   = 2'b01,
		   STRONGNOTTAKEN = 2'b00,
		   B_I            = 7'b110_0011;

reg [1:0] state, state_c;

assign should_take = state[1]; // 1 indicates two taken states, 0 indicates two not taken states

always @(posedge clk) begin
	state <= (exmemop == B_I) ? state_c : state;
	if (!rstn) begin
		state <= STRONGTAKEN;
	end
end

always @(state or prev_taken) begin
	case(state)
		STRONGTAKEN   : state_c = prev_taken ? STRONGTAKEN  : WEAKTAKEN;
		WEAKTAKEN     : state_c = prev_taken ? STRONGTAKEN  : WEAKNOTTAKEN;
		WEAKNOTTAKEN  : state_c = prev_taken ? WEAKTAKEN    : STRONGNOTTAKEN;
		STRONGNOTTAKEN: state_c = prev_taken ? WEAKNOTTAKEN : STRONGNOTTAKEN;
		default: state_c = STRONGTAKEN;
	endcase
end

endmodule
