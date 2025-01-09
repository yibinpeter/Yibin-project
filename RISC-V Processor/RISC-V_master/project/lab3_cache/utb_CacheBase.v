//========================================================================
// utb_CacheAlt
//========================================================================
// A basic Verilog unit test bench for the CacheAlt module

`default_nettype none
`timescale 1ps/1ps


`include "CacheBase.v"
`include "vc/trace.v"
`include "vc/mem-msgs.v"
//------------------------------------------------------------------------
// Top-level module
//------------------------------------------------------------------------

module top(  input logic clk, input logic linetrace );
  logic                    reset;
  logic                    memreq_val;
  logic                    memreq_rdy;
  mem_req_4B_t             memreq_msg;
  logic                    memresp_val;
  logic                    memresp_rdy;
  mem_resp_4B_t            memresp_msg;
  logic                    cache_req_val;
  logic                    cache_req_rdy;
  mem_req_4B_t             cache_req_msg;
  logic                    cache_resp_val;
  logic                    cache_resp_rdy;
  mem_resp_4B_t            cache_resp_msg;
  logic                    flush;
  logic                    flush_done;

  //----------------------------------------------------------------------
  // Module instantiations
  //----------------------------------------------------------------------
  
  // Instantiate the CacheBase
  lab3_cache_CacheBase DUT
  ( 
    .clk(clk),
    .reset(reset),
    .memreq_val(memreq_val),
    .memreq_rdy(memreq_rdy),
    .memreq_msg(memreq_msg),
    .memresp_val(memresp_val),
    .memresp_rdy(memresp_rdy),
    .memresp_msg(memresp_msg),
    .cache_req_val(cache_req_val),
    .cache_req_rdy(cache_req_rdy),
    .cache_req_msg(cache_req_msg),
    .cache_resp_val(cache_resp_val),
    .cache_resp_rdy(cache_resp_rdy),
    .cache_resp_msg(cache_resp_msg), 
    .flush(flush),
    .flush_done(flush_done)
  ); 

    logic [31:0] Addr;
    logic [20:0] Tag;
    logic [4:0]  Idx;
    logic [3:0]  Offset;
    assign {Tag, Idx, Offset} = Addr[31:2];


  //----------------------------------------------------------------------
  // Run the Test Bench
  //----------------------------------------------------------------------

  initial begin

    $display("Start of Testbench");
    // Initalize all the signal inital values.

    reset                    = 0;
    memreq_val               = 0;
    memreq_msg               = 0;
    memresp_rdy              = 0;
    cache_req_rdy            = 0;
    cache_resp_val           = 0;
    cache_resp_msg           = 0;
    flush                    = 0;#1
    reset                    = 1;#1

    //--------------------------------------------------------------------
    // Unit Testing #1 Read hit path for clean lines  
    //--------------------------------------------------------------------
    // Align test bench with negedge so that it looks better
    @(negedge clk); 
    $display( "Advancing time");
    memreq_msg.type_         = `VC_MEM_REQ_MSG_TYPE_READ;
    memreq_msg.opaque        = 8'h00;
    memreq_msg.addr          = 32'hffffffff;//
    memreq_msg.len           = 0;
    memreq_msg.data          = 32'h0;
    Addr = 32'hffffffff;
    Tag = Addr[31:11];
    Idx = Addr[10:6];
    Offset =Addr[5:2];
    DUT.tag_array[31][20:0] = Tag;
    DUT.tag_array_next[31][20:0] = Tag;
    DUT.data_array[Idx][Offset*32 +: 32]=32'hdeadbeef; 
    reset                    = 0;
    memreq_val               = 1;
    memresp_rdy              = 1;

    DUT.ditry_array[Idx]=0;
    //DUT.ditry_array_next[Idx]=0;
    DUT.valid_array[Idx]=1;
    #0.2
    assert(DUT.memresp_msg.data == DUT.data_array[Idx][Offset*32 +: 32]) begin
      $display("DUT.memresp_msg.data is correct.                 Expected: %h, Actual: %h", DUT.data_array[Idx][Offset*32 +: 32],DUT.memresp_msg.data); pass();
    end else begin
      $display("DUT.memresp_msg.data is incorrect.               Expected: %h, Actual: %h", DUT.data_array[Idx][Offset*32 +: 32],DUT.memresp_msg.data); fail();
    end
 

    //--------------------------------------------------------------------
    // Unit Testing #2 Write hit path for clean lines  
    //--------------------------------------------------------------------
    // Align test bench with negedge so that it looks better
    @(negedge clk); 
    $display( "Advancing time");
    memreq_msg.type_         = `VC_MEM_REQ_MSG_TYPE_WRITE;
    memreq_msg.opaque        = 8'h00;
    memreq_msg.addr          = 32'hffffffff;//
    memreq_msg.len           = 0;
    memreq_msg.data          = 32'h12345678;
    Addr = 32'hffffffff;
    Tag = Addr[31:11];
    Idx = Addr[10:6];
    Offset =Addr[5:2];
    DUT.tag_array[31][20:0] = Tag;
    DUT.tag_array_next[31][20:0] = Tag;
   // DUT.data_array[Idx][Offset*32 +: 32]=32'hdeadbeef; 
   // DUT.data_array_next[Idx][Offset*32 +: 32]=32'hdeadbeef; 
    reset                    = 0;
    memreq_val               = 1;
    memresp_rdy              = 1;

    DUT.ditry_array[Idx]=0;
    //DUT.ditry_array_next[Idx]=0;
    DUT.valid_array[Idx]=1;
    @(negedge clk); 
    #0.2
    assert(DUT.memreq_msg.data == DUT.data_array[Idx][Offset*32 +: 32]) begin
      $display("DUT.memresp_msg.data is correct.                 Expected: %h, Actual: %h", DUT.data_array[Idx][Offset*32 +: 32],DUT.memreq_msg.data); pass();
    end else begin
      $display("DUT.memresp_msg.data is incorrect.               Expected: %h, Actual: %h", DUT.data_array[Idx][Offset*32 +: 32],DUT.memreq_msg.data); fail();
    end
 

    //--------------------------------------------------------------------
    // Unit Testing #3 Read hit path for dirty lines  
    //--------------------------------------------------------------------
    // Align test bench with negedge so that it looks better
    @(negedge clk); 
    $display( "Advancing time");
    memreq_msg.type_         = `VC_MEM_REQ_MSG_TYPE_READ;
    memreq_msg.opaque        = 8'h00;
    memreq_msg.addr          = 32'hffffffff;//
    memreq_msg.len           = 0;
    memreq_msg.data          = 32'h0;
    Addr = 32'hffffffff;
    Tag = Addr[31:11];
    Idx = Addr[10:6];
    Offset =Addr[5:2];
    DUT.tag_array[31][20:0] = Tag;
    DUT.tag_array_next[31][20:0] = Tag;
    DUT.data_array[Idx][Offset*32 +: 32]=32'hdeadbeef; 
    reset                    = 0;
    memreq_val               = 1;
    memresp_rdy              = 1;

    DUT.ditry_array[Idx]=1;
    //DUT.ditry_array_next[Idx]=1;
    DUT.valid_array[Idx]=1;
    #0.2
    assert(DUT.memresp_msg.data == DUT.data_array[Idx][Offset*32 +: 32]) begin
      $display("DUT.memresp_msg.data is correct.                 Expected: %h, Actual: %h", DUT.data_array[Idx][Offset*32 +: 32],DUT.memresp_msg.data); pass();
    end else begin
      $display("DUT.memresp_msg.data is incorrect.               Expected: %h, Actual: %h", DUT.data_array[Idx][Offset*32 +: 32],DUT.memresp_msg.data); fail();
    end



    //--------------------------------------------------------------------
    // Unit Testing #4 Write hit path for dirty lines  
    //--------------------------------------------------------------------
    // Align test bench with negedge so that it looks better
    @(negedge clk); 
    $display( "Advancing time");
    memreq_msg.type_         = `VC_MEM_REQ_MSG_TYPE_WRITE;
    memreq_msg.opaque        = 8'h00;
    memreq_msg.addr          = 32'hffffffff;//
    memreq_msg.len           = 0;
    memreq_msg.data          = 32'h12345678;
    Addr = 32'hffffffff;
    Tag = Addr[31:11];
    Idx = Addr[10:6];
    Offset =Addr[5:2];
    DUT.tag_array[31][20:0] = Tag;
    DUT.tag_array_next[31][20:0] = Tag;

    reset                    = 0;
    memreq_val               = 1;
    memresp_rdy              = 1;

    DUT.ditry_array[Idx]=0;
    //DUT.ditry_array_next[Idx]=0;
    DUT.valid_array[Idx]=1;
    @(negedge clk); 
    #0.2
    // assert(DUT.memreq_msg.data == DUT.data_array[Idx][Offset*32 +: 32]) begin
    //   $display("DUT.memresp_msg.data is correct.                 Expected: %h, Actual: %h", DUT.data_array[Idx][Offset*32 +: 32],DUT.memreq_msg.data); pass();
    // end else begin
    //   $display("DUT.memresp_msg.data is incorrect.               Expected: %h, Actual: %h", DUT.data_array[Idx][Offset*32 +: 32],DUT.memreq_msg.data); fail();
    // end


    //--------------------------------------------------------------------
    // Unit Testing #5 Read miss with refill and no eviction  
    //--------------------------------------------------------------------
    // Align test bench with negedge so that it looks better
    reset=1;
    @(negedge clk); 
    $display( "Advancing time");
    memreq_msg.type_         = `VC_MEM_REQ_MSG_TYPE_READ;
    memreq_msg.opaque        = 8'h00;
    memreq_msg.addr          = 32'h0fffffff;//
    memreq_msg.len           = 0;
    memreq_msg.data          = 32'h0;
    Addr = 32'h0fffffff;
    Tag = Addr[31:11];
    Idx = Addr[10:6];
    Offset =Addr[5:2];
    memreq_val               = 1;
    reset                    = 0;
    memreq_val               = 1;
    memresp_rdy              = 1;

    DUT.ditry_array[Idx]=0;
    //DUT.ditry_array_next[Idx]=0;
    DUT.valid_array[Idx]=1;
    #0.2
    @(negedge clk); 
    assert(DUT.st_cur == DUT.CACHE_MISS_SEND) begin
      $display("DUT.st_cur is correct.                 Expected: %h, Actual: %h", DUT.CACHE_MISS_SEND,DUT.st_cur); pass();
    end else begin
      $display("DUT.st_cur is incorrect.               Expected: %h, Actual: %h", DUT.CACHE_MISS_SEND,DUT.st_cur); fail();
    end

    cache_req_rdy = 1;
    cache_resp_val = 1;
    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'b1};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*0+31 : 32*0] == 32'h1) begin
      $display("DUT.data_array[31][32*0+31 : 32*0] is correct.                 Expected: %h, Actual: %h", 32'h1 ,DUT.data_array[31][32*0+31 : 32*0]); pass();
    end else begin
      $display("DUT.data_array[31][32*0+31 : 32*0] is incorrect.               Expected: %h, Actual: %h", 32'h1 ,DUT.data_array[31][32*0+31 : 32*0]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h2};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*1+31 : 32*1] == 32'h2) begin
      $display("DUT.data_array[31][32*1+31 : 32*1] is correct.                 Expected: %h, Actual: %h", 32'h2 ,DUT.data_array[31][32*1+31 : 32*1]); pass();
    end else begin
      $display("DUT.data_array[31][32*1+31 : 32*1] is incorrect.               Expected: %h, Actual: %h", 32'h2 ,DUT.data_array[31][32*1+31 : 32*1]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h3};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*2+31 : 32*2] == 32'h3) begin
      $display("DUT.data_array[31][32*2+31 : 32*2] is correct.                 Expected: %h, Actual: %h", 32'h3 ,DUT.data_array[31][32*2+31 : 32*2]); pass();
    end else begin
      $display("DUT.data_array[31][32*2+31 : 32*2] is incorrect.               Expected: %h, Actual: %h", 32'h3 ,DUT.data_array[31][32*2+31 : 32*2]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h4};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*3+31 : 32*3] == 32'h4) begin
      $display("DUT.data_array[31][32*3+31 : 32*3] is correct.                 Expected: %h, Actual: %h", 32'h4 ,DUT.data_array[31][32*3+31 : 32*3]); pass();
    end else begin
      $display("DUT.data_array[31][32*3+31 : 32*3] is incorrect.               Expected: %h, Actual: %h", 32'h4 ,DUT.data_array[31][32*3+31 : 32*3]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h5};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*4+31 : 32*4] == 32'h5) begin
      $display("DUT.data_array[31][32*4+31 : 32*4] is correct.                 Expected: %h, Actual: %h", 32'h5 ,DUT.data_array[31][32*4+31 : 32*4]); pass();
    end else begin
      $display("DUT.data_array[31][32*4+31 : 32*4] is incorrect.               Expected: %h, Actual: %h", 32'h5 ,DUT.data_array[31][32*4+31 : 32*4]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h6};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*5+31 : 32*5] == 32'h6) begin
      $display("DUT.data_array[31][32*5+31 : 32*5] is correct.                 Expected: %h, Actual: %h", 32'h6 ,DUT.data_array[31][32*5+31 : 32*5]); pass();
    end else begin
      $display("DUT.data_array[31][32*5+31 : 32*5] is incorrect.               Expected: %h, Actual: %h", 32'h6 ,DUT.data_array[31][32*5+31 : 32*5]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h7};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*6+31 : 32*6] == 32'h7) begin
      $display("DUT.data_array[31][32*6+31 : 32*6] is correct.                 Expected: %h, Actual: %h", 32'h7 ,DUT.data_array[31][32*6+31 : 32*6]); pass();
    end else begin
      $display("DUT.data_array[31][32*6+31 : 32*6] is incorrect.               Expected: %h, Actual: %h", 32'h7 ,DUT.data_array[31][32*6+31 : 32*6]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h8};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*7+31 : 32*7] == 32'h8) begin
      $display("DUT.data_array[31][32*7+31 : 32*7] is correct.                 Expected: %h, Actual: %h", 32'h8 ,DUT.data_array[31][32*7+31 : 32*7]); pass();
    end else begin
      $display("DUT.data_array[31][32*7+31 : 32*7] is incorrect.               Expected: %h, Actual: %h", 32'h8 ,DUT.data_array[31][32*7+31 : 32*7]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h9};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*8+31 : 32*8] == 32'h9) begin
      $display("DUT.data_array[31][32*8+31 : 32*8] is correct.                 Expected: %h, Actual: %h", 32'h9 ,DUT.data_array[31][32*8+31 : 32*8]); pass();
    end else begin
      $display("DUT.data_array[31][32*8+31 : 32*8] is incorrect.               Expected: %h, Actual: %h", 32'h9 ,DUT.data_array[31][32*8+31 : 32*8]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h10};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*9+31 : 32*9] == 32'h10) begin
      $display("DUT.data_array[31][32*9+31 : 32*9] is correct.                 Expected: %h, Actual: %h", 32'h10 ,DUT.data_array[31][32*9+31 : 32*9]); pass();
    end else begin
      $display("DUT.data_array[31][32*9+31 : 32*9] is incorrect.               Expected: %h, Actual: %h", 32'h10 ,DUT.data_array[31][32*9+31 : 32*9]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h11};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*10+31 : 32*10] == 32'h11) begin
      $display("DUT.data_array[31][32*10+31 : 32*10] is correct.                 Expected: %h, Actual: %h", 32'h11 ,DUT.data_array[31][32*10+31 : 32*10]); pass();
    end else begin
      $display("DUT.data_array[31][32*10+31 : 32*10] is incorrect.               Expected: %h, Actual: %h", 32'h11 ,DUT.data_array[31][32*10+31 : 32*10]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h12};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*11+31 : 32*11] == 32'h12) begin
      $display("DUT.data_array[31][32*11+31 : 32*11] is correct.                 Expected: %h, Actual: %h", 32'h12 ,DUT.data_array[31][32*11+31 : 32*11]); pass();
    end else begin
      $display("DUT.data_array[31][32*11+31 : 32*11] is incorrect.               Expected: %h, Actual: %h", 32'h12 ,DUT.data_array[31][32*11+31 : 32*11]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h13};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*12+31 : 32*12] == 32'h13) begin
      $display("DUT.data_array[31][32*12+31 : 32*12] is correct.                 Expected: %h, Actual: %h", 32'h13 ,DUT.data_array[31][32*12+31 : 32*12]); pass();
    end else begin
      $display("DUT.data_array[31][32*12+31 : 32*12] is incorrect.               Expected: %h, Actual: %h", 32'h13 ,DUT.data_array[31][32*12+31 : 32*12]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h14};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*13+31 : 32*13] == 32'h14) begin
      $display("DUT.data_array[31][32*13+31 : 32*13] is correct.                 Expected: %h, Actual: %h", 32'h14 ,DUT.data_array[31][32*13+31 : 32*13]); pass();
    end else begin
      $display("DUT.data_array[31][32*13+31 : 32*13] is incorrect.               Expected: %h, Actual: %h", 32'h14 ,DUT.data_array[31][32*13+31 : 32*13]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h15};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*14+31 : 32*14] == 32'h15) begin
      $display("DUT.data_array[31][32*14+31 : 32*14] is correct.                 Expected: %h, Actual: %h", 32'h15 ,DUT.data_array[31][32*14+31 : 32*14]); pass();
    end else begin
      $display("DUT.data_array[31][32*14+31 : 32*14] is incorrect.               Expected: %h, Actual: %h", 32'h15 ,DUT.data_array[31][32*14+31 : 32*14]); fail();
    end
    memresp_rdy = 1;

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h1};
    //refill:CACHE_MISS_WAIT
        $display("count   ",DUT.count);
       // memresp_rdy = 1;
     @(negedge clk); 
    // assert(DUT.data_array[31][32*15+31 : 32*15] == 32'h1) begin
    //   $display("DUT.data_array[31][32*15+31 : 32*15] is correct.                 Expected: %h, Actual: %h", 32'h1 ,DUT.data_array[31][32*15+31 : 32*15]); pass();
    // end else begin
    //   $display("DUT.data_array[31][32*15+31 : 32*15] is incorrect.               Expected: %h, Actual: %h", 32'h1 ,DUT.data_array[31][32*15+31 : 32*15]); fail();
    // end

    //tag check

   assert(DUT.memresp_msg.data == DUT.data_array[Idx][Offset*32 +: 32]) begin
      $display("DUT.memresp_msg.data is correct.                 Expected: %h, Actual: %h", DUT.data_array[Idx][Offset*32 +: 32],DUT.memresp_msg.data); pass();
    end else begin
      $display("DUT.memresp_msg.data is incorrect.               Expected: %h, Actual: %h", DUT.data_array[Idx][Offset*32 +: 32],DUT.memresp_msg.data); fail();
    end


 





    //--------------------------------------------------------------------
    // Unit Testing #6 Write miss with refill and no eviction  
    //--------------------------------------------------------------------
    // Align test bench with negedge so that it looks better
    reset=1;
    @(negedge clk); 
    $display( "Advancing time");
    memreq_msg.type_         = `VC_MEM_REQ_MSG_TYPE_WRITE;
    memreq_msg.opaque        = 8'h00;
    memreq_msg.addr          = 32'h00ffffff;//
    memreq_msg.len           = 0;
    memreq_msg.data          = 32'habcd4321;
    Addr = 32'h00ffffff;
    Tag = Addr[31:11];
    Idx = Addr[10:6];
    Offset =Addr[5:2];
    memreq_val               = 1;
    // DUT.tag_array[31][20:0] = Tag;
    // DUT.tag_array_next[31][20:0] = Tag;
    // DUT.data_array[Idx][Offset*32 +: 32]=32'hdeadbeef; 
    reset                    = 0;
    memreq_val               = 1;
    memresp_rdy              = 1;

    DUT.ditry_array[Idx]=0;
    //DUT.ditry_array_next[Idx]=0;
    DUT.valid_array[Idx]=1;
    #0.2
    @(negedge clk); 
    assert(DUT.st_cur == DUT.CACHE_MISS_SEND) begin
      $display("DUT.st_cur is correct.                 Expected: %h, Actual: %h", DUT.CACHE_MISS_SEND,DUT.st_cur); pass();
    end else begin
      $display("DUT.st_cur is incorrect.               Expected: %h, Actual: %h", DUT.CACHE_MISS_SEND,DUT.st_cur); fail();
    end

    cache_req_rdy = 1;
    cache_resp_val = 1;
    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'b1};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*0+31 : 32*0] == 32'h1) begin
      $display("DUT.data_array[31][32*0+31 : 32*0] is correct.                 Expected: %h, Actual: %h", 32'h1 ,DUT.data_array[31][32*0+31 : 32*0]); pass();
    end else begin
      $display("DUT.data_array[31][32*0+31 : 32*0] is incorrect.               Expected: %h, Actual: %h", 32'h1 ,DUT.data_array[31][32*0+31 : 32*0]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h2};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*1+31 : 32*1] == 32'h2) begin
      $display("DUT.data_array[31][32*1+31 : 32*1] is correct.                 Expected: %h, Actual: %h", 32'h2 ,DUT.data_array[31][32*1+31 : 32*1]); pass();
    end else begin
      $display("DUT.data_array[31][32*1+31 : 32*1] is incorrect.               Expected: %h, Actual: %h", 32'h2 ,DUT.data_array[31][32*1+31 : 32*1]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h3};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*2+31 : 32*2] == 32'h3) begin
      $display("DUT.data_array[31][32*2+31 : 32*2] is correct.                 Expected: %h, Actual: %h", 32'h3 ,DUT.data_array[31][32*2+31 : 32*2]); pass();
    end else begin
      $display("DUT.data_array[31][32*2+31 : 32*2] is incorrect.               Expected: %h, Actual: %h", 32'h3 ,DUT.data_array[31][32*2+31 : 32*2]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h4};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*3+31 : 32*3] == 32'h4) begin
      $display("DUT.data_array[31][32*3+31 : 32*3] is correct.                 Expected: %h, Actual: %h", 32'h4 ,DUT.data_array[31][32*3+31 : 32*3]); pass();
    end else begin
      $display("DUT.data_array[31][32*3+31 : 32*3] is incorrect.               Expected: %h, Actual: %h", 32'h4 ,DUT.data_array[31][32*3+31 : 32*3]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h5};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*4+31 : 32*4] == 32'h5) begin
      $display("DUT.data_array[31][32*4+31 : 32*4] is correct.                 Expected: %h, Actual: %h", 32'h5 ,DUT.data_array[31][32*4+31 : 32*4]); pass();
    end else begin
      $display("DUT.data_array[31][32*4+31 : 32*4] is incorrect.               Expected: %h, Actual: %h", 32'h5 ,DUT.data_array[31][32*4+31 : 32*4]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h6};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*5+31 : 32*5] == 32'h6) begin
      $display("DUT.data_array[31][32*5+31 : 32*5] is correct.                 Expected: %h, Actual: %h", 32'h6 ,DUT.data_array[31][32*5+31 : 32*5]); pass();
    end else begin
      $display("DUT.data_array[31][32*5+31 : 32*5] is incorrect.               Expected: %h, Actual: %h", 32'h6 ,DUT.data_array[31][32*5+31 : 32*5]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h7};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*6+31 : 32*6] == 32'h7) begin
      $display("DUT.data_array[31][32*6+31 : 32*6] is correct.                 Expected: %h, Actual: %h", 32'h7 ,DUT.data_array[31][32*6+31 : 32*6]); pass();
    end else begin
      $display("DUT.data_array[31][32*6+31 : 32*6] is incorrect.               Expected: %h, Actual: %h", 32'h7 ,DUT.data_array[31][32*6+31 : 32*6]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h8};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*7+31 : 32*7] == 32'h8) begin
      $display("DUT.data_array[31][32*7+31 : 32*7] is correct.                 Expected: %h, Actual: %h", 32'h8 ,DUT.data_array[31][32*7+31 : 32*7]); pass();
    end else begin
      $display("DUT.data_array[31][32*7+31 : 32*7] is incorrect.               Expected: %h, Actual: %h", 32'h8 ,DUT.data_array[31][32*7+31 : 32*7]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h9};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*8+31 : 32*8] == 32'h9) begin
      $display("DUT.data_array[31][32*8+31 : 32*8] is correct.                 Expected: %h, Actual: %h", 32'h9 ,DUT.data_array[31][32*8+31 : 32*8]); pass();
    end else begin
      $display("DUT.data_array[31][32*8+31 : 32*8] is incorrect.               Expected: %h, Actual: %h", 32'h9 ,DUT.data_array[31][32*8+31 : 32*8]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h10};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*9+31 : 32*9] == 32'h10) begin
      $display("DUT.data_array[31][32*9+31 : 32*9] is correct.                 Expected: %h, Actual: %h", 32'h10 ,DUT.data_array[31][32*9+31 : 32*9]); pass();
    end else begin
      $display("DUT.data_array[31][32*9+31 : 32*9] is incorrect.               Expected: %h, Actual: %h", 32'h10 ,DUT.data_array[31][32*9+31 : 32*9]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h11};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*10+31 : 32*10] == 32'h11) begin
      $display("DUT.data_array[31][32*10+31 : 32*10] is correct.                 Expected: %h, Actual: %h", 32'h11 ,DUT.data_array[31][32*10+31 : 32*10]); pass();
    end else begin
      $display("DUT.data_array[31][32*10+31 : 32*10] is incorrect.               Expected: %h, Actual: %h", 32'h11 ,DUT.data_array[31][32*10+31 : 32*10]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h122};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*11+31 : 32*11] == 32'h122) begin
      $display("DUT.data_array[31][32*11+31 : 32*11] is correct.                 Expected: %h, Actual: %h", 32'h122 ,DUT.data_array[31][32*11+31 : 32*11]); pass();
    end else begin
      $display("DUT.data_array[31][32*11+31 : 32*11] is incorrect.               Expected: %h, Actual: %h", 32'h122 ,DUT.data_array[31][32*11+31 : 32*11]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h133};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*12+31 : 32*12] == 32'h133) begin
      $display("DUT.data_array[31][32*12+31 : 32*12] is correct.                 Expected: %h, Actual: %h", 32'h133 ,DUT.data_array[31][32*12+31 : 32*12]); pass();
    end else begin
      $display("DUT.data_array[31][32*12+31 : 32*12] is incorrect.               Expected: %h, Actual: %h", 32'h133 ,DUT.data_array[31][32*12+31 : 32*12]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h144};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*13+31 : 32*13] == 32'h144) begin
      $display("DUT.data_array[31][32*13+31 : 32*13] is correct.                 Expected: %h, Actual: %h", 32'h144 ,DUT.data_array[31][32*13+31 : 32*13]); pass();
    end else begin
      $display("DUT.data_array[31][32*13+31 : 32*13] is incorrect.               Expected: %h, Actual: %h", 32'h144 ,DUT.data_array[31][32*13+31 : 32*13]); fail();
    end

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h155};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    assert(DUT.data_array[31][32*14+31 : 32*14] == 32'h155) begin
      $display("DUT.data_array[31][32*14+31 : 32*14] is correct.                 Expected: %h, Actual: %h", 32'h155 ,DUT.data_array[31][32*14+31 : 32*14]); pass();
    end else begin
      $display("DUT.data_array[31][32*14+31 : 32*14] is incorrect.               Expected: %h, Actual: %h", 32'h155 ,DUT.data_array[31][32*14+31 : 32*14]); fail();
    end
    memresp_rdy = 1;

    //refill:CACHE_MISS_SEND
    @(negedge clk); 
    cache_resp_msg = {3'b0, 8'b0, 2'b0 ,2'b0, 32'h101};
    //refill:CACHE_MISS_WAIT
    @(negedge clk); 
    // assert(DUT.data_array[31][32*15+31 : 32*15] == 32'h101) begin
    //   $display("DUT.data_array[31][32*15+31 : 32*15] is correct.                 Expected: %h, Actual: %h", 32'h101 ,DUT.data_array[31][32*15+31 : 32*15]); pass();
    // end else begin
    //   $display("DUT.data_array[31][32*15+31 : 32*15] is incorrect.               Expected: %h, Actual: %h", 32'h101 ,DUT.data_array[31][32*15+31 : 32*15]); fail();
    // end
    @(negedge clk); 
    //tag check
    assert(DUT.memreq_msg.data == DUT.data_array[Idx][Offset*32 +: 32]) begin
      $display("DUT.memresp_msg.data is correct.                 Expected: %h, Actual: %h", DUT.data_array[Idx][Offset*32 +: 32],DUT.memreq_msg.data); pass();
    end else begin
      $display("DUT.memresp_msg.data is incorrect.               Expected: %h, Actual: %h", DUT.data_array[Idx][Offset*32 +: 32],DUT.memreq_msg.data); fail();
    end


    //--------------------------------------------------------------------
    // Unit Testing #7 Read miss with refill and eviction  
    //--------------------------------------------------------------------
    // Align test bench with negedge so that it looks better
    reset=1;
    @(negedge clk); 
    $display( "Advancing time");
    memreq_msg.type_         = `VC_MEM_REQ_MSG_TYPE_READ;
    memreq_msg.opaque        = 8'h00;
    memreq_msg.addr          = 32'h0000ffff;//
    memreq_msg.len           = 0;
    memreq_msg.data          = 32'h0;
    Addr = 32'h0000ffff;
    Tag = Addr[31:11];
    Idx = Addr[10:6];
    Offset =Addr[5:2];
    #0.2
    memreq_val               = 1;
    memresp_rdy= 0;
    reset                    = 0;
    memreq_val               = 1;
    memresp_rdy              = 1;
    DUT.ditry_array[Idx]=1;
    //DUT.ditry_array_next[Idx]=1;
    DUT.valid_array[Idx]=1;
    #0.2
    cache_req_rdy = 1;
    //eviction: WRITE_BACK_SEND
    @(negedge clk); 
    assert(DUT.st_cur == DUT.WRITE_BACK_SEND) begin
      $display("DUT.st_cur is correct.                 Expected: %h, Actual: %h", DUT.WRITE_BACK_SEND,DUT.st_cur); pass();
    end else begin
      $display("DUT.st_cur is incorrect.               Expected: %h, Actual: %h", DUT.WRITE_BACK_SEND,DUT.st_cur); fail();
    end
    //eviction; WRITE_BACK_WAIT
    @(negedge clk); 
    assert(cache_req_msg.addr == {DUT.tag_array[DUT.idx],DUT.idx,DUT.count,2'b00}) begin
      $display("cache_req_msg.addr is correct.                 Expected: %h, Actual: %h", {DUT.tag_array[DUT.idx],DUT.idx,DUT.count,2'b00} ,cache_req_msg.addr); pass();
    end else begin
      $display("cache_req_msg.addr is incorrect.               Expected: %h, Actual: %h", {DUT.tag_array[DUT.idx],DUT.idx,DUT.count,2'b00} ,cache_req_msg.addr); fail();
    end
    assert(cache_req_msg.data == DUT.data_array[DUT.idx][31:0]) begin
      $display("cache_req_msg.data is correct.                 Expected: %h, Actual: %h", {DUT.tag_array[DUT.idx],DUT.idx,DUT.count,2'b00} ,cache_req_msg.data); pass();
    end else begin
      $display("cache_req_msg.data is incorrect.               Expected: %h, Actual: %h", {DUT.tag_array[DUT.idx],DUT.idx,DUT.count,2'b00} ,cache_req_msg.data); fail();
    end


    //eviction: WRITE_BACK_SEND
    @(negedge clk); 
    assert(DUT.st_cur == DUT.WRITE_BACK_SEND) begin
      $display("DUT.st_cur is correct.                 Expected: %h, Actual: %h", DUT.WRITE_BACK_SEND,DUT.st_cur); pass();
    end else begin
      $display("DUT.st_cur is incorrect.               Expected: %h, Actual: %h", DUT.WRITE_BACK_SEND,DUT.st_cur); fail();
    end
    //eviction; WRITE_BACK_WAIT

    assert(cache_req_msg.addr == {DUT.tag_array[DUT.idx],DUT.idx,DUT.count,2'b00}) begin
      $display("cache_req_msg.addr is correct.                 Expected: %h, Actual: %h", {DUT.tag_array[DUT.idx],DUT.idx,DUT.count,2'b00} ,cache_req_msg.addr); pass();
    end else begin
      $display("cache_req_msg.addr is incorrect.               Expected: %h, Actual: %h", {DUT.tag_array[DUT.idx],DUT.idx,DUT.count,2'b00} ,cache_req_msg.addr); fail();
    end


    #10





    $finish();

  end

  
endmodule
