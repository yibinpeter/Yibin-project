module RISCV_top_mat_mul
#(parameter M = 9,
  parameter N = 9,
  parameter N2 = 9,
  parameter REG_WIDTH = 32,
  parameter IFILENAME = "")
(CLOCK_50, rstn, done, instr_count, clock_count, TotalBranches, timeswrong);

localparam LW             = 7'b000_0011;
localparam SW             = 7'b010_0011;
localparam BEQ            = 7'b110_0011;
localparam ALUop          = 7'b011_0011;
localparam ADDI           = 7'b001_0011;
localparam B_I            = 7'b110_0011;
localparam NOP            = 32'h0000_0000;
localparam EOF            = 32'hFFFF_FFFF;
localparam FORWARDFROMALU = 2'b01;
localparam FORWARDFROMMEM = 2'b10;

///////////////////////////////// I/O Declarations ////////////////////////////
input             CLOCK_50;
input             rstn; // external active low reset signal
output reg        done;
output reg [31:0] clock_count;
output reg [31:0] instr_count;
output [15:0] TotalBranches, timeswrong;
///////////////////////////////// END I/O Declarations ////////////////////////////


////////////////////////////////////// Internal REG/WIRE Declaration /////////////////////////////////////////////
reg          [31:0]  clock_count_n, instr_count_n;
reg [REG_WIDTH-1:0]  Regs[0:31];
reg          [31:0]  PC, PCn, IFIDPC, IDEXPC, EXMEMPC; // PCn in the next cycle PC
// reg          [31:0] PCSum;


reg [REG_WIDTH-1:0]  IDEXA, IDEXB;
reg [REG_WIDTH-1:0]  ALUOut, WBALUOut;
reg                  ISLESSTHAN; // ALU result register for branch determination
reg [REG_WIDTH-1:0]  EXMEMB, EXMEMALUout;
reg [REG_WIDTH-1:0]  D_entry;
reg [REG_WIDTH-1:0]  WBValue;
reg [REG_WIDTH-1:0]  write_back_val;

reg [REG_WIDTH-1:0]  MEMWBValue;

reg   signed [31:0]  ImmGen, ImmGen_c;

reg          [31:0]  IDEXIR;
reg           [6:0]  IDEXop, EXMEMop, MEMWBop, WBop;       // Instruction
reg           [4:0]  IDEXrs1, IDEXrs2, EXMEMrs1, EXMEMrs2; // Decoded
reg           [4:0]  IDEXrd, EXMEMrd, MEMWBrd;             // Values
reg           [9:0]  IDEXFuncCode;                         // Registers

reg           [1:0]  IDEXALUop;                                                               // Control
reg                  IDEXMemtoReg, EXMEMMemtoReg, MEMWBMemtoReg, IDEXMemWrite, EXMEMMemWrite; // Signals
reg                  IDEXRegWrite, EXMEMRegWrite, MEMWBRegWrite;                              // Pipeline
reg                  IDEXBranch, EXMEMBranch;                                                 // Registers
reg                  IDEXALUSrc;                                                              //

reg                  IDEXstall, EXMEMstall, MEMWBstall; // Stall pipeline registers

wire          [31:0] PC_addr;
wire          [31:0] DMem_addr_w;
wire          [31:0] predict_pc, correct_pc;
wire   signed [31:0] PCOffset;
wire          [31:0] IFIDIR_w, IFIDIR;
wire           [6:0] IFIDop;
wire           [4:0] IFIDrs1, IFIDrs2, IFIDrd;

wire [REG_WIDTH-1:0] Ain, Bin;
wire [REG_WIDTH-1:0] ALUResult;
wire [REG_WIDTH-1:0] D_out;

wire           [9:0] FuncCode;
wire           [3:0] ALUCtl;
wire           [3:0] RealALUCtl;
wire           [6:0] ControlInOp;
wire                 ALUSrc_w, MemRead_w, MemWrite_w, RegWrite_w, MemtoReg_w, islessthan, Branch_w, PCSrc;
wire           [1:0] ALUop_w;
wire           [1:0] Forwading_A, Forwading_B;
wire                 flush;
wire                 stall;
////////////////////////////////////// END Internal REG/WIRE Declaration /////////////////////////////////////////////

/////////////////////////////////////// Module Instantiations ///////////////////////////////////////////////////////
PClogic PClogic(
	.clk(CLOCK_50),
	.rstn(rstn),
	.prev_taken(PCSrc),
	.exmemop(EXMEMop),
	.current_pc(PC),
	.instr(IFIDIR_w),
	.flush(flush),
	.predict_pc(predict_pc),
	.correct_pc(correct_pc),
	.TotalBranches(TotalBranches),
	.timeswrong(timeswrong)
);

RAM #(32, 45, IFILENAME) I_Memory(.wr_en(1'b0),
                                      .read_en(~stall),
									  .index(PC_addr),
									  .entry(32'b0),
									  .entry_out(IFIDIR_w),
									  .clk(CLOCK_50)
);

RAM #(REG_WIDTH, M*N+N*N2+M*N2, "D20_32bit.txt") D_Memory(.wr_en(EXMEMMemWrite),
                                                        .read_en(1'b1),
												        .index(DMem_addr_w),
												        .entry(D_entry),
												        .entry_out(D_out),
												        .clk(CLOCK_50)
);

ALUControl ALUControl(.ALUOp(IDEXALUop), .FuncCode(IDEXFuncCode), .ALUCtl(ALUCtl));

RISCVALU ALU(.ALUCtl(RealALUCtl),
			 .ALUOut(ALUResult),
			 .A(Ain),
			 .B(Bin),
			 .IsLessThan(islessthan)
);

Forwarding Mainforwading (
    .IDEXrs1(IDEXrs1),
    .IDEXrs2(IDEXrs2),
    .EXMEMrd(EXMEMrd),
    .MEMWBrd(MEMWBrd),
	.MEMWBstall(MEMWBstall),
    .Forwading_A(Forwading_A),
    .Forwading_B(Forwading_B)
);

Control MainControl(.opcode(ControlInOp),
					.MemtoReg(MemtoReg_w),
					.ALUSrc(ALUSrc_w),
					.ALUOp(ALUop_w),
					.Branch(Branch_w),
                    .MemRead(MemRead_w),
                    .MemWrite(MemWrite_w),
					.RegWrite(RegWrite_w)
);
/////////////////////////////////////// END Module Instantiations ////////////////////////////////////////////////


//////////////////////////////////////////// Assignments ///////////////////////////////////////////////////////////////
assign PC_addr     = PC >> 2;
assign DMem_addr_w = ALUOut >> 2;

assign IFIDIR   = !rstn ? 32'b0 : IFIDIR_w;
assign IFIDrd   = IFIDIR[11:7];
assign IFIDrs1  = IFIDIR[19:15];
assign IFIDrs2  = IFIDIR[24:20];
assign IFIDop   = IFIDIR[6:0];
assign FuncCode = {IFIDIR[31:25], IFIDIR[14:12]};
assign PCOffset = {{22{IFIDIR[31]}}, IFIDIR[7], IFIDIR[30:25], IFIDIR[11:8], 1'b0};

assign RealALUCtl  = (IDEXstall && (IDEXop != B_I)) ? 4'bzzzz : ALUCtl;
assign ControlInOp = (stall && (IFIDop != B_I)) ? NOP[6:0] : IFIDIR[6:0];

assign PCSrc = EXMEMBranch && ISLESSTHAN;

assign Ain = (Forwading_A == FORWARDFROMALU) ? ALUOut : ((Forwading_A == FORWARDFROMMEM) ? write_back_val : IDEXA) ;
assign Bin = (Forwading_B == FORWARDFROMALU) ? ALUOut : ((Forwading_B == FORWARDFROMMEM) ? write_back_val : (IDEXALUSrc ? ImmGen : IDEXB));

assign stall = ((IDEXop == LW) && ((IFIDrs1 == IDEXrd) || (IFIDrs2 == IDEXrd)));
//////////////////////////////////////////// END Assignments ///////////////////////////////////////////////////////////////


integer i;
always @(posedge CLOCK_50) begin
	clock_count <= clock_count + 1'b1;
	PC <= PCn;
	IFIDPC <= PC;
	if (IFIDIR == EOF) done <= 1'b1;

	////////////////// ID/EX Stage /////////////////////
	IDEXstall <= stall;
	if (~IDEXstall) begin
        IDEXPC <= IFIDPC;
        IDEXrs1 <= IFIDrs1;
        IDEXrs2 <= IFIDrs2;
        ImmGen <= ImmGen_c;
        IDEXFuncCode <= FuncCode;
        IDEXrd <= IFIDrd;
        IDEXop <= IFIDIR[6:0];
        IDEXMemWrite <= MemWrite_w;
        instr_count <= (IFIDIR != EOF) ? instr_count + 1'b1 : instr_count;
		IDEXIR <= IFIDIR;
    end
    Regs[MEMWBrd] <= (WBop == B_I) ? Regs[MEMWBrd] : (MEMWBRegWrite ? write_back_val : Regs[MEMWBrd]);
	IDEXBranch   <= Branch_w;
    IDEXRegWrite <= RegWrite_w;
	IDEXALUSrc   <= ALUSrc_w;
	IDEXMemtoReg <= MemtoReg_w;
    IDEXALUop    <= ALUop_w;
	///////////// END ID/EX Stage ///////////////////////


	////////////////////// EX/MEM Stage ///////////////
	EXMEMstall <= IDEXstall;
	if (~EXMEMstall) begin
        EXMEMrs1 <= IDEXrs1;
        EXMEMrs2 <= IDEXrs2;
        ISLESSTHAN <= islessthan;
        EXMEMB <= IDEXB;
        EXMEMrd <= IDEXrd;
        EXMEMop <= IDEXop;
        EXMEMBranch <= IDEXBranch;
        EXMEMMemWrite <= IDEXMemWrite;
	end
	ALUOut <= ALUResult;
    EXMEMRegWrite <= IDEXRegWrite;
	EXMEMMemtoReg <= IDEXMemtoReg;
	EXMEMBranch   <= IDEXBranch;
	/////////////////////// END EX/MEM Stage ///////////

	/////////////////////// MEM/WB Stage ///////////////
	MEMWBstall <= EXMEMstall;
	if (~MEMWBstall) begin
		MEMWBrd <= EXMEMrd;
		MEMWBop <= EXMEMop;
	end
	WBop <= MEMWBop;
	WBALUOut <= ALUOut;
    MEMWBRegWrite <= EXMEMRegWrite;
	MEMWBMemtoReg <= EXMEMMemtoReg;
	/////////////////////// END MEM/WB Stage ///////////

	if (!rstn || flush) begin
		done <= 0;
		IFIDPC <= 0;

		IDEXPC <= 0;
		IDEXA        <= 0; IDEXB <= 0;
		IDEXrs1      <= 0; IDEXrs2 <= 0;
		IDEXFuncCode <= 0; IDEXrd <= 0;
		IDEXstall <= 0;    IDEXop <= 0;
		IDEXMemtoReg <= 0; IDEXBranch <= 0;
		IDEXALUSrc <= 0;   IDEXALUop <= 0;
		IDEXMemWrite <= 0; IDEXRegWrite <= 1;
		// PCSum <= 0;

        ISLESSTHAN <= 0;
		ALUOut <= 0;
		EXMEMB <= 0;       EXMEMrd <= 0;
		EXMEMstall <= 0;   EXMEMPC <= 0;
		EXMEMop <= 0;      EXMEMMemtoReg <= 0;
		EXMEMBranch <= 0;  EXMEMMemWrite <= 0;
		EXMEMrs1 <= 0;     EXMEMrs2 <= 0;
		EXMEMRegWrite <= 1;

		WBALUOut <= 0;      MEMWBop <= 0;
		MEMWBMemtoReg <= 0; MEMWBRegWrite <= 1;
		MEMWBstall <= 0;    MEMWBrd <= 0;
		MEMWBop <= 0;
		
		WBop <= 0;
		ImmGen <= 0;
	end
	if (!rstn) begin
		PC <= 0;
		clock_count <= 0;
		instr_count <= 0;
		for(i = 0; i <= 31; i = i + 1) Regs[i] <= 0;
	end
end

always @(*) begin

	ImmGen_c = ImmGen;
	PCn = stall ? PC : (flush ? correct_pc : predict_pc);

	IDEXA = Regs[IDEXrs1];
	IDEXB = Regs[IDEXrs2];

	if ((IFIDop == LW) || (IFIDop == ADDI)) begin
		ImmGen_c = IFIDIR[31:20];
	end else if (IFIDop == SW) begin
		ImmGen_c = {IFIDIR[31:25], IFIDIR[11:7]};
	end else if (IFIDop == B_I) begin
		ImmGen_c = PCOffset;
	end
	/////////////////// END ID/EX Stage //////////////

	//////////////////// EX/MEM Stage ////////////////
	// PCSum = IDEXPC + ImmGen;
	D_entry = EXMEMB;
	///////////////////// END EX/MEM Stage /////////////

	///////////////////////// MEM/WB Stage ////////////////
    write_back_val = MEMWBMemtoReg ? D_out : WBALUOut;
	//////////////////////// END MEM/WB Stage /////////////

end

endmodule
