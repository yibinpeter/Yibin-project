//=========================================================================
// Functional Level MultiCycle Processor
//=========================================================================

`ifndef LAB2_PROC_PROC_BASE_V
`define LAB2_PROC_PROC_BASE_V

`include "vc/mem-msgs.v"
`include "vc/queues.v"
`include "vc/trace.v"

`include "tinyrv2_encoding.v"


module lab2_proc_ProcFLMultiCycle
#(
  parameter p_num_cores = 1
)
(
  input  logic         clk,
  input  logic         reset,

  // From mngr streaming port

  input  logic [31:0]  mngr2proc_msg,
  input  logic         mngr2proc_val,
  output logic         mngr2proc_rdy,

  // To mngr streaming port

  output logic [31:0]  proc2mngr_msg,
  output logic         proc2mngr_val,
  input  logic         proc2mngr_rdy,

  // Instruction Memory Request Port

  output mem_req_4B_t  imem_reqstream_msg,
  output logic         imem_reqstream_val,
  input  logic         imem_reqstream_rdy,

  // Instruction Memory Response Port

  input  mem_resp_4B_t imem_respstream_msg,
  input  logic         imem_respstream_val,
  output logic         imem_respstream_rdy,

  // Data Memory Request Port

  output mem_req_4B_t  dmem_reqstream_msg,
  output logic         dmem_reqstream_val,
  input  logic         dmem_reqstream_rdy,

  // Data Memory Response Port

  input  mem_resp_4B_t dmem_respstream_msg,
  input  logic         dmem_respstream_val,
  output logic         dmem_respstream_rdy,

  // stats output; core_id is an input port rather than a parameter so
  // that the module only needs to be compiled once. If it were a
  // parameter, each core would be compiled separately.

  input  logic [31:0]  core_id,
  output logic         commit_inst,
  output logic         stats_en

);

  //----------------------------------------------------------------------
  // Instruction Memory Request Bypass Queue
  //----------------------------------------------------------------------

  logic [1:0]  imem_queue_num_free_entries;
  mem_req_4B_t imem_reqstream_enq_msg;
  logic        imem_reqstream_enq_val;
  logic        imem_reqstream_enq_rdy;

  logic [31:0] imem_reqstream_msg_addr;

  assign imem_reqstream_msg.type_  = `VC_MEM_REQ_MSG_TYPE_READ;
  assign imem_reqstream_msg.opaque = 8'b0;
  assign imem_reqstream_msg.addr   = imem_reqstream_msg_addr;
  assign imem_reqstream_msg.len    = 2'd0;
  assign imem_reqstream_msg.data   = 32'bx;


  //----------------------------------------------------------------------
  // Data Memory Request Bypass Queue
  //----------------------------------------------------------------------

  logic        dmem_queue_num_free_entries;
  mem_req_4B_t dmem_reqstream_enq_msg;
  logic        dmem_reqstream_enq_val;
  logic        dmem_reqstream_enq_rdy;

  logic [2:0 ] dmem_reqstream_enq_msg_type;
  logic [31:0] dmem_reqstream_enq_msg_addr;
  logic [31:0] dmem_reqstream_enq_msg_data;

  assign dmem_reqstream_enq_msg.type_  = dmem_reqstream_enq_msg_type;
  assign dmem_reqstream_enq_msg.opaque = 8'b0;
  assign dmem_reqstream_enq_msg.addr   = dmem_reqstream_enq_msg_addr;
  assign dmem_reqstream_enq_msg.len    = 2'd0;
  assign dmem_reqstream_enq_msg.data   = dmem_reqstream_enq_msg_data;

  vc_Queue#(`VC_QUEUE_BYPASS,$bits(mem_req_4B_t),1) dmem_queue
  (
    .clk     (clk),
    .reset   (reset),
    .num_free_entries(dmem_queue_num_free_entries),

    .enq_msg (dmem_reqstream_enq_msg),
    .enq_val (dmem_reqstream_enq_val),
    .enq_rdy (dmem_reqstream_enq_rdy),

    .deq_msg (dmem_reqstream_msg),
    .deq_val (dmem_reqstream_val),
    .deq_rdy (dmem_reqstream_rdy)
  );

  //----------------------------------------------------------------------
  // proc2mngr Bypass Queue
  //----------------------------------------------------------------------

  logic        proc2mngr_queue_num_free_entries;
  logic [31:0] proc2mngr_enq_msg;
  logic        proc2mngr_enq_val;
  logic        proc2mngr_enq_rdy;

  vc_Queue#(`VC_QUEUE_BYPASS,32,1) proc2mngr_queue
  (
    .clk     (clk),
    .reset   (reset),
    .num_free_entries(proc2mngr_queue_num_free_entries),

    .enq_msg (proc2mngr_enq_msg),
    .enq_val (proc2mngr_enq_val),
    .enq_rdy (proc2mngr_enq_rdy),

    .deq_msg (proc2mngr_msg),
    .deq_val (proc2mngr_val),
    .deq_rdy (proc2mngr_rdy)
  );

  //----------------------------------------------------------------------
  // Instruction Unpacking
  //----------------------------------------------------------------------
  logic [`TINYRV2_INST_OPCODE_NBITS-1:0] opcode;
  logic [`TINYRV2_INST_RD_NBITS-1:0]     rd;
  logic [`TINYRV2_INST_RS1_NBITS-1:0]    rs1;
  logic [`TINYRV2_INST_RS2_NBITS-1:0]    rs2;
  logic [`TINYRV2_INST_FUNCT3_NBITS-1:0] funct3;
  logic [`TINYRV2_INST_FUNCT7_NBITS-1:0] funct7;
  logic [`TINYRV2_INST_CSR_NBITS-1:0]    csr;
   lab2_proc_tinyrv2_encoding_InstUnpack inst_unpack
  (
    .opcode   (),
    .inst     (inst),
    .rs1      (rs1),
    .rs2      (rs2),
    .rd       (rd),
    .funct3   (funct3),
    .funct7   (funct7),
    .csr      (csr)
  );
  logic [31:0] PC;
  logic [31:0] PC_prev;
  logic [31:0] n_PC;
  logic [31:0] inst;
  logic [31:0] n_inst;
  logic print_trace;
  logic [31:0] rf [31:0];
  logic [31:0] n_rf [31:0];

    function [11:0] imm_i( input [`TINYRV2_INST_NBITS-1:0] inst );
  begin
    // I-type immediate
    imm_i = { inst[31], inst[30:25], inst[24:21], inst[20] };
  end
  endfunction

  function [4:0] imm_shamt( input [`TINYRV2_INST_NBITS-1:0] inst );
  begin
    // I-type immediate, specialized for shift amounts
    imm_shamt = { inst[24:21], inst[20] };
  end
  endfunction

  function [11:0] imm_s( input [`TINYRV2_INST_NBITS-1:0] inst );
  begin
    // S-type immediate
    imm_s = { inst[31], inst[30:25], inst[11:8], inst[7] };
  end
  endfunction

  function [12:0] imm_b( input [`TINYRV2_INST_NBITS-1:0] inst );
  begin
    // B-type immediate
    imm_b = { inst[31], inst[7], inst[30:25], inst[11:8], 1'b0 };
  end
  endfunction

  function [19:0] imm_u_sh12( input [`TINYRV2_INST_NBITS-1:0] inst );
  begin
    // U-type immediate, shifted right by 12
    imm_u_sh12 = { inst[31], inst[30:20], inst[19:12] };
  end
  endfunction

  function [20:0] imm_j( input [`TINYRV2_INST_NBITS-1:0] inst );
  begin
    // J-type immediate
    imm_j = { inst[31], inst[19:12], inst[20], inst[30:25], inst[24:21], 1'b0 };
  end
  endfunction

  /* verilator lint_off WIDTH */
  typedef enum { Idle, IReq,IWait, E, EWait} pstate;
  pstate state, n_state;
  always_comb begin
    n_state= state;
    n_PC=PC;
    n_inst=inst;
    print_trace =1;
    n_rf=rf;
    imem_reqstream_val=0;
    dmem_reqstream_enq_msg_addr = 0;
    dmem_reqstream_enq_msg_data =0;
    dmem_reqstream_enq_msg_type =0;
    dmem_reqstream_enq_val=0;
    dmem_respstream_rdy =0;
    proc2mngr_enq_val =0;
    proc2mngr_enq_msg=0;
    mngr2proc_rdy=0;
    imem_respstream_rdy=0;
    if (reset) begin
        n_state = Idle;
        n_rf ='{default:32'h00000000};
    end
    else begin
      if (state == Idle)begin
        n_state =IReq;
      end
      else if (state == IReq)begin
          imem_reqstream_val =1;
          imem_reqstream_msg_addr = PC;
        if(imem_reqstream_rdy && imem_reqstream_val)begin
          n_state=IWait;
        end 
        else n_state=IReq;
      end
      else if (state == IWait)begin
        imem_respstream_rdy =1;
        if(imem_respstream_rdy && imem_respstream_val) begin
          n_state = E;
          n_inst =imem_respstream_msg.data;
          //print_trace =0;
        end else begin
          n_state=IWait;
        end
      end
      else if (state == E)begin
          n_state=Idle;
          n_PC=PC+4;
          casez ( inst )
          `TINYRV2_INST_CSRR  : begin
            if(csr == `TINYRV2_CPR_MNGR2PROC) begin
              mngr2proc_rdy =1;
              if(mngr2proc_val)begin
                n_rf[rd]=mngr2proc_msg;
              end else begin
                 n_state=E;
                 n_PC=PC;
              end
            end
            else if ( csr == `TINYRV2_CPR_NUMCORES )
              n_rf[rd] = 2'h1;
            else if ( csr  == `TINYRV2_CPR_COREID )
              n_rf[rd]       = 2'h0;
          end
          `TINYRV2_INST_CSRW  : begin
            if(csr == `TINYRV2_CPR_PROC2MNGR) begin
              proc2mngr_enq_val =1;
              proc2mngr_enq_msg=rf[rs1];
              if(proc2mngr_enq_rdy)begin
              end else begin
                n_state=E;
                n_PC=PC;
              end
            end    
          end
           `TINYRV2_INST_ADD   : begin 
              n_rf[rd]=rf[rs1]+rf[rs2];
            end
            `TINYRV2_INST_SUB   : begin 
              n_rf[rd]=rf[rs1]-rf[rs2];
            end
            `TINYRV2_INST_AND   : begin 
              n_rf[rd]=rf[rs1]&rf[rs2];
            end
            `TINYRV2_INST_OR    : begin 
              n_rf[rd]=rf[rs1]|rf[rs2];
            end
            `TINYRV2_INST_XOR   : begin 
              n_rf[rd]=rf[rs1]^rf[rs2];
            end
            `TINYRV2_INST_SLT   : begin 
              n_rf[rd]={{31'b0},{$signed(rf[rs1]) < $signed(rf[rs2])}};
            end
            `TINYRV2_INST_SLTU  :  begin 
              n_rf[rd]={{31'b0},{rf[rs1] < rf[rs2]}};
            end
            `TINYRV2_INST_MUL   : begin 
              n_rf[rd]=rf[rs1] * rf[rs2];
            end
            `TINYRV2_INST_ADDI  : begin 
              n_rf[rd]=$signed(rf[rs1]) + $signed(imm_i(inst));
            end
            `TINYRV2_INST_ANDI  : begin 
              n_rf[rd]=$signed(rf[rs1]) & $signed(imm_i(inst));
            end
            `TINYRV2_INST_ORI   : begin 
              n_rf[rd]=$signed(rf[rs1]) | $signed(imm_i(inst));
            end
            `TINYRV2_INST_XORI  :  begin 
              n_rf[rd]=$signed(rf[rs1]) ^ $signed(imm_i(inst));
            end
            `TINYRV2_INST_SLTI  : begin 
              n_rf[rd]={{31'b0},{$signed(rf[rs1]) < $signed(imm_i(inst))}};
            end 
            `TINYRV2_INST_SLTIU : begin 
              n_rf[rd]={{31'b0},{(rf[rs1]) < {{20{inst[31]}},{imm_i(inst)}}}};
            end
            `TINYRV2_INST_SRA   : begin
              n_rf[ rd ] = $signed(rf[ rs1 ]) >>> rf[ rs2 ][4:0];
            end
            `TINYRV2_INST_SRL   : begin
              n_rf[ rd ] = $signed(rf[ rs1 ]) >> rf[ rs2 ][4:0];
            end
            `TINYRV2_INST_SLL   : begin
              n_rf[ rd ] = $signed(rf[ rs1 ]) << rf[ rs2 ][4:0];
            end
            `TINYRV2_INST_SRAI  : begin
              n_rf[ rd ] = $signed(rf[ rs1 ]) >>> imm_shamt(inst);
            end
            `TINYRV2_INST_SRLI  : begin
              n_rf[ rd ] = $signed(rf[ rs1 ]) >> imm_shamt(inst);
            end
            `TINYRV2_INST_SLLI  : begin
              n_rf[ rd ] = $signed(rf[ rs1 ]) << imm_shamt(inst);
            end
            `TINYRV2_INST_LUI   : begin
              n_rf[ rd ] = imm_u_sh12(inst)<<12;
            end
            `TINYRV2_INST_AUIPC : begin
              n_rf[ rd ] = PC+(imm_u_sh12(inst)<<12);
            end
          `TINYRV2_INST_LW    : begin
              dmem_reqstream_enq_msg_addr = $signed(rf[ rs1 ])+ $signed( imm_i(inst) );
              dmem_reqstream_enq_msg_data =0;
              dmem_reqstream_enq_msg_type =`VC_MEM_REQ_MSG_TYPE_READ;
              dmem_reqstream_enq_val=1;
            if(dmem_reqstream_enq_rdy&& dmem_reqstream_enq_val)begin
              n_state=EWait;
            end else begin
              n_state=E;
              n_PC=PC;
            end
          end
          `TINYRV2_INST_SW    : begin
                dmem_reqstream_enq_msg_addr = $signed(rf[ rs1 ]) + $signed( imm_s(inst) );
                dmem_reqstream_enq_msg_data =rf[ rs2 ];
                dmem_reqstream_enq_msg_type =`VC_MEM_REQ_MSG_TYPE_WRITE;
                dmem_reqstream_enq_val =1;
            if(dmem_reqstream_enq_val&&dmem_reqstream_enq_rdy)begin
              n_state=EWait;
            end else begin
              n_state=E;
              n_PC=PC;
            end
          end
          `TINYRV2_INST_JAL   : begin
              n_rf[ rd ] = PC+4;
              n_PC = $signed(PC) +$signed(imm_j(inst));
            end
            `TINYRV2_INST_JALR  : begin
              n_rf[ rd ] = PC+4;
              n_PC = ($signed(rf[rs1]) + $signed(imm_i(inst)))& 32'hfffffffe;
            end
            `TINYRV2_INST_BEQ   : begin
              if (rf[rs1]==rf[rs2]) n_PC=$signed(PC) +$signed(imm_b(inst));
            end
            `TINYRV2_INST_BNE   : begin
              if (rf[rs1]!=rf[rs2]) begin
                n_PC= $signed(PC) +$signed(imm_b(inst));
              end 
            end
            `TINYRV2_INST_BLT   : begin
              if ($signed(rf[rs1]) < $signed(rf[rs2])) n_PC=$signed(PC) +$signed(imm_b(inst));
            end
            `TINYRV2_INST_BGE   : begin
              if ($signed(rf[rs1]) >= $signed(rf[rs2])) n_PC=$signed(PC) +$signed(imm_b(inst));
            end
            `TINYRV2_INST_BLTU  : begin
              if (rf[rs1] < rf[rs2]) n_PC=$signed(PC) +$signed(imm_b(inst));
            end
            `TINYRV2_INST_BGEU  :  begin
              if (rf[rs1] >= rf[rs2]) n_PC=$signed(PC) +$signed(imm_b(inst));
            end
          default             : begin end
        endcase
      end
      else if (state == EWait)begin
          n_state=Idle;
          casez ( inst )
          `TINYRV2_INST_LW    : begin
            dmem_respstream_rdy =1;
            if(dmem_respstream_rdy && dmem_respstream_val) begin
              n_state=Idle;
              n_rf[ rd ] = dmem_respstream_msg.data;
            end else  begin 
              n_state=EWait;
            end
          end
          `TINYRV2_INST_SW    : begin
            dmem_respstream_rdy =1;
            if(dmem_respstream_rdy &&dmem_respstream_val) n_state=Idle;
            else  begin
              n_state=EWait;
            end
          end
          
          endcase
      end

      if(PC!=n_PC) begin 
        
        print_trace=0;
      end 
  end

  end
  always_ff @(posedge clk) begin
      inst <=n_inst;
      PC<=n_PC;
      PC_prev<=PC;


      if(PC!=n_PC) begin 
        PC_prev<=n_PC;
      end 
      rf<=n_rf;
      rf[0]<=0;
      state <=n_state;
      if (reset) begin
          PC<= 32'h200 ;
      end    
  end
  
  /* verilator lint_on WIDTH */


  //----------------------------------------------------------------------
  // Line tracing
  //----------------------------------------------------------------------

  `ifndef SYNTHESIS

  lab2_proc_tinyrv2_encoding_InstTasks tinyrv2();
  logic [`VC_TRACE_NBITS-1:0] temp;
  
  logic [`VC_TRACE_NBITS-1:0] str;
  `VC_TRACE_BEGIN
  begin
      $sformat(temp,"%x",mngr2proc_msg);
      vc_trace.append_val_rdy_str( trace_str, mngr2proc_val, mngr2proc_rdy, temp );
      vc_trace.append_str( trace_str, ">" );
      if(print_trace) begin
        vc_trace.append_str(trace_str,".");
        vc_trace.append_chars( trace_str, " ", 31 );
      end
      else begin
        $sformat( str, "%x-",  PC_prev);
        vc_trace.append_str(trace_str,str);
        vc_trace.append_str( trace_str, { 3896'b0, tinyrv2.disasm( n_inst ) } );
      end
    
      vc_trace.append_str( trace_str, ">" );
      $sformat(temp,"%x",proc2mngr_enq_msg);
      vc_trace.append_val_rdy_str( trace_str, proc2mngr_enq_val, proc2mngr_enq_rdy, temp);

  end
  `VC_TRACE_END

  // These trace modules are useful because they breakout all the
  // individual fields so you can see them in gtkwave

  vc_MemReqMsg4BTrace imem_reqstream_trace
  (
    .clk   (clk),
    .reset (reset),
    .val   (imem_reqstream_val),
    .rdy   (imem_reqstream_rdy),
    .msg   (imem_reqstream_msg)
  );

  vc_MemReqMsg4BTrace dmem_reqstream_trace
  (
    .clk   (clk),
    .reset (reset),
    .val   (dmem_reqstream_val),
    .rdy   (dmem_reqstream_rdy),
    .msg   (dmem_reqstream_msg)
  );

  vc_MemRespMsg4BTrace imem_respstream_trace
  (
    .clk   (clk),
    .reset (reset),
    .val   (imem_respstream_val),
    .rdy   (imem_respstream_rdy),
    .msg   (imem_respstream_msg)
  );

  vc_MemRespMsg4BTrace dmem_respstream_trace
  (
    .clk   (clk),
    .reset (reset),
    .val   (dmem_respstream_val),
    .rdy   (dmem_respstream_rdy),
    .msg   (dmem_respstream_msg)
  );

  `endif

endmodule

`endif /* LAB2_PROC_PROC_BASE_V */

