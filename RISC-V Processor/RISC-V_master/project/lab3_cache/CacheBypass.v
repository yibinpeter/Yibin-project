//=========================================================================
// Cache Bypass FL Module
//=========================================================================

`ifndef LAB3_CACHE_CACHE_BYPASS_V
`define LAB3_CACHE_CACHE_BYPASS_V

`include "vc/mem-msgs.v"

module lab3_cache_CacheBypass
(
  input  logic                    clk,
  input  logic                    reset,


  // imem

  input  logic                    memreq_val,
  output logic                    memreq_rdy,
  input  mem_req_4B_t             memreq_msg,

  output logic                    memresp_val,
  input  logic                    memresp_rdy,
  output mem_resp_4B_t            memresp_msg,

  //cache
  output  logic                    cache_req_val,
  input   logic                    cache_req_rdy,
  output  mem_req_4B_t             cache_req_msg,
 
  input  logic                     cache_resp_val,
  output logic                     cache_resp_rdy,
  input  mem_resp_4B_t             cache_resp_msg,


  // flush
  input logic                     flush,
  output logic                    flush_done
);

assign cache_req_val = memreq_val;
assign memreq_rdy = cache_req_rdy;
assign cache_req_msg = memreq_msg;

assign memresp_val = cache_resp_val;
assign cache_resp_rdy = memresp_rdy;
assign memresp_msg = cache_resp_msg;
assign flush_done = flush;

endmodule


`endif /* LAB3_CACHE_CACHE_BYPASS_V */
