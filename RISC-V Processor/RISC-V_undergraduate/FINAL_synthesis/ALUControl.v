module ALUControl (ALUOp, FuncCode, ALUCtl);
    
    input [1:0] ALUOp;
    input [9:0] FuncCode; // FuncCode = {funct7, funct3}
    output reg [3:0] ALUCtl;

    always @( ALUOp or FuncCode ) begin
        casex (ALUOp)
            2'b00: ALUCtl = 4'b0010; // addi
            2'b01: ALUCtl = 4'b0110;
            2'b1x: begin
                casex (FuncCode)
					10'b0000001_000: ALUCtl = 4'b1000; // mul
                    10'bx0xxxxx_000: ALUCtl = 4'b0010; // add
                    10'bx1xxxxx_000: ALUCtl = 4'b0110; // subtract
                    10'bx0xxxxx_111: ALUCtl = 4'b0000; // and
                    10'bx0xxxxx_110: ALUCtl = 4'b0001; // or
                    10'bxxxxxxx_100: ALUCtl = 4'b0111; // blt
                    default: ALUCtl = 4'b0000;
                endcase
            end
            default: ALUCtl = 4'b0000;
        endcase 
    end

endmodule
