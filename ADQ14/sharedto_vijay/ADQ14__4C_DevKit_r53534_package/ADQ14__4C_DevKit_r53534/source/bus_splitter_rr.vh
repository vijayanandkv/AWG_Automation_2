/* -*- coding: us-ascii-dos -*-
 *
 * Copyright Signal Processing Devices Sweden AB. All rights reserved.
 * See document "08-0175 EULA" for specific license terms regarding this file.
 *
 * Description   : Bus extraction macros, reduced rate
 * Documentation :
 *
 */

/* Must be defined by user before including this file
localparam           BUS_PIPELINE = 1;

wire                      s_axis_aclk;
wire [RR_DATA_BUS_WIDTH-1:0] s_axis_tdata
wire                      s_axis_tvalid;
reg [RR_DATA_BUS_WIDTH-1:0]  m_axis_tdata
reg                       m_axis_tvalid
*/


// RR Bus format:
// DATA   = $SPD_PARALLEL_SAMPLES * $SPD_DATAWIDTH_BITS
// CHT    = $RR_SPD_NUM_CH_TRIG_BITS + $RR_SPD_NUM_TRIG_ADDBITS  + $RR_SPD_NUM_TRIG_DATARD_ADDFRACBITS
// RECORD = $RR_SPD_DATABUSRD_RECORDBITS_WIDTH
// VALID  = $RR_SPD_DATABUSRD_DVALID
// AUX    = $RR_SPD_NUM_AUX_TRIG_BITS + $RR_SPD_NUM_TRIG_ADDBITS + $RR_SPD_NUM_TRIG_DATARD_ADDFRACBITS
// TS     = $RR_SPD_TIMESTAMP_WIDTH_BITS
// OR     = OVER RANGE
// UI     = USer ID
// GP     = General purpose bits

// NOTE: VALID should alwas be last bit!
// BUS    = $SPD_PROCESSING_CHANNELS_FULL * {VALID, GP, UI, OR, CNT, RECORD, CHT, DATA}, AUX, TS

`include "bus_splitter_rr_param.vh"

// Output
`ifndef DISABLE_OUTPUT_RR
wire [RR_DATA_BUS_WIDTH:0] user_bus_o_default;
reg  [RR_DATA_BUS_WIDTH:0] user_bus_o;

generate
   reg [RR_DATA_BUS_WIDTH:0] bus_pipeline[BUS_PIPELINE-1:0];

   if (BUS_PIPELINE > 0)
     begin
        always@(posedge s_axis_aclk)
          begin : bus_pipeline_inst
             integer i;
             bus_pipeline[0][RR_DATA_BUS_WIDTH]      <= s_axis_tvalid;
             bus_pipeline[0][RR_DATA_BUS_WIDTH-1:0]  <= s_axis_tdata;
             if (BUS_PIPELINE > 1)
               for (i=0; i<BUS_PIPELINE-1; i=i+1)
                 bus_pipeline[i+1]   <= bus_pipeline[i];

          end
     end
   else
     ; //ERROR

   assign user_bus_o_default = bus_pipeline[BUS_PIPELINE-1];
endgenerate

task init_bus_output;
   begin
      user_bus_o = user_bus_o_default;
   end
endtask

task finish_bus_output;
   begin
      m_axis_tdata  = user_bus_o[RR_DATA_BUS_WIDTH-1:0];
      m_axis_tvalid = user_bus_o[RR_DATA_BUS_WIDTH];
   end
endtask


task insert_trig_inhibit;
   input [RR_SPD_TRIGGER_INHIBIT_BITS-1:0] trig_inhibit;
   user_bus_o[0 +: RR_SPD_TRIGGER_INHIBIT_BITS] = trig_inhibit;
endtask

task insert_aux_trig;
   input [RR_AUX_TRIG_VECTOR_WIDTH-1:0] vector;
   user_bus_o[RR_SPD_TRIGGER_INHIBIT_BITS +: RR_AUX_TRIG_VECTOR_WIDTH] = vector;
endtask

task insert_gate_cnt;
   input [RR_SPD_GATE_CNT_WIDTH-1:0] vector;
   user_bus_o[RR_SPD_TRIGGER_INHIBIT_BITS + RR_AUX_TRIG_VECTOR_WIDTH +: RR_SPD_GATE_CNT_WIDTH] = vector;
endtask

//Data valid

task insert_data_valid;
   input valid;
   input integer ch;
   if(ch < SPD_PROCESSING_CHANNELS_FULL)
     user_bus_o[RR_CH_FIRST_BIT + ch*RR_CH_WIDTH + RR_CH_WIDTH-1 +: 1] = valid;
endtask

task insert_data_valid_a;
   input valid;
                                user_bus_o[RR_CH_FIRST_BIT + CH_A*RR_CH_WIDTH + RR_CH_WIDTH-1 +: 1] = valid;
endtask
task insert_data_valid_b;
   input valid;
   if (SPD_PROCESSING_CHANNELS_FULL > 1) user_bus_o[RR_CH_FIRST_BIT + CH_B*RR_CH_WIDTH + RR_CH_WIDTH-1 +: 1] = valid;
endtask
task insert_data_valid_c;
   input valid;
   if (SPD_PROCESSING_CHANNELS_FULL > 2) user_bus_o[RR_CH_FIRST_BIT + CH_C*RR_CH_WIDTH + RR_CH_WIDTH-1 +: 1] = valid;
endtask
task insert_data_valid_d;
   input valid;
   if (SPD_PROCESSING_CHANNELS_FULL > 3) user_bus_o[RR_CH_FIRST_BIT + CH_D*RR_CH_WIDTH + RR_CH_WIDTH-1 +: 1] = valid;
endtask


task insert_ch_all;
   input [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data;
   input integer ch;
   user_bus_o[RR_CH_FIRST_BIT + ch * RR_CH_WIDTH +: SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS] = data;
endtask

task insert_ch_a_all;
   input [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data;
   user_bus_o[RR_CH_FIRST_BIT + CH_A * RR_CH_WIDTH +: SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS] = data;
endtask
task insert_ch_b_all;
   input [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data;
   user_bus_o[RR_CH_FIRST_BIT + CH_B * RR_CH_WIDTH +: SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS] = data;
endtask
task insert_ch_c_all;
   input [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data;
   user_bus_o[RR_CH_FIRST_BIT + CH_C * RR_CH_WIDTH +: SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS] = data;
endtask
task insert_ch_d_all;
   input [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data;
   user_bus_o[RR_CH_FIRST_BIT + CH_D * RR_CH_WIDTH +: SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS] = data;
endtask


task insert_ch_a;
   input [SPD_DATAWIDTH_BITS-1:0] data;
   input integer idx;
   begin
      case (idx)
        0:                              user_bus_o[RR_CH_FIRST_BIT + CH_A * RR_CH_WIDTH + 0*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
        1:if (SPD_PARALLEL_SAMPLES > 1) user_bus_o[RR_CH_FIRST_BIT + CH_A * RR_CH_WIDTH + 1*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
        2:if (SPD_PARALLEL_SAMPLES > 2) user_bus_o[RR_CH_FIRST_BIT + CH_A * RR_CH_WIDTH + 2*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
        3:if (SPD_PARALLEL_SAMPLES > 3) user_bus_o[RR_CH_FIRST_BIT + CH_A * RR_CH_WIDTH + 3*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
        4:if (SPD_PARALLEL_SAMPLES > 4) user_bus_o[RR_CH_FIRST_BIT + CH_A * RR_CH_WIDTH + 4*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
        5:if (SPD_PARALLEL_SAMPLES > 5) user_bus_o[RR_CH_FIRST_BIT + CH_A * RR_CH_WIDTH + 5*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
        6:if (SPD_PARALLEL_SAMPLES > 6) user_bus_o[RR_CH_FIRST_BIT + CH_A * RR_CH_WIDTH + 6*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
        7:if (SPD_PARALLEL_SAMPLES > 7) user_bus_o[RR_CH_FIRST_BIT + CH_A * RR_CH_WIDTH + 7*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;

      endcase
   end
endtask

task insert_ch_b;
   input [SPD_DATAWIDTH_BITS-1:0] data;
   input integer idx;
   if (SPD_PROCESSING_CHANNELS_FULL > 1)
     begin
        case (idx)
          0:                              user_bus_o[RR_CH_FIRST_BIT + CH_B * RR_CH_WIDTH + 0*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          1:if (SPD_PARALLEL_SAMPLES > 1) user_bus_o[RR_CH_FIRST_BIT + CH_B * RR_CH_WIDTH + 1*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          2:if (SPD_PARALLEL_SAMPLES > 2) user_bus_o[RR_CH_FIRST_BIT + CH_B * RR_CH_WIDTH + 2*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          3:if (SPD_PARALLEL_SAMPLES > 3) user_bus_o[RR_CH_FIRST_BIT + CH_B * RR_CH_WIDTH + 3*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          4:if (SPD_PARALLEL_SAMPLES > 4) user_bus_o[RR_CH_FIRST_BIT + CH_B * RR_CH_WIDTH + 4*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          5:if (SPD_PARALLEL_SAMPLES > 5) user_bus_o[RR_CH_FIRST_BIT + CH_B * RR_CH_WIDTH + 5*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          6:if (SPD_PARALLEL_SAMPLES > 6) user_bus_o[RR_CH_FIRST_BIT + CH_B * RR_CH_WIDTH + 6*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          7:if (SPD_PARALLEL_SAMPLES > 7) user_bus_o[RR_CH_FIRST_BIT + CH_B * RR_CH_WIDTH + 7*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;

        endcase
     end
endtask

task insert_ch_c;
   input [SPD_DATAWIDTH_BITS-1:0] data;
   input integer idx;
   if (SPD_PROCESSING_CHANNELS_FULL > 2)
     begin
        case (idx)
          0:                              user_bus_o[RR_CH_FIRST_BIT + CH_C * RR_CH_WIDTH + 0*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          1:if (SPD_PARALLEL_SAMPLES > 1) user_bus_o[RR_CH_FIRST_BIT + CH_C * RR_CH_WIDTH + 1*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          2:if (SPD_PARALLEL_SAMPLES > 2) user_bus_o[RR_CH_FIRST_BIT + CH_C * RR_CH_WIDTH + 2*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          3:if (SPD_PARALLEL_SAMPLES > 3) user_bus_o[RR_CH_FIRST_BIT + CH_C * RR_CH_WIDTH + 3*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          4:if (SPD_PARALLEL_SAMPLES > 4) user_bus_o[RR_CH_FIRST_BIT + CH_C * RR_CH_WIDTH + 4*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          5:if (SPD_PARALLEL_SAMPLES > 5) user_bus_o[RR_CH_FIRST_BIT + CH_C * RR_CH_WIDTH + 5*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          6:if (SPD_PARALLEL_SAMPLES > 6) user_bus_o[RR_CH_FIRST_BIT + CH_C * RR_CH_WIDTH + 6*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          7:if (SPD_PARALLEL_SAMPLES > 7) user_bus_o[RR_CH_FIRST_BIT + CH_C * RR_CH_WIDTH + 7*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;

        endcase
   end
endtask

task insert_ch_d;
   input [SPD_DATAWIDTH_BITS-1:0] data;
   input integer                  idx;
   if (SPD_PROCESSING_CHANNELS_FULL > 3)
     begin
        case (idx)
          0:                              user_bus_o[RR_CH_FIRST_BIT + CH_D * RR_CH_WIDTH + 0*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          1:if (SPD_PARALLEL_SAMPLES > 1) user_bus_o[RR_CH_FIRST_BIT + CH_D * RR_CH_WIDTH + 1*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          2:if (SPD_PARALLEL_SAMPLES > 2) user_bus_o[RR_CH_FIRST_BIT + CH_D * RR_CH_WIDTH + 2*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          3:if (SPD_PARALLEL_SAMPLES > 3) user_bus_o[RR_CH_FIRST_BIT + CH_D * RR_CH_WIDTH + 3*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
	  4:if (SPD_PARALLEL_SAMPLES > 4) user_bus_o[RR_CH_FIRST_BIT + CH_D * RR_CH_WIDTH + 4*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          5:if (SPD_PARALLEL_SAMPLES > 5) user_bus_o[RR_CH_FIRST_BIT + CH_D * RR_CH_WIDTH + 5*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          6:if (SPD_PARALLEL_SAMPLES > 6) user_bus_o[RR_CH_FIRST_BIT + CH_D * RR_CH_WIDTH + 6*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          7:if (SPD_PARALLEL_SAMPLES > 7) user_bus_o[RR_CH_FIRST_BIT + CH_D * RR_CH_WIDTH + 7*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;

        endcase
     end
endtask

task insert_ch_trig_vector;
   input [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] data;
   input integer ch;
   if(ch < SPD_PROCESSING_CHANNELS_FULL)
     user_bus_o[RR_CH_FIRST_BIT + ch * RR_CH_WIDTH + SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS +: RR_CH_TRIG_VECTOR_1_WIDTH] = data;
endtask

task insert_ch_trig_vector_a;
   input [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] data;
   begin
      insert_ch_trig_vector(data, CH_A);
   end
endtask
task insert_ch_trig_vector_b;
   input [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] data;
   begin
      insert_ch_trig_vector(data, CH_B);
   end
endtask
task insert_ch_trig_vector_c;
   input [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] data;
   begin
      insert_ch_trig_vector(data, CH_C);
   end
endtask
task insert_ch_trig_vector_d;
   input [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] data;
   begin
      insert_ch_trig_vector(data, CH_D);
   end
endtask


task insert_ch_over_range;
   input  data;
   input integer ch;
   if(ch < SPD_PROCESSING_CHANNELS_FULL)
     user_bus_o[RR_CH_FIRST_BIT + ch * RR_CH_WIDTH + RR_CH_POS_OVER_RANGE +: RR_SPD_OVER_RANGE_1_WIDTH] = data;
endtask

task insert_over_range_a;
   input data;
   begin
      insert_ch_over_range(data, CH_A);
   end
endtask
task insert_over_range_b;
   input data;
   begin
      insert_ch_over_range(data, CH_B);
   end
endtask
task insert_over_range_c;
   input data;
   begin
      insert_ch_over_range(data, CH_C);
   end
endtask
task insert_over_range_d;
   input data;
   begin
      insert_ch_over_range(data, CH_D);
   end
endtask


task insert_record_bits;
  input [RR_SPD_NUM_RECORDBITS-1:0] data;
  input integer ch;
  if(ch < SPD_PROCESSING_CHANNELS_FULL)
    user_bus_o[RR_CH_FIRST_BIT + ch*RR_CH_WIDTH + RR_CH_POS_RC_BITS +: RR_SPD_NUM_RECORDBITS] = data;
endtask

task insert_record_bits_a;
   input [RR_SPD_NUM_RECORDBITS-1:0] data;
                                user_bus_o[RR_CH_FIRST_BIT + CH_A*RR_CH_WIDTH + RR_CH_POS_RC_BITS +: RR_SPD_NUM_RECORDBITS] = data;
endtask
task insert_record_bits_b;
      input [RR_SPD_NUM_RECORDBITS-1:0] data;
   if (SPD_PROCESSING_CHANNELS_FULL > 1) user_bus_o[RR_CH_FIRST_BIT + CH_B*RR_CH_WIDTH + RR_CH_POS_RC_BITS +: RR_SPD_NUM_RECORDBITS] = data;
endtask
task insert_record_bits_c;
      input [RR_SPD_NUM_RECORDBITS-1:0] data;
   if (SPD_PROCESSING_CHANNELS_FULL > 2) user_bus_o[RR_CH_FIRST_BIT + CH_C*RR_CH_WIDTH + RR_CH_POS_RC_BITS +: RR_SPD_NUM_RECORDBITS] = data;
endtask
task insert_record_bits_d;
      input [RR_SPD_NUM_RECORDBITS-1:0] data;
   if (SPD_PROCESSING_CHANNELS_FULL > 3) user_bus_o[RR_CH_FIRST_BIT + CH_D*RR_CH_WIDTH + RR_CH_POS_RC_BITS +: RR_SPD_NUM_RECORDBITS] = data;
endtask

task insert_record_cnt;
  input [RR_SPD_NUM_RECORD_COUNTER_BITS-1:0] data;
  input integer ch;
  if(ch < SPD_PROCESSING_CHANNELS_FULL)
    user_bus_o[RR_CH_FIRST_BIT + ch*RR_CH_WIDTH + RR_CH_POS_RC_CNT +: RR_SPD_NUM_RECORD_COUNTER_BITS] = data;
endtask

task insert_record_cnt_a;
   input [RR_SPD_NUM_RECORD_COUNTER_BITS-1:0] data;
   begin
      insert_record_cnt(data, CH_A);
   end
endtask
task insert_record_cnt_b;
   input [RR_SPD_NUM_RECORD_COUNTER_BITS-1:0] data;
   begin
      insert_record_cnt(data, CH_B);
   end
endtask
task insert_record_cnt_c;
   input [RR_SPD_NUM_RECORD_COUNTER_BITS-1:0] data;
   begin
      insert_record_cnt(data, CH_C);
   end
endtask
task insert_record_cnt_d;
   input [RR_SPD_NUM_RECORD_COUNTER_BITS-1:0] data;
   begin
      insert_record_cnt(data, CH_D);
   end
endtask

task insert_user_id;
  input [RR_SPD_USER_ID_WIDTH_BITS-1:0] data;
  input integer ch;
  if(ch < SPD_PROCESSING_CHANNELS_FULL)
    user_bus_o[RR_CH_FIRST_BIT + ch * RR_CH_WIDTH + RR_CH_POS_USER_ID +: RR_SPD_USER_ID_WIDTH_BITS] = data;
endtask

task insert_user_id_a;
   input [RR_SPD_USER_ID_WIDTH_BITS-1:0] data;
   begin
      insert_user_id(data, CH_A);
   end
endtask
task insert_user_id_b;
   input [RR_SPD_USER_ID_WIDTH_BITS-1:0] data;
   begin
      insert_user_id(data, CH_B);
   end
endtask
task insert_user_id_c;
   input [RR_SPD_USER_ID_WIDTH_BITS-1:0] data;
   begin
      insert_user_id(data, CH_C);
   end
endtask
task insert_user_id_d;
   input [RR_SPD_USER_ID_WIDTH_BITS-1:0] data;
   begin
      insert_user_id(data, CH_D);
   end
endtask

task insert_general_purpose_vector;
  input [RR_SPD_GENERAL_PURPOSE_WIDTH-1:0] data;
  input integer ch;
  if(ch < SPD_PROCESSING_CHANNELS_FULL)
    user_bus_o[RR_CH_FIRST_BIT + ch * RR_CH_WIDTH + RR_CH_POS_GP_BITS +: RR_SPD_GENERAL_PURPOSE_WIDTH] = data;
endtask

task insert_general_purpose_vector_a;
   input [RR_SPD_GENERAL_PURPOSE_WIDTH-1:0] data;
   begin
      insert_general_purpose_vector(data, CH_A);
   end
endtask
task insert_general_purpose_vector_b;
   input [RR_SPD_GENERAL_PURPOSE_WIDTH-1:0] data;
   begin
      insert_general_purpose_vector(data, CH_B);
   end
endtask
task insert_general_purpose_vector_c;
   input [RR_SPD_GENERAL_PURPOSE_WIDTH-1:0] data;
   begin
      insert_general_purpose_vector(data, CH_C);
   end
endtask
task insert_general_purpose_vector_d;
   input [RR_SPD_GENERAL_PURPOSE_WIDTH-1:0] data;
   begin
      insert_general_purpose_vector(data, CH_D);
   end
endtask

task insert_timestamp_ch;
   input [RR_SPD_TIMESTAMP_WIDTH_BITS-1:0] data;
   input integer ch;
   if(ch < SPD_PROCESSING_CHANNELS_FULL)
     user_bus_o[RR_CH_FIRST_BIT + ch * RR_CH_WIDTH + RR_CH_POS_GP_BITS + RR_SPD_GENERAL_PURPOSE_WIDTH +: RR_SPD_TIMESTAMP_WIDTH_BITS] = data;
endtask

/* Backwards compability with single timestamp field */
task insert_timestamp;
   input [RR_SPD_TIMESTAMP_WIDTH_BITS-1:0] timestamp;
   begin
     insert_timestamp_ch(timestamp, CH_A);

     if (SPD_PROCESSING_CHANNELS_FULL > 1) insert_timestamp_ch(timestamp, CH_B);
     if (SPD_PROCESSING_CHANNELS_FULL > 2) insert_timestamp_ch(timestamp, CH_C);
     if (SPD_PROCESSING_CHANNELS_FULL > 3) insert_timestamp_ch(timestamp, CH_D);
     if (SPD_PROCESSING_CHANNELS_FULL > 4) insert_timestamp_ch(timestamp, 4);
     if (SPD_PROCESSING_CHANNELS_FULL > 5) insert_timestamp_ch(timestamp, 5);
     if (SPD_PROCESSING_CHANNELS_FULL > 6) insert_timestamp_ch(timestamp, 6);
     if (SPD_PROCESSING_CHANNELS_FULL > 7) insert_timestamp_ch(timestamp, 7);
   end
endtask

`endif

//Input
`ifndef  DISABLE_INPUT_RR

wire [RR_DATA_BUS_WIDTH:0] user_bus_i = {s_axis_tvalid, s_axis_tdata};

function [RR_SPD_TRIGGER_INHIBIT_BITS-1:0] extract_trig_inhibit;
   input dummy;
   extract_trig_inhibit =  user_bus_i[0 +: RR_SPD_TRIGGER_INHIBIT_BITS];
endfunction

function [RR_AUX_TRIG_VECTOR_WIDTH-1:0] extract_aux_trig;
   input integer        dummy;
   extract_aux_trig =   user_bus_i[RR_SPD_TRIGGER_INHIBIT_BITS +: RR_AUX_TRIG_VECTOR_WIDTH];
endfunction

function [RR_SPD_GATE_CNT_WIDTH-1:0] extract_gate_cnt;
   input dummy;
   extract_gate_cnt =  user_bus_i[RR_SPD_TRIGGER_INHIBIT_BITS + RR_AUX_TRIG_VECTOR_WIDTH +: RR_SPD_GATE_CNT_WIDTH];
endfunction

function [RR_CH_WIDTH-1:0] extract_ch;
   input integer ch;
   if(ch < SPD_PROCESSING_CHANNELS_FULL)
     extract_ch = user_bus_i[RR_CH_FIRST_BIT + ch * RR_CH_WIDTH +: RR_CH_WIDTH];
endfunction

// Samples
function [SPD_DATAWIDTH_BITS-1:0] extract_sample;
   input [RR_CH_WIDTH-1:0] data; //retruned by "extract_ch(ch)"
   input integer       idx;
   case (idx)
     0:                              extract_sample = data[0*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS];
     1:if (SPD_PARALLEL_SAMPLES > 1) extract_sample = data[1*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS];
     2:if (SPD_PARALLEL_SAMPLES > 2) extract_sample = data[2*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS];
     3:if (SPD_PARALLEL_SAMPLES > 3) extract_sample = data[3*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS];
     4:if (SPD_PARALLEL_SAMPLES > 4) extract_sample = data[4*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS];
     5:if (SPD_PARALLEL_SAMPLES > 5) extract_sample = data[5*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS];
     6:if (SPD_PARALLEL_SAMPLES > 6) extract_sample = data[6*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS];
     7:if (SPD_PARALLEL_SAMPLES > 7) extract_sample = data[7*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS];

   endcase
endfunction

function [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] extract_ch_all_sample;
   input [RR_CH_WIDTH-1:0] data; //retruned by "extract_ch(ch)"
   extract_ch_all_sample = data[0 +: SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS];
endfunction

function [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] extract_ch_all;
   input integer       ch;
   extract_ch_all = extract_ch_all_sample(extract_ch(ch));
endfunction

function [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] extract_ch_a_all;
   input integer       dummy;
   extract_ch_a_all = extract_ch_all_sample(extract_ch(CH_A));
endfunction
function [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] extract_ch_b_all;
   input integer       dummy;
   extract_ch_b_all = extract_ch_all_sample(extract_ch(CH_B));
endfunction
function [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] extract_ch_c_all;
   input integer       dummy;
   extract_ch_c_all = extract_ch_all_sample(extract_ch(CH_C));
endfunction
function [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] extract_ch_d_all;
   input integer       dummy;
   extract_ch_d_all = extract_ch_all_sample(extract_ch(CH_D));
endfunction

function [SPD_DATAWIDTH_BITS-1:0] extract_ch_a;
  input integer idx;
   case (idx)
     0:                              extract_ch_a = extract_sample(extract_ch(CH_A), 0);
     1:if (SPD_PARALLEL_SAMPLES > 1) extract_ch_a = extract_sample(extract_ch(CH_A), 1);
     2:if (SPD_PARALLEL_SAMPLES > 2) extract_ch_a = extract_sample(extract_ch(CH_A), 2);
     3:if (SPD_PARALLEL_SAMPLES > 3) extract_ch_a = extract_sample(extract_ch(CH_A), 3);
     4:if (SPD_PARALLEL_SAMPLES > 4) extract_ch_a = extract_sample(extract_ch(CH_A), 4);
     5:if (SPD_PARALLEL_SAMPLES > 5) extract_ch_a = extract_sample(extract_ch(CH_A), 5);
     6:if (SPD_PARALLEL_SAMPLES > 6) extract_ch_a = extract_sample(extract_ch(CH_A), 6);
     7:if (SPD_PARALLEL_SAMPLES > 7) extract_ch_a = extract_sample(extract_ch(CH_A), 7);

   endcase
endfunction

function [SPD_DATAWIDTH_BITS-1:0] extract_ch_b;
  input integer       idx;
   case (idx)
     0:                              extract_ch_b = extract_sample(extract_ch(CH_B), 0);
     1:if (SPD_PARALLEL_SAMPLES > 1) extract_ch_b = extract_sample(extract_ch(CH_B), 1);
     2:if (SPD_PARALLEL_SAMPLES > 2) extract_ch_b = extract_sample(extract_ch(CH_B), 2);
     3:if (SPD_PARALLEL_SAMPLES > 3) extract_ch_b = extract_sample(extract_ch(CH_B), 3);
     4:if (SPD_PARALLEL_SAMPLES > 4) extract_ch_b = extract_sample(extract_ch(CH_B), 4);
     5:if (SPD_PARALLEL_SAMPLES > 5) extract_ch_b = extract_sample(extract_ch(CH_B), 5);
     6:if (SPD_PARALLEL_SAMPLES > 6) extract_ch_b = extract_sample(extract_ch(CH_B), 6);
     7:if (SPD_PARALLEL_SAMPLES > 7) extract_ch_b = extract_sample(extract_ch(CH_B), 7);

   endcase
endfunction

function [SPD_DATAWIDTH_BITS-1:0] extract_ch_c;
  input integer       idx;
   case (idx)
     0:                              extract_ch_c = extract_sample(extract_ch(CH_C), 0);
     1:if (SPD_PARALLEL_SAMPLES > 1) extract_ch_c = extract_sample(extract_ch(CH_C), 1);
     2:if (SPD_PARALLEL_SAMPLES > 2) extract_ch_c = extract_sample(extract_ch(CH_C), 2);
     3:if (SPD_PARALLEL_SAMPLES > 3) extract_ch_c = extract_sample(extract_ch(CH_C), 3);
     4:if (SPD_PARALLEL_SAMPLES > 4) extract_ch_c = extract_sample(extract_ch(CH_C), 4);
     5:if (SPD_PARALLEL_SAMPLES > 5) extract_ch_c = extract_sample(extract_ch(CH_C), 5);
     6:if (SPD_PARALLEL_SAMPLES > 6) extract_ch_c = extract_sample(extract_ch(CH_C), 6);
     7:if (SPD_PARALLEL_SAMPLES > 7) extract_ch_c = extract_sample(extract_ch(CH_C), 7);

   endcase
endfunction

function [SPD_DATAWIDTH_BITS-1:0] extract_ch_d;
  input integer       idx;
   case (idx)
     0:                              extract_ch_d = extract_sample(extract_ch(CH_D), 0);
     1:if (SPD_PARALLEL_SAMPLES > 1) extract_ch_d = extract_sample(extract_ch(CH_D), 1);
     2:if (SPD_PARALLEL_SAMPLES > 2) extract_ch_d = extract_sample(extract_ch(CH_D), 2);
     3:if (SPD_PARALLEL_SAMPLES > 3) extract_ch_d = extract_sample(extract_ch(CH_D), 3);
     4:if (SPD_PARALLEL_SAMPLES > 4) extract_ch_d = extract_sample(extract_ch(CH_D), 4);
     5:if (SPD_PARALLEL_SAMPLES > 5) extract_ch_d = extract_sample(extract_ch(CH_D), 5);
     6:if (SPD_PARALLEL_SAMPLES > 6) extract_ch_d = extract_sample(extract_ch(CH_D), 6);
     7:if (SPD_PARALLEL_SAMPLES > 7) extract_ch_d = extract_sample(extract_ch(CH_D), 7);

   endcase
endfunction

function [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] extract_all_ch_samples;
   input [RR_CH_WIDTH-1:0] data;
   if (SPD_PARALLEL_SAMPLES == 8)
     extract_all_ch_samples = { data[7*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS],
                                data[6*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS],
                                data[5*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS],
                                data[4*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS],
                                data[3*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS],
                                data[2*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS],
                                data[1*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS],
                                data[0*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS]};
   else if (SPD_PARALLEL_SAMPLES == 4)
     extract_all_ch_samples = { data[3*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS],
                                data[2*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS],
                                data[1*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS],
                                data[0*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS]};
   else if (SPD_PARALLEL_SAMPLES == 2)
     extract_all_ch_samples = { data[1*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS],
                                data[0*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS]};

endfunction

function [SPD_PROCESSING_CHANNELS_FULL*SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] extract_all_sample;
   input integer        dummy;
   case (SPD_PROCESSING_CHANNELS_FULL)
     4:	extract_all_sample  = { extract_all_ch_samples(extract_ch(CH_D)),
						                    extract_all_ch_samples(extract_ch(CH_C)),
                                extract_all_ch_samples(extract_ch(CH_B)),
                                extract_all_ch_samples(extract_ch(CH_A))};
     3:	extract_all_sample  = { extract_all_ch_samples(extract_ch(CH_C)),
                                extract_all_ch_samples(extract_ch(CH_B)),
                                extract_all_ch_samples(extract_ch(CH_A))};
     2:	extract_all_sample  = { extract_all_ch_samples(extract_ch(CH_B)),
                                extract_all_ch_samples(extract_ch(CH_A))};
     1:	extract_all_sample  = { extract_all_ch_samples(extract_ch(CH_A))};
	   default: extract_all_sample = 0;
	 endcase
endfunction



// Data valid
function extract_data_valid_from_ch_data;
   input [RR_CH_WIDTH-1:0] data;
   extract_data_valid_from_ch_data = data[RR_CH_WIDTH-1];
endfunction

function extract_data_valid;
   input integer        ch;
   extract_data_valid = extract_data_valid_from_ch_data(extract_ch(ch));
endfunction

function extract_data_valid_a;
   input integer        dummy;
   extract_data_valid_a = extract_data_valid_from_ch_data(extract_ch(CH_A));
endfunction
function extract_data_valid_b;
   input integer        dummy;
   extract_data_valid_b = extract_data_valid_from_ch_data(extract_ch(CH_B));
endfunction
function extract_data_valid_c;
   input integer        dummy;
   extract_data_valid_c = extract_data_valid_from_ch_data(extract_ch(CH_C));
endfunction
function extract_data_valid_d;
   input integer        dummy;
   extract_data_valid_d = extract_data_valid_from_ch_data(extract_ch(CH_D));
endfunction

//CH trig
function [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] extract_ch_trig_from_ch_data;
   input [RR_CH_WIDTH-1:0] data;
   extract_ch_trig_from_ch_data = data[SPD_PARALLEL_SAMPLES * SPD_DATAWIDTH_BITS +: RR_CH_TRIG_VECTOR_1_WIDTH];
endfunction
function [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] extract_ch_trig;
   input integer        ch;
   extract_ch_trig = extract_ch_trig_from_ch_data(extract_ch(ch));
endfunction
function [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] extract_ch_trig_a;
   input integer        dummy;
   extract_ch_trig_a = extract_ch_trig_from_ch_data(extract_ch(CH_A));
endfunction
function [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] extract_ch_trig_b;
   input integer        dummy;
   extract_ch_trig_b = extract_ch_trig_from_ch_data(extract_ch(CH_B));
endfunction
function [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] extract_ch_trig_c;
   input integer        dummy;
   extract_ch_trig_c = extract_ch_trig_from_ch_data(extract_ch(CH_C));
endfunction
function [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] extract_ch_trig_d;
   input integer        dummy;
   extract_ch_trig_d = extract_ch_trig_from_ch_data(extract_ch(CH_D));
endfunction

function  extract_ch_over_range_from_ch_data;
   input [RR_CH_WIDTH-1:0] data;
   extract_ch_over_range_from_ch_data = data[RR_CH_POS_OVER_RANGE +: 1];
endfunction

function extract_over_range;
   input integer        ch;
   extract_over_range = extract_ch_over_range_from_ch_data(extract_ch(ch));
endfunction
function extract_over_range_a;
   input integer        dummy;
   extract_over_range_a = extract_ch_over_range_from_ch_data(extract_ch(CH_A));
endfunction
function extract_over_range_b;
   input integer        dummy;
   extract_over_range_b = extract_ch_over_range_from_ch_data(extract_ch(CH_B));
endfunction
function extract_over_range_c;
   input integer        dummy;
   extract_over_range_c = extract_ch_over_range_from_ch_data(extract_ch(CH_C));
endfunction
function extract_over_range_d;
   input integer        dummy;
   extract_over_range_d = extract_ch_over_range_from_ch_data(extract_ch(CH_D));
endfunction

function [RR_SPD_NUM_RECORDBITS-1:0] extract_ch_record_bits_from_ch_data;
   input [RR_CH_WIDTH-1:0] data;
   extract_ch_record_bits_from_ch_data = data[RR_CH_POS_RC_BITS +: RR_SPD_NUM_RECORDBITS];
endfunction

function [RR_SPD_NUM_RECORDBITS-1:0] extract_record_bits;
   input integer        ch;
   extract_record_bits = extract_ch_record_bits_from_ch_data(extract_ch(ch));
endfunction
function [RR_SPD_NUM_RECORDBITS-1:0] extract_record_bits_a;
   input integer        dummy;
   extract_record_bits_a = extract_ch_record_bits_from_ch_data(extract_ch(CH_A));
endfunction
function [RR_SPD_NUM_RECORDBITS-1:0] extract_record_bits_b;
   input integer        dummy;
   extract_record_bits_b = extract_ch_record_bits_from_ch_data(extract_ch(CH_B));
endfunction
function [RR_SPD_NUM_RECORDBITS-1:0] extract_record_bits_c;
   input integer        dummy;
   extract_record_bits_c = extract_ch_record_bits_from_ch_data(extract_ch(CH_C));
endfunction
function [RR_SPD_NUM_RECORDBITS-1:0] extract_record_bits_d;
   input integer        dummy;
   extract_record_bits_d = extract_ch_record_bits_from_ch_data(extract_ch(CH_D));
endfunction


function [RR_SPD_NUM_RECORD_COUNTER_BITS-1:0] extract_ch_record_cnt_from_ch_data;
   input [RR_CH_WIDTH-1:0] data;
   extract_ch_record_cnt_from_ch_data = data[RR_CH_POS_RC_CNT +: RR_SPD_NUM_RECORD_COUNTER_BITS];
endfunction

function [RR_SPD_NUM_RECORD_COUNTER_BITS-1:0] extract_record_cnt;
   input integer        ch;
   extract_record_cnt = extract_ch_record_cnt_from_ch_data(extract_ch(ch));
endfunction
function [RR_SPD_NUM_RECORD_COUNTER_BITS-1:0] extract_record_cnt_a;
   input integer        dummy;
   extract_record_cnt_a = extract_ch_record_cnt_from_ch_data(extract_ch(CH_A));
endfunction
function [RR_SPD_NUM_RECORD_COUNTER_BITS-1:0] extract_record_cnt_b;
   input integer        dummy;
   extract_record_cnt_b = extract_ch_record_cnt_from_ch_data(extract_ch(CH_B));
endfunction
function [RR_SPD_NUM_RECORD_COUNTER_BITS-1:0] extract_record_cnt_c;
   input integer        dummy;
   extract_record_cnt_c = extract_ch_record_cnt_from_ch_data(extract_ch(CH_C));
endfunction
function [RR_SPD_NUM_RECORD_COUNTER_BITS-1:0] extract_record_cnt_d;
   input integer        dummy;
   extract_record_cnt_d = extract_ch_record_cnt_from_ch_data(extract_ch(CH_D));
endfunction

function  [RR_SPD_USER_ID_WIDTH_BITS-1:0] extract_ch_user_id_from_ch_data;
   input [RR_CH_WIDTH-1:0] data;
   extract_ch_user_id_from_ch_data = data[RR_CH_POS_USER_ID +: RR_SPD_USER_ID_WIDTH_BITS];
endfunction

function [RR_SPD_USER_ID_WIDTH_BITS-1:0] extract_user_id;
   input integer        ch;
   extract_user_id = extract_ch_user_id_from_ch_data(extract_ch(ch));
endfunction
function [RR_SPD_USER_ID_WIDTH_BITS-1:0] extract_user_id_a;
   input integer        dummy;
   extract_user_id_a = extract_ch_user_id_from_ch_data(extract_ch(CH_A));
endfunction
function [RR_SPD_USER_ID_WIDTH_BITS-1:0] extract_user_id_b;
   input integer        dummy;
   extract_user_id_b = extract_ch_user_id_from_ch_data(extract_ch(CH_B));
endfunction
function [RR_SPD_USER_ID_WIDTH_BITS-1:0] extract_user_id_c;
   input integer        dummy;
   extract_user_id_c = extract_ch_user_id_from_ch_data(extract_ch(CH_C));
endfunction
function [RR_SPD_USER_ID_WIDTH_BITS-1:0] extract_user_id_d;
   input integer        dummy;
   extract_user_id_d = extract_ch_user_id_from_ch_data(extract_ch(CH_D));
endfunction

function  [RR_SPD_GENERAL_PURPOSE_WIDTH-1:0] extract_ch_general_purpose_vector_from_ch_data;
   input [RR_CH_WIDTH-1:0] data;
   extract_ch_general_purpose_vector_from_ch_data = data[RR_CH_POS_GP_BITS +: RR_SPD_GENERAL_PURPOSE_WIDTH];
endfunction

function [RR_SPD_GENERAL_PURPOSE_WIDTH-1:0] extract_ch_general_purpose_vector;
   input integer        ch;
   extract_ch_general_purpose_vector = extract_ch_general_purpose_vector_from_ch_data(extract_ch(ch));
endfunction
function [RR_SPD_GENERAL_PURPOSE_WIDTH-1:0] extract_ch_general_purpose_vector_a;
   input integer        dummy;
   extract_ch_general_purpose_vector_a = extract_ch_general_purpose_vector_from_ch_data(extract_ch(CH_A));
endfunction
function [RR_SPD_GENERAL_PURPOSE_WIDTH-1:0] extract_ch_general_purpose_vector_b;
   input integer        dummy;
   extract_ch_general_purpose_vector_b = extract_ch_general_purpose_vector_from_ch_data(extract_ch(CH_B));
endfunction
function [RR_SPD_GENERAL_PURPOSE_WIDTH-1:0] extract_ch_general_purpose_vector_c;
   input integer        dummy;
   extract_ch_general_purpose_vector_c = extract_ch_general_purpose_vector_from_ch_data(extract_ch(CH_C));
endfunction
function [RR_SPD_GENERAL_PURPOSE_WIDTH-1:0] extract_ch_general_purpose_vector_d;
   input integer        dummy;
   extract_ch_general_purpose_vector_d = extract_ch_general_purpose_vector_from_ch_data(extract_ch(CH_D));
endfunction

function  [RR_SPD_TIMESTAMP_WIDTH_BITS-1:0] extract_ch_timestamp;
   input [RR_CH_WIDTH-1:0] data;
   extract_ch_timestamp = data[RR_CH_POS_GP_BITS + RR_SPD_GENERAL_PURPOSE_WIDTH +: RR_SPD_TIMESTAMP_WIDTH_BITS];
endfunction

function [RR_SPD_TIMESTAMP_WIDTH_BITS-1:0] extract_timestamp;
   input dummy;
   extract_timestamp =  extract_ch_timestamp(extract_ch(CH_A));
endfunction


`endif
