//=========================================================================
// Cache with both base and alt design for I and D cache
//=========================================================================

`ifndef LAB3_CACHE_CACHE_ALL_V
`define LAB3_CACHE_CACHE_ALL_V

`include "vc/mem-msgs.v"
`include "CacheBypass.v"
`include "CacheBase.v"
`include "CacheAlt.v"

module lab3_cache_CacheAll
(
  input  logic                    clk,
  input  logic                    reset,


  // imem

  input  logic                    imemreq_val,
  output logic                    imemreq_rdy,
  input  mem_req_4B_t             imemreq_msg,

  // dmem

  input  logic                    dmemreq_val,
  output logic                    dmemreq_rdy,
  input  mem_req_4B_t             dmemreq_msg,

  // imem

  output logic                    imemresp_val,
  input  logic                    imemresp_rdy,
  output mem_resp_4B_t            imemresp_msg,

  // dmem
  output logic                    dmemresp_val,
  input  logic                    dmemresp_rdy,
  output mem_resp_4B_t            dmemresp_msg,

  //cache
  output  logic                    cache0_req_val,
  input   logic                    cache0_req_rdy,
  output  mem_req_4B_t             cache0_req_msg,
 
  input  logic                     cache0_resp_val,
  output logic                     cache0_resp_rdy,
  input  mem_resp_4B_t             cache0_resp_msg,

  output  logic                    cache1_req_val,
  input   logic                    cache1_req_rdy,
  output  mem_req_4B_t             cache1_req_msg,
 
  input  logic                    cache1_resp_val,
  output logic                    cache1_resp_rdy,
  input  mem_resp_4B_t            cache1_resp_msg,

  // flush
  input logic                     flush,
  output logic                    flush_done
);
logic flush_done1, flush_done2;
assign  flush_done = flush_done1 & flush_done2;

lab3_cache_CacheBase
icache (
  .clk(clk),
  .reset(reset),  
  
  // input request interface 
  .memreq_val(imemreq_val),
  .memreq_rdy(imemreq_rdy),
  .memreq_msg(imemreq_msg),

  // input response interface 
  .memresp_val(imemresp_val),
  .memresp_rdy(imemresp_rdy),
  .memresp_msg(imemresp_msg),

  
  // Memory interface 
  .cache_req_val(cache0_req_val),
  .cache_req_rdy(cache0_req_rdy),
  .cache_req_msg(cache0_req_msg),

  .cache_resp_val(cache0_resp_val),
  .cache_resp_rdy(cache0_resp_rdy),
  .cache_resp_msg(cache0_resp_msg),

  .flush(flush),
  .flush_done(flush_done1)
);

lab3_cache_CacheAlt
dcache (
  .clk(clk),
  .reset(reset),  
  
  // input request interface 
  .memreq_val(dmemreq_val),
  .memreq_rdy(dmemreq_rdy),
  .memreq_msg(dmemreq_msg),

  // input response interface 
  .memresp_val(dmemresp_val),
  .memresp_rdy(dmemresp_rdy),
  .memresp_msg(dmemresp_msg),
  
  // Memory interface 
  .cache_req_val(cache1_req_val),
  .cache_req_rdy(cache1_req_rdy),
  .cache_req_msg(cache1_req_msg),

  .cache_resp_val(cache1_resp_val),
  .cache_resp_rdy(cache1_resp_rdy),
  .cache_resp_msg(cache1_resp_msg),

  .flush(flush),
  .flush_done(flush_done2)
);


endmodule


`endif /* LAB3_CACHE_CACHE_BYPASS_V */
