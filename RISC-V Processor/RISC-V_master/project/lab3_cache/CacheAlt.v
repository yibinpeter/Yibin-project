//=========================================================================
// Cache Base Design
//=========================================================================

`ifndef LAB3_CACHE_CACHE_ALT_V
`define LAB3_CACHE_CACHE_ALT_V

`include "vc/mem-msgs.v"

// // memory request type values
`define VC_MEM_REQ_MSG_TYPE_READ     3'd0
`define VC_MEM_REQ_MSG_TYPE_WRITE    3'd1


module lab3_cache_CacheAlt
(
  input  logic                    clk,
  input  logic                    reset,


  // imem cpu
  input  logic                    memreq_val,
  output logic                    memreq_rdy,
  input  mem_req_4B_t             memreq_msg,

  output logic                    memresp_val,
  input  logic                    memresp_rdy,
  output mem_resp_4B_t            memresp_msg,

  //cache mem
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

//valid array
logic [31:0] valid_array;
logic [31:0] valid_array_next;

logic [31:0] valid_array_1;
logic [31:0] valid_array_next_1;


//dirty array 
logic  [31:0] ditry_array;
logic  [31:0] ditry_array_next;

logic  [31:0] ditry_array_1;
logic  [31:0] ditry_array_next_1;

// Tag array 
logic [20:0] tag_array[31:0]; 
logic [20:0] tag_array_next[31:0];

logic [20:0] tag_array_1[31:0]; 
logic [20:0] tag_array_next_1[31:0];


// Data array 
logic [511:0] data_array[31:0]; 
logic [511:0] data_array_next[31:0]; 

logic [511:0] data_array_1[31:0]; 
logic [511:0] data_array_next_1[31:0]; 


logic [31:0] SET; 
logic [31:0] SET_next; 

logic [31:0] LRU; 
logic [31:0] LRU_next; 

logic flush_set_count;
logic flush_set_count_next;


logic [2:0]  CI_type;
logic [7:0]  CI_opaque;
logic [31:0] CI_addr;
logic [1:0]  CI_len;
logic [31:0] CI_data;

logic [2:0]  CO_type;
logic [7:0]  CO_opaque;
logic [1:0]  CO_test;
logic [1:0]  CO_len;
logic [31:0] CO_data;

logic [2:0]  MI_type;
logic [7:0]  MI_opaque;
logic [31:0]  MI_addr;
logic [1:0]  MI_len;
logic [31:0] MI_data;

logic [2:0]  MO_type;
logic [7:0]  MO_opaque;
logic [1:0]  MO_test;
logic [1:0]  MO_len;
logic [31:0] MO_data;

logic [20:0] tag;
logic [4:0]  idx;
logic [3:0]  offset;




// memreq_msg decode; 
assign {CI_type, CI_opaque, CI_addr, CI_len, CI_data} = memreq_msg;

//***************************************FSM***********************************************
//machine variable
logic [3:0]            st_next ;
logic [3:0]            st_cur ;

logic [3:0]            count_next;
logic [3:0]            count;

logic [4:0]            count_flush_next;
logic [4:0]            count_flush;



parameter IDLE = 0 ;
parameter TAG_CHECK = 1;
parameter CACHE_MISS_SEND = 2;
parameter CACHE_MISS_WAIT = 3;
parameter WRITE_BACK_SEND = 4;
parameter WRITE_BACK_WAIT = 5;
parameter FLUSH_SEND      = 6;
parameter FLUSH_WAIT      = 7;
parameter FLUSH_START      = 8;


//(1) state transfer
always_ff @(posedge clk) begin
    if (reset) begin
        st_cur      <= TAG_CHECK ;
        count_flush <= 0 ;
        count       <= 0;
        // valid_array <= 32'b0;

    end
    else begin
        st_cur      <= st_next ;
        count       <= count_next;
        valid_array <= valid_array_next;
        valid_array_1 <= valid_array_next_1;
        ditry_array <= ditry_array_next;
        ditry_array_1 <= ditry_array_next_1;
        data_array  <= data_array_next;
        data_array_1  <= data_array_next_1;
        tag_array   <= tag_array_next;
        tag_array_1   <= tag_array_next_1;
        count_flush <= count_flush_next;
        count <= count_next; 
        LRU <= LRU_next;
        flush_set_count <= flush_set_count_next;
    end
end



always_comb begin
    case(st_cur)
        TAG_CHECK : begin
          // which set hit 
          if(memreq_val) {tag, idx, offset} = memreq_msg.addr[31:2];


          if(memreq_val) begin
          if(tag_array[idx] == tag && valid_array[idx]) SET[idx] = 0;
          else if(tag_array_1[idx] == tag && valid_array_1[idx])  SET[idx]= 1;
          else SET[idx] = LRU[idx];
        end



          // flush ? 
          if(flush) st_next = FLUSH_START;
          // Ready to recive 
          else if (memreq_val) begin
            // least 0 
            if(SET[idx]) begin
            // HIt
            if(valid_array_1[idx] && tag == tag_array_1[idx]) st_next = TAG_CHECK;
            // MISS
            else st_next = ditry_array_1[idx] ? WRITE_BACK_SEND : CACHE_MISS_SEND;
            LRU_next[idx] = 1;
            end 
            // least 1
            else begin
            // HIt
            if(valid_array[idx] && tag == tag_array[idx]) st_next = TAG_CHECK;
            // MISS
            else st_next = ditry_array[idx] ? WRITE_BACK_SEND : CACHE_MISS_SEND;
            end
            LRU_next[idx] = 0;
          end
          else st_next = TAG_CHECK;
        end

        
        CACHE_MISS_SEND: begin
          if(cache_req_rdy) st_next = CACHE_MISS_WAIT;
          else st_next = CACHE_MISS_SEND;
        end

        CACHE_MISS_WAIT: begin
          if(count == 15    && memresp_rdy) st_next = TAG_CHECK;
          else if(count < 15 && cache_resp_val   ) st_next = CACHE_MISS_SEND;
          else st_next = CACHE_MISS_WAIT;
        end


        WRITE_BACK_SEND: begin
          if(cache_req_rdy) st_next = WRITE_BACK_WAIT;
          else st_next = WRITE_BACK_SEND;
        end

        WRITE_BACK_WAIT: begin
          if(count == 15 && cache_resp_val   ) st_next = CACHE_MISS_SEND;
          else if(count < 15 && cache_resp_val   ) st_next = WRITE_BACK_SEND;
          else st_next = WRITE_BACK_WAIT;
        end


        FLUSH_SEND : begin
          if(cache_req_rdy) st_next = FLUSH_WAIT;
          else st_next = FLUSH_SEND;
        end

        FLUSH_WAIT: begin
          if(count == 15 && cache_resp_val   ) st_next = FLUSH_START;
          else if(count < 15 && cache_resp_val   ) st_next = FLUSH_SEND;
          else st_next = FLUSH_WAIT;
        end

        FLUSH_START : begin
          if(flush_set_count == 0) begin
             st_next = (count_flush == 31 && flush_set_count == 1) ? TAG_CHECK : 
                    ((ditry_array[count_flush]) ? FLUSH_SEND : FLUSH_START);    
          end
          else begin
            st_next = (count_flush == 31 && flush_set_count == 1) ? TAG_CHECK : 
            ((ditry_array_1[count_flush]) ? FLUSH_SEND : FLUSH_START);    
          end        

        end

        default:    st_next = TAG_CHECK ;
    endcase
end


//(3) output logic, using non-block assignment
always_comb begin
  case(st_cur)

  TAG_CHECK : begin
    if(SET[idx]) begin
      if(memreq_val) begin
        // HIT
        if(valid_array_1[idx] && tag == tag_array_1[idx]) begin
          // if CPU has take the Data or Not 
          memreq_rdy = memresp_rdy ? 1: 0;
          memresp_val = 1;
        end 
        // MISS
        else begin
          memreq_rdy = 0;
          memresp_val = 0;
        end
      end
      else begin
        memreq_rdy = 1;
        memresp_val = 0;
      end
    end
    else begin
        if(memreq_val) begin
        // HIT
        if(valid_array[idx] && tag == tag_array[idx]) begin
          // if CPU has take the Data or Not 
          memreq_rdy = memresp_rdy ? 1: 0;
          memresp_val = 1;
        end 
        // MISS
        else begin
          memreq_rdy = 0;
          memresp_val = 0;
        end
      end
      else begin
        memreq_rdy = 1;
        memresp_val = 0;
      end
    end
  end


  CACHE_MISS_SEND : begin
    memreq_rdy = 0;
    memresp_val = 0;
    cache_req_val = 1;
    cache_resp_rdy = 0;
  end

  CACHE_MISS_WAIT : begin
    cache_req_val  = 0;
    cache_resp_rdy = 1;
    if(count == 15) begin
        memresp_val = 1;
        memreq_rdy = 1;
    end
  end


  WRITE_BACK_SEND : begin
    memreq_rdy = 0;
    cache_req_val = 1;
    cache_resp_rdy = 0;
    memresp_val = 0;
  end

  WRITE_BACK_WAIT : begin
    cache_req_val  = 0;
    cache_resp_rdy = 1;
  end


  FLUSH_SEND : begin
    memreq_rdy = 0;
    cache_req_val = 1;
    cache_resp_rdy = 0;
    memresp_val = 0;
  end

  FLUSH_WAIT : begin
    cache_req_val  = 0;
    cache_resp_rdy = 1;
  end

  FLUSH_START : begin
    if(count_flush == 31 && flush_set_count == 1) flush_done = 1;
  end

endcase
end


//(3) output logic, using non-block assignment
always_comb begin
  case(st_cur)

  TAG_CHECK : begin
    
    if(SET[idx]) begin
      count_next = 0;
      // Output the values if hit and CPU ready to recive signal 
      if(tag == tag_array_1[idx] && valid_array_1[idx] && memresp_rdy) begin
        if(memreq_msg.type_ == `VC_MEM_REQ_MSG_TYPE_WRITE) begin
          data_array_next_1[idx][offset*32 +: 32] = memreq_msg.data;
          ditry_array_next_1[idx] = 1;
        end else begin 
          memresp_msg.data = data_array_1[idx][offset*32 +: 32];
        end
      end
    end
    else begin
      // reset count before miss or WB
      count_next = 0;
      // If valid request, read in the msg 
      // Output the values if hit and CPU ready to recive signal 
      if(tag == tag_array[idx] && valid_array[idx] && memresp_rdy) begin
        if(memreq_msg.type_ == `VC_MEM_REQ_MSG_TYPE_WRITE) begin
          data_array_next[idx][offset*32 +: 32] = memreq_msg.data;
          ditry_array_next[idx] = 1;
        end else begin 
          memresp_msg.data = data_array[idx][offset*32 +: 32];
        end
      end
    end
  end

  CACHE_MISS_SEND : begin
    MI_type = `VC_MEM_REQ_MSG_TYPE_READ;
    MI_opaque = {4'd1, count};
    MI_addr = {tag, idx, count, 2'b00};
    MI_len  = 2'b0;
    MI_data = 32'b0;
    cache_req_msg = {MI_type, MI_opaque, MI_addr, MI_len, MI_data};
  end

  CACHE_MISS_WAIT : begin
    if(SET[idx]) begin
      // If the count < 15 
      if(count < 15 && cache_resp_val) begin
        MO_opaque = cache_resp_msg.opaque;
        MO_data   = cache_resp_msg.data;
        count_next = count + 1;
        data_array_next_1[idx][count*32 +: 32] =  cache_resp_msg.data;
      end
      else if(count == 15 && cache_resp_val)begin
        data_array_next_1[idx][count*32 +: 32] =  cache_resp_msg.data;
      end 
      else begin
        count_next = count;
        data_array_next_1[idx] = data_array_1[idx];
      end


      if(count == 15  && memresp_rdy) begin
        MO_opaque = cache_resp_msg.opaque;
        MO_data   = cache_resp_msg.data;
        // write in to output
        memresp_msg.data = data_array_1[idx][offset*32 +: 32];
        memresp_msg.type_ = cache_resp_msg.type_;
        memresp_msg.opaque =  cache_resp_msg.opaque;
        memresp_msg.test =  cache_resp_msg.test;
        memresp_msg.len =  cache_resp_msg.len;
        // write back to array
        tag_array_next_1[idx] = tag;
        valid_array_next_1[idx] = 1;
        // read or write
        ditry_array_next_1[idx] = (memreq_msg.type_ == `VC_MEM_REQ_MSG_TYPE_WRITE) ? 1 : 0;
        data_array_next_1[idx][offset*32 +: 32] = (memreq_msg.type_ == `VC_MEM_REQ_MSG_TYPE_WRITE) ? memreq_msg.data : data_array_1[idx][offset*32 +: 32];
      end
    end
    else begin
            // If the count < 15 
      if(count < 15 && cache_resp_val) begin
        MO_opaque = cache_resp_msg.opaque;
        MO_data   = cache_resp_msg.data;
        count_next = count + 1;
        data_array_next[idx][count*32 +: 32] =  cache_resp_msg.data;
      end
      else if(count == 15 && cache_resp_val)begin
        data_array_next[idx][count*32 +: 32] =  cache_resp_msg.data;
      end 
      else begin
        count_next = count;
        data_array_next[idx] = data_array[idx];
      end


      if(count == 15  && memresp_rdy) begin
        MO_opaque = cache_resp_msg.opaque;
        MO_data   = cache_resp_msg.data;
        // write in to output
        memresp_msg.data = data_array[idx][offset*32 +: 32];
        memresp_msg.type_ = cache_resp_msg.type_;
        memresp_msg.opaque =  cache_resp_msg.opaque;
        memresp_msg.test =  cache_resp_msg.test;
        memresp_msg.len =  cache_resp_msg.len;
        // write back to array
        tag_array_next[idx] = tag;
        valid_array_next[idx] = 1;
        // read or write
        ditry_array_next[idx] = (memreq_msg.type_ == `VC_MEM_REQ_MSG_TYPE_WRITE) ? 1 : 0;
        data_array_next[idx][offset*32 +: 32] = (memreq_msg.type_ == `VC_MEM_REQ_MSG_TYPE_WRITE) ? memreq_msg.data : data_array[idx][offset*32 +: 32];
      end
    end
  end

WRITE_BACK_SEND : begin
    if(SET[idx]) begin
      MI_type = `VC_MEM_REQ_MSG_TYPE_WRITE;
      MI_opaque = {4'd1, count};
      MI_addr = {tag_array_1[idx], idx, count, 2'b00};
      MI_len  = 2'b0;
      MI_data = data_array_1[idx][count*32 +: 32];
      cache_req_msg = {MI_type, MI_opaque, MI_addr, MI_len, MI_data};
    end
    else begin
      MI_type = `VC_MEM_REQ_MSG_TYPE_WRITE;
      MI_opaque = {4'd1, count};
      MI_addr = {tag_array[idx], idx, count, 2'b00};
      MI_len  = 2'b0;
      MI_data = data_array[idx][count*32 +: 32];
      cache_req_msg = {MI_type, MI_opaque, MI_addr, MI_len, MI_data};
    end
  end

  WRITE_BACK_WAIT : begin
    if( cache_resp_val   ) begin
      count_next = count + 1;
    end
    else begin
      count_next = count;
    end
  end


FLUSH_SEND : begin
    if(flush_set_count == 1) begin
      MI_type = `VC_MEM_REQ_MSG_TYPE_WRITE;
      MI_opaque = {4'd1, count};
      MI_addr = {tag_array_1[count_flush], count_flush, count, 2'b00};
      MI_len  = 2'b0;
      MI_data = data_array_1[count_flush][count*32 +: 32];
      cache_req_msg = {MI_type, MI_opaque, MI_addr, MI_len, MI_data};
    end
    else begin
      MI_type = `VC_MEM_REQ_MSG_TYPE_WRITE;
      MI_opaque = {4'd1, count};
      MI_addr = {tag_array[count_flush], count_flush, count, 2'b00};
      MI_len  = 2'b0;
      MI_data = data_array[count_flush][count*32 +: 32];
      cache_req_msg = {MI_type, MI_opaque, MI_addr, MI_len, MI_data};
    end
  end

  FLUSH_WAIT : begin
    if(cache_resp_val   ) begin
      count_next = count + 1;
      count_flush_next = (count == 15) ?  count_flush + 1 : count_flush;
    end
    else begin
      count_next = count;
    end
  end


  FLUSH_START : begin

    if(count_flush == 31 && flush_set_count == 0) begin
      flush_set_count_next = flush_set_count + 1;
    end

    if(flush_set_count == 1) begin
    count_flush_next = (ditry_array_1[count_flush]) ? count_flush : count_flush + 1;
    end
    else begin
    count_flush_next = (ditry_array[count_flush]) ? count_flush : count_flush + 1;
    end
  end

endcase
end


endmodule

`endif /* LAB3_CACHE_CACHE_ALT_V */
