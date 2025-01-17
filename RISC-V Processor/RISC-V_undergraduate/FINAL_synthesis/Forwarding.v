module Forwarding (
    IDEXrs1,
    IDEXrs2,
    EXMEMrd,
    MEMWBrd,
    MEMWBstall,
    Forwading_A,
    Forwading_B
);

input [4:0] IDEXrs1, IDEXrs2, EXMEMrd, MEMWBrd;
input MEMWBstall;
output reg [1:0] Forwading_A, Forwading_B;

localparam FORWARDFROMALU = 2'b01;
localparam FORWARDFROMMEM = 2'b10;
localparam NOTFORWARD     = 2'b00;

always @(*) begin

    if      ((IDEXrs1 == EXMEMrd) && (EXMEMrd != 0) && !MEMWBstall) Forwading_A = FORWARDFROMALU;
    else if ((IDEXrs1 == MEMWBrd) && (MEMWBrd != 0) && !MEMWBstall) Forwading_A = FORWARDFROMMEM;
    else Forwading_A = NOTFORWARD;
    

    if      ((IDEXrs2 == EXMEMrd) && (EXMEMrd != 0) && !MEMWBstall) Forwading_B = FORWARDFROMALU;
    else if ((IDEXrs2 == MEMWBrd) && (MEMWBrd != 0) && !MEMWBstall) Forwading_B = FORWARDFROMMEM;
    else Forwading_B = NOTFORWARD;

end

endmodule
