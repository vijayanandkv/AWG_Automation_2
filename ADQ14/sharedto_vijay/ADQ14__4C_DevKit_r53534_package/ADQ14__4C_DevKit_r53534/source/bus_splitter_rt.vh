/* -*- coding: us-ascii-dos -*-
 *
 * Copyright Signal Processing Devices Sweden AB. All rights reserved.
 * See document "08-0175 EULA" for specific license terms regarding this file.
 *
 * Description   : Bus extraction macros, real time
 * Documentation :
 *
 */

/* Must be defined by user before including this file
localparam           BUS_PIPELINE = 1;
localparam           RT_DATA_BUS_WIDTH = 199;

wire                      s_axis_aclk;
wire [RT_DATA_BUS_WIDTH-1:0] s_axis_tdata
wire                      s_axis_tvalid;
reg [RT_DATA_BUS_WIDTH-1:0]  m_axis_tdata
reg                       m_axis_tvalid
*/

// RT Bus format:
// DATA = $SPD_PARALLEL_SAMPLES * $SPD_DATAWIDTH_BITS
// CHT  = RT_CH_TRIG_VECTOR_1_WIDTH = $RT_SPD_NUM_CH_TRIG_BITS  + $RT_SPD_NUM_TRIG_ADDBITS
// AUX  = $RT_SPD_NUM_AUX_TRIG_BITS + $RT_SPD_NUM_TRIG_ADDBITS
// TS   = $RT_SPD_TIMESTAMP_WIDTH_BITS
// OR   = OVER RANGE bit
// BUS =  $SPD_ANALOG_CHANNELS * {$OR, $CHT, $DATA}, AUX, TS

`include "bus_splitter_rt_param.vh"

// Only check for illegal task/function usage during synthesis
`ifdef XILINX_SIMULATOR 
  `define ERROR__Illegal_usage begin end
`elsif MODEL_TECH
   `define ERROR__Illegal_usage begin end
`else
  `define ERROR__Illegal_usage ERROR__Illegal_usage();
`endif

// Output
`ifndef DISABLE_OUTPUT_RT
wire [RT_DATA_BUS_WIDTH:0] user_bus_o_default;
reg  [RT_DATA_BUS_WIDTH:0] user_bus_o;

generate
   reg [RT_DATA_BUS_WIDTH:0] bus_pipeline[BUS_PIPELINE-1:0];

   if (BUS_PIPELINE > 0)
     begin
        always@(posedge s_axis_aclk)
          begin : bus_pipeline_inst
             integer i;
             bus_pipeline[0][RT_DATA_BUS_WIDTH]      <= s_axis_tvalid;
             bus_pipeline[0][RT_DATA_BUS_WIDTH-1:0]  <= s_axis_tdata;
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
      m_axis_tdata  = user_bus_o[RT_DATA_BUS_WIDTH-1:0];
      m_axis_tvalid = user_bus_o[RT_DATA_BUS_WIDTH];
   end
endtask

task insert_timestamp;
   input [RT_SPD_TIMESTAMP_WIDTH_BITS-1:0] timestamp;
   user_bus_o[0 +: RT_SPD_TIMESTAMP_WIDTH_BITS] = timestamp;
endtask

task insert_trig_inhibit;
   input [RT_SPD_TRIGGER_INHIBIT_BITS-1:0] trig_inhibit;
   user_bus_o[RT_SPD_TIMESTAMP_WIDTH_BITS +: RT_SPD_TRIGGER_INHIBIT_BITS] = trig_inhibit;
endtask

task insert_aux_trig;
   input [RT_AUX_TRIG_VECTOR_WIDTH-1:0] vector;
   user_bus_o[RT_SPD_TIMESTAMP_WIDTH_BITS + RT_SPD_TRIGGER_INHIBIT_BITS +: RT_AUX_TRIG_VECTOR_WIDTH] = vector;
endtask

task insert_gate_cnt;
   input [RT_SPD_GATE_CNT_WIDTH-1:0] vector;
   user_bus_o[RT_SPD_TIMESTAMP_WIDTH_BITS + RT_SPD_TRIGGER_INHIBIT_BITS + RT_AUX_TRIG_VECTOR_WIDTH +: RT_SPD_GATE_CNT_WIDTH] = vector;
endtask

task insert_ch_a_all;
   input [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data;
   user_bus_o[RT_CH_FIRST_BIT + CH_A * RT_CH_WIDTH +: SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS] = data;
endtask
task insert_ch_b_all;
   input [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data;
   user_bus_o[RT_CH_FIRST_BIT + CH_B * RT_CH_WIDTH +: SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS] = data;
endtask
task insert_ch_c_all;
   input [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data;
   user_bus_o[RT_CH_FIRST_BIT + CH_C * RT_CH_WIDTH +: SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS] = data;
endtask
task insert_ch_d_all;
   input [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data;
   user_bus_o[RT_CH_FIRST_BIT + CH_D * RT_CH_WIDTH +: SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS] = data;
endtask


task insert_ch_a;
   input [SPD_DATAWIDTH_BITS-1:0] data;
   input integer idx;
   begin
      case (idx)
        0:                              user_bus_o[RT_CH_FIRST_BIT + CH_A * RT_CH_WIDTH + 0*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
        1:if (SPD_PARALLEL_SAMPLES > 1) user_bus_o[RT_CH_FIRST_BIT + CH_A * RT_CH_WIDTH + 1*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
        2:if (SPD_PARALLEL_SAMPLES > 2) user_bus_o[RT_CH_FIRST_BIT + CH_A * RT_CH_WIDTH + 2*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
        3:if (SPD_PARALLEL_SAMPLES > 3) user_bus_o[RT_CH_FIRST_BIT + CH_A * RT_CH_WIDTH + 3*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
        4:if (SPD_PARALLEL_SAMPLES > 4) user_bus_o[RT_CH_FIRST_BIT + CH_A * RT_CH_WIDTH + 4*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
        5:if (SPD_PARALLEL_SAMPLES > 5) user_bus_o[RT_CH_FIRST_BIT + CH_A * RT_CH_WIDTH + 5*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
        6:if (SPD_PARALLEL_SAMPLES > 6) user_bus_o[RT_CH_FIRST_BIT + CH_A * RT_CH_WIDTH + 6*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
        7:if (SPD_PARALLEL_SAMPLES > 7) user_bus_o[RT_CH_FIRST_BIT + CH_A * RT_CH_WIDTH + 7*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
        default: `ERROR__Illegal_usage
      endcase
   end
endtask

task insert_ch_b;
   input [SPD_DATAWIDTH_BITS-1:0] data;
   input integer idx;
   if (SPD_ANALOG_CHANNELS > 1)
     begin
        case (idx)
          0:                              user_bus_o[RT_CH_FIRST_BIT + CH_B * RT_CH_WIDTH + 0*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          1:if (SPD_PARALLEL_SAMPLES > 1) user_bus_o[RT_CH_FIRST_BIT + CH_B * RT_CH_WIDTH + 1*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          2:if (SPD_PARALLEL_SAMPLES > 2) user_bus_o[RT_CH_FIRST_BIT + CH_B * RT_CH_WIDTH + 2*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          3:if (SPD_PARALLEL_SAMPLES > 3) user_bus_o[RT_CH_FIRST_BIT + CH_B * RT_CH_WIDTH + 3*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          4:if (SPD_PARALLEL_SAMPLES > 4) user_bus_o[RT_CH_FIRST_BIT + CH_B * RT_CH_WIDTH + 4*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          5:if (SPD_PARALLEL_SAMPLES > 5) user_bus_o[RT_CH_FIRST_BIT + CH_B * RT_CH_WIDTH + 5*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          6:if (SPD_PARALLEL_SAMPLES > 6) user_bus_o[RT_CH_FIRST_BIT + CH_B * RT_CH_WIDTH + 6*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          7:if (SPD_PARALLEL_SAMPLES > 7) user_bus_o[RT_CH_FIRST_BIT + CH_B * RT_CH_WIDTH + 7*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          default: `ERROR__Illegal_usage
        endcase
     end
endtask

task insert_ch_c;
   input [SPD_DATAWIDTH_BITS-1:0] data;
   input integer idx;
   if (SPD_ANALOG_CHANNELS > 2)
     begin
        case (idx)
          0:                              user_bus_o[RT_CH_FIRST_BIT + CH_C * RT_CH_WIDTH + 0*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          1:if (SPD_PARALLEL_SAMPLES > 1) user_bus_o[RT_CH_FIRST_BIT + CH_C * RT_CH_WIDTH + 1*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          2:if (SPD_PARALLEL_SAMPLES > 2) user_bus_o[RT_CH_FIRST_BIT + CH_C * RT_CH_WIDTH + 2*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          3:if (SPD_PARALLEL_SAMPLES > 3) user_bus_o[RT_CH_FIRST_BIT + CH_C * RT_CH_WIDTH + 3*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          4:if (SPD_PARALLEL_SAMPLES > 4) user_bus_o[RT_CH_FIRST_BIT + CH_C * RT_CH_WIDTH + 4*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          5:if (SPD_PARALLEL_SAMPLES > 5) user_bus_o[RT_CH_FIRST_BIT + CH_C * RT_CH_WIDTH + 5*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          6:if (SPD_PARALLEL_SAMPLES > 6) user_bus_o[RT_CH_FIRST_BIT + CH_C * RT_CH_WIDTH + 6*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          7:if (SPD_PARALLEL_SAMPLES > 7) user_bus_o[RT_CH_FIRST_BIT + CH_C * RT_CH_WIDTH + 7*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          default: `ERROR__Illegal_usage
        endcase
   end
endtask

task insert_ch_d;
   input [SPD_DATAWIDTH_BITS-1:0] data;
   input integer                  idx;
   if (SPD_ANALOG_CHANNELS > 3)
     begin
        case (idx)
          0:                              user_bus_o[RT_CH_FIRST_BIT + CH_D * RT_CH_WIDTH + 0*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data;
          1:if (SPD_PARALLEL_SAMPLES > 1) user_bus_o[RT_CH_FIRST_BIT + CH_D * RT_CH_WIDTH + 1*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          2:if (SPD_PARALLEL_SAMPLES > 2) user_bus_o[RT_CH_FIRST_BIT + CH_D * RT_CH_WIDTH + 2*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          3:if (SPD_PARALLEL_SAMPLES > 3) user_bus_o[RT_CH_FIRST_BIT + CH_D * RT_CH_WIDTH + 3*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
	        4:if (SPD_PARALLEL_SAMPLES > 4) user_bus_o[RT_CH_FIRST_BIT + CH_D * RT_CH_WIDTH + 4*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          5:if (SPD_PARALLEL_SAMPLES > 5) user_bus_o[RT_CH_FIRST_BIT + CH_D * RT_CH_WIDTH + 5*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          6:if (SPD_PARALLEL_SAMPLES > 6) user_bus_o[RT_CH_FIRST_BIT + CH_D * RT_CH_WIDTH + 6*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          7:if (SPD_PARALLEL_SAMPLES > 7) user_bus_o[RT_CH_FIRST_BIT + CH_D * RT_CH_WIDTH + 7*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS] = data; else `ERROR__Illegal_usage
          default: `ERROR__Illegal_usage
        endcase
     end
endtask

task insert_ch_trig_vector;
   input [RT_CH_TRIG_VECTOR_1_WIDTH-1:0] data;
   input integer ch;
   begin
      case (ch)
        0:                             user_bus_o[RT_CH_FIRST_BIT + CH_A * RT_CH_WIDTH + SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS +: RT_CH_TRIG_VECTOR_1_WIDTH] = data;
        1:if (SPD_ANALOG_CHANNELS > 1) user_bus_o[RT_CH_FIRST_BIT + CH_B * RT_CH_WIDTH + SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS +: RT_CH_TRIG_VECTOR_1_WIDTH] = data; else `ERROR__Illegal_usage
        2:if (SPD_ANALOG_CHANNELS > 2) user_bus_o[RT_CH_FIRST_BIT + CH_C * RT_CH_WIDTH + SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS +: RT_CH_TRIG_VECTOR_1_WIDTH] = data; else `ERROR__Illegal_usage
        3:if (SPD_ANALOG_CHANNELS > 3) user_bus_o[RT_CH_FIRST_BIT + CH_D * RT_CH_WIDTH + SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS +: RT_CH_TRIG_VECTOR_1_WIDTH] = data; else `ERROR__Illegal_usage
        default: `ERROR__Illegal_usage
      endcase
   end
endtask

task insert_ch_trig_vector_a;
   input [RT_CH_TRIG_VECTOR_1_WIDTH-1:0] data;
   begin
      insert_ch_trig_vector(data, CH_A);
   end
endtask
task insert_ch_trig_vector_b;
   input [RT_CH_TRIG_VECTOR_1_WIDTH-1:0] data;
   begin
      insert_ch_trig_vector(data, CH_B);
   end
endtask
task insert_ch_trig_vector_c;
   input [RT_CH_TRIG_VECTOR_1_WIDTH-1:0] data;
   begin
      insert_ch_trig_vector(data, CH_C);
   end
endtask
task insert_ch_trig_vector_d;
   input [RT_CH_TRIG_VECTOR_1_WIDTH-1:0] data;
   begin
      insert_ch_trig_vector(data, CH_D);
   end
endtask


task insert_ch_over_range;
   input  data;
   input integer ch;
   begin
      case (ch)
        0:                             user_bus_o[RT_CH_FIRST_BIT + CH_A * RT_CH_WIDTH + SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS + RT_CH_TRIG_VECTOR_1_WIDTH +: RT_SPD_OVER_RANGE_1_WIDTH] = data;
        1:if (SPD_ANALOG_CHANNELS > 1) user_bus_o[RT_CH_FIRST_BIT + CH_B * RT_CH_WIDTH + SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS + RT_CH_TRIG_VECTOR_1_WIDTH +: RT_SPD_OVER_RANGE_1_WIDTH] = data; else `ERROR__Illegal_usage
        2:if (SPD_ANALOG_CHANNELS > 2) user_bus_o[RT_CH_FIRST_BIT + CH_C * RT_CH_WIDTH + SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS + RT_CH_TRIG_VECTOR_1_WIDTH +: RT_SPD_OVER_RANGE_1_WIDTH] = data; else `ERROR__Illegal_usage
        3:if (SPD_ANALOG_CHANNELS > 3) user_bus_o[RT_CH_FIRST_BIT + CH_D * RT_CH_WIDTH + SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS + RT_CH_TRIG_VECTOR_1_WIDTH +: RT_SPD_OVER_RANGE_1_WIDTH] = data; else `ERROR__Illegal_usage
        default: `ERROR__Illegal_usage
      endcase
   end
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

task insert_general_purpose_vector;
   input [RT_SPD_GENERAL_PURPOSE_WIDTH-1:0] data;
   input integer ch;
   begin
      case (ch)
        0:                             user_bus_o[RT_CH_FIRST_BIT + CH_A * RT_CH_WIDTH + RT_CH_WIDTH - RT_SPD_GENERAL_PURPOSE_WIDTH +: RT_SPD_GENERAL_PURPOSE_WIDTH] = data;
        1:if (SPD_ANALOG_CHANNELS > 1) user_bus_o[RT_CH_FIRST_BIT + CH_B * RT_CH_WIDTH + RT_CH_WIDTH - RT_SPD_GENERAL_PURPOSE_WIDTH +: RT_SPD_GENERAL_PURPOSE_WIDTH] = data; else `ERROR__Illegal_usage
        2:if (SPD_ANALOG_CHANNELS > 2) user_bus_o[RT_CH_FIRST_BIT + CH_C * RT_CH_WIDTH + RT_CH_WIDTH - RT_SPD_GENERAL_PURPOSE_WIDTH +: RT_SPD_GENERAL_PURPOSE_WIDTH] = data; else `ERROR__Illegal_usage
        3:if (SPD_ANALOG_CHANNELS > 3) user_bus_o[RT_CH_FIRST_BIT + CH_D * RT_CH_WIDTH + RT_CH_WIDTH - RT_SPD_GENERAL_PURPOSE_WIDTH +: RT_SPD_GENERAL_PURPOSE_WIDTH] = data; else `ERROR__Illegal_usage
        default: `ERROR__Illegal_usage
      endcase
   end
endtask

task insert_general_purpose_vector_a;
   input [RT_SPD_GENERAL_PURPOSE_WIDTH-1:0] data;
   begin
      insert_general_purpose_vector(data, CH_A);
   end
endtask
task insert_general_purpose_vector_b;
   input [RT_SPD_GENERAL_PURPOSE_WIDTH-1:0] data;
   begin
      insert_general_purpose_vector(data, CH_B);
   end
endtask
task insert_general_purpose_vector_c;
   input [RT_SPD_GENERAL_PURPOSE_WIDTH-1:0] data;
   begin
      insert_general_purpose_vector(data, CH_C);
   end
endtask
task insert_general_purpose_vector_d;
   input [RT_SPD_GENERAL_PURPOSE_WIDTH-1:0] data;
   begin
      insert_general_purpose_vector(data, CH_D);
   end
endtask

`endif

//Input
`ifndef DISABLE_INPUT_RT

wire [RT_DATA_BUS_WIDTH:0] user_bus_i = {s_axis_tvalid, s_axis_tdata};

function [RT_SPD_TIMESTAMP_WIDTH_BITS-1:0] extract_timestamp;
   input dummy;
   extract_timestamp =  user_bus_i[0 +: RT_SPD_TIMESTAMP_WIDTH_BITS];
endfunction

function [RT_SPD_TRIGGER_INHIBIT_BITS-1:0] extract_trig_inhibit;
   input dummy;
   extract_trig_inhibit =  user_bus_i[RT_SPD_TIMESTAMP_WIDTH_BITS +: RT_SPD_TRIGGER_INHIBIT_BITS];
endfunction

function [RT_AUX_TRIG_VECTOR_WIDTH-1:0] extract_aux_trig;
   input integer        dummy;
   extract_aux_trig =   user_bus_i[RT_SPD_TIMESTAMP_WIDTH_BITS + RT_SPD_TRIGGER_INHIBIT_BITS +: RT_AUX_TRIG_VECTOR_WIDTH];
endfunction

function [RT_SPD_GATE_CNT_WIDTH-1:0] extract_gate_cnt;
   input dummy;
   extract_gate_cnt =  user_bus_i[RT_SPD_TIMESTAMP_WIDTH_BITS + RT_SPD_TRIGGER_INHIBIT_BITS + RT_AUX_TRIG_VECTOR_WIDTH +: RT_SPD_GATE_CNT_WIDTH];
endfunction

function [RT_CH_WIDTH-1:0] extract_ch;
   input integer ch;
   case (ch)
     0:                             extract_ch = user_bus_i[RT_CH_FIRST_BIT + CH_A * RT_CH_WIDTH +: RT_CH_WIDTH];
     1:if (SPD_ANALOG_CHANNELS > 1) extract_ch = user_bus_i[RT_CH_FIRST_BIT + CH_B * RT_CH_WIDTH +: RT_CH_WIDTH]; else `ERROR__Illegal_usage
     2:if (SPD_ANALOG_CHANNELS > 2) extract_ch = user_bus_i[RT_CH_FIRST_BIT + CH_C * RT_CH_WIDTH +: RT_CH_WIDTH]; else `ERROR__Illegal_usage
     3:if (SPD_ANALOG_CHANNELS > 3) extract_ch = user_bus_i[RT_CH_FIRST_BIT + CH_D * RT_CH_WIDTH +: RT_CH_WIDTH]; else `ERROR__Illegal_usage
     default: `ERROR__Illegal_usage
   endcase
endfunction

// Samples
function [SPD_DATAWIDTH_BITS-1:0] extract_sample;
   input [RT_CH_WIDTH-1:0] data; //retruned by "extract_ch(ch)"
   input integer       idx;
   case (idx)
     0:                              extract_sample = data[0*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS];
     1:if (SPD_PARALLEL_SAMPLES > 1) extract_sample = data[1*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS]; else `ERROR__Illegal_usage
     2:if (SPD_PARALLEL_SAMPLES > 2) extract_sample = data[2*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS]; else `ERROR__Illegal_usage
     3:if (SPD_PARALLEL_SAMPLES > 3) extract_sample = data[3*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS]; else `ERROR__Illegal_usage
     4:if (SPD_PARALLEL_SAMPLES > 4) extract_sample = data[4*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS]; else `ERROR__Illegal_usage
     5:if (SPD_PARALLEL_SAMPLES > 5) extract_sample = data[5*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS]; else `ERROR__Illegal_usage
     6:if (SPD_PARALLEL_SAMPLES > 6) extract_sample = data[6*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS]; else `ERROR__Illegal_usage
     7:if (SPD_PARALLEL_SAMPLES > 7) extract_sample = data[7*SPD_DATAWIDTH_BITS +: SPD_DATAWIDTH_BITS]; else `ERROR__Illegal_usage
     default: `ERROR__Illegal_usage
   endcase
endfunction

function [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] extract_ch_all_sample;
   input [RT_CH_WIDTH-1:0] data; //retruned by "extract_ch(ch)"
   extract_ch_all_sample = data[0 +: SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS];
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
     1:if (SPD_PARALLEL_SAMPLES > 1) extract_ch_a = extract_sample(extract_ch(CH_A), 1); else `ERROR__Illegal_usage
     2:if (SPD_PARALLEL_SAMPLES > 2) extract_ch_a = extract_sample(extract_ch(CH_A), 2); else `ERROR__Illegal_usage
     3:if (SPD_PARALLEL_SAMPLES > 3) extract_ch_a = extract_sample(extract_ch(CH_A), 3); else `ERROR__Illegal_usage
     4:if (SPD_PARALLEL_SAMPLES > 4) extract_ch_a = extract_sample(extract_ch(CH_A), 4); else `ERROR__Illegal_usage
     5:if (SPD_PARALLEL_SAMPLES > 5) extract_ch_a = extract_sample(extract_ch(CH_A), 5); else `ERROR__Illegal_usage
     6:if (SPD_PARALLEL_SAMPLES > 6) extract_ch_a = extract_sample(extract_ch(CH_A), 6); else `ERROR__Illegal_usage
     7:if (SPD_PARALLEL_SAMPLES > 7) extract_ch_a = extract_sample(extract_ch(CH_A), 7); else `ERROR__Illegal_usage
     default: `ERROR__Illegal_usage
   endcase
endfunction

function [SPD_DATAWIDTH_BITS-1:0] extract_ch_b;
  input integer       idx;
   case (idx)
     0:                              extract_ch_b = extract_sample(extract_ch(CH_B), 0);
     1:if (SPD_PARALLEL_SAMPLES > 1) extract_ch_b = extract_sample(extract_ch(CH_B), 1); else `ERROR__Illegal_usage
     2:if (SPD_PARALLEL_SAMPLES > 2) extract_ch_b = extract_sample(extract_ch(CH_B), 2); else `ERROR__Illegal_usage
     3:if (SPD_PARALLEL_SAMPLES > 3) extract_ch_b = extract_sample(extract_ch(CH_B), 3); else `ERROR__Illegal_usage
     4:if (SPD_PARALLEL_SAMPLES > 4) extract_ch_b = extract_sample(extract_ch(CH_B), 4); else `ERROR__Illegal_usage
     5:if (SPD_PARALLEL_SAMPLES > 5) extract_ch_b = extract_sample(extract_ch(CH_B), 5); else `ERROR__Illegal_usage
     6:if (SPD_PARALLEL_SAMPLES > 6) extract_ch_b = extract_sample(extract_ch(CH_B), 6); else `ERROR__Illegal_usage
     7:if (SPD_PARALLEL_SAMPLES > 7) extract_ch_b = extract_sample(extract_ch(CH_B), 7); else `ERROR__Illegal_usage
     default: `ERROR__Illegal_usage
   endcase
endfunction

function [SPD_DATAWIDTH_BITS-1:0] extract_ch_c;
  input integer       idx;
   case (idx)
     0:                              extract_ch_c = extract_sample(extract_ch(CH_C), 0);
     1:if (SPD_PARALLEL_SAMPLES > 1) extract_ch_c = extract_sample(extract_ch(CH_C), 1); else `ERROR__Illegal_usage
     2:if (SPD_PARALLEL_SAMPLES > 2) extract_ch_c = extract_sample(extract_ch(CH_C), 2); else `ERROR__Illegal_usage
     3:if (SPD_PARALLEL_SAMPLES > 3) extract_ch_c = extract_sample(extract_ch(CH_C), 3); else `ERROR__Illegal_usage
     4:if (SPD_PARALLEL_SAMPLES > 4) extract_ch_c = extract_sample(extract_ch(CH_C), 4); else `ERROR__Illegal_usage
     5:if (SPD_PARALLEL_SAMPLES > 5) extract_ch_c = extract_sample(extract_ch(CH_C), 5); else `ERROR__Illegal_usage
     6:if (SPD_PARALLEL_SAMPLES > 6) extract_ch_c = extract_sample(extract_ch(CH_C), 6); else `ERROR__Illegal_usage
     7:if (SPD_PARALLEL_SAMPLES > 7) extract_ch_c = extract_sample(extract_ch(CH_C), 7); else `ERROR__Illegal_usage
     default: `ERROR__Illegal_usage
   endcase
endfunction

function [SPD_DATAWIDTH_BITS-1:0] extract_ch_d;
  input integer       idx;
   case (idx)
     0:                              extract_ch_d = extract_sample(extract_ch(CH_D), 0);
     1:if (SPD_PARALLEL_SAMPLES > 1) extract_ch_d = extract_sample(extract_ch(CH_D), 1); else `ERROR__Illegal_usage
     2:if (SPD_PARALLEL_SAMPLES > 2) extract_ch_d = extract_sample(extract_ch(CH_D), 2); else `ERROR__Illegal_usage
     3:if (SPD_PARALLEL_SAMPLES > 3) extract_ch_d = extract_sample(extract_ch(CH_D), 3); else `ERROR__Illegal_usage
     4:if (SPD_PARALLEL_SAMPLES > 4) extract_ch_d = extract_sample(extract_ch(CH_D), 4); else `ERROR__Illegal_usage
     5:if (SPD_PARALLEL_SAMPLES > 5) extract_ch_d = extract_sample(extract_ch(CH_D), 5); else `ERROR__Illegal_usage
     6:if (SPD_PARALLEL_SAMPLES > 6) extract_ch_d = extract_sample(extract_ch(CH_D), 6); else `ERROR__Illegal_usage
     7:if (SPD_PARALLEL_SAMPLES > 7) extract_ch_d = extract_sample(extract_ch(CH_D), 7); else `ERROR__Illegal_usage
     default: `ERROR__Illegal_usage
   endcase
endfunction

function [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] extract_all_ch_samples;
   input [RT_CH_WIDTH-1:0] data;
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

function [SPD_ANALOG_CHANNELS*SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] extract_all_sample;
   input integer        dummy;
   case (SPD_ANALOG_CHANNELS)
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

//CH trig
function [RT_CH_TRIG_VECTOR_1_WIDTH-1:0] extract_ch_trig;
   input [RT_CH_WIDTH-1:0] data;
   extract_ch_trig = data[SPD_PARALLEL_SAMPLES * SPD_DATAWIDTH_BITS +: RT_CH_TRIG_VECTOR_1_WIDTH];
endfunction
function [RT_CH_TRIG_VECTOR_1_WIDTH-1:0] extract_ch_trig_a;
   input integer        dummy;
   extract_ch_trig_a = extract_ch_trig(extract_ch(CH_A));
endfunction
function [RT_CH_TRIG_VECTOR_1_WIDTH-1:0] extract_ch_trig_b;
   input integer        dummy;
   extract_ch_trig_b = extract_ch_trig(extract_ch(CH_B));
endfunction
function [RT_CH_TRIG_VECTOR_1_WIDTH-1:0] extract_ch_trig_c;
   input integer        dummy;
   extract_ch_trig_c = extract_ch_trig(extract_ch(CH_C));
endfunction
function [RT_CH_TRIG_VECTOR_1_WIDTH-1:0] extract_ch_trig_d;
   input integer        dummy;
   extract_ch_trig_d = extract_ch_trig(extract_ch(CH_D));
endfunction

function  extract_ch_over_range;
   input [RT_CH_WIDTH-1:0] data;
   extract_ch_over_range = data[SPD_PARALLEL_SAMPLES * SPD_DATAWIDTH_BITS + RT_CH_TRIG_VECTOR_1_WIDTH +: 1];
endfunction

function extract_over_range_a;
   input integer        dummy;
   extract_over_range_a = extract_ch_over_range(extract_ch(CH_A));
endfunction
function extract_over_range_b;
   input integer        dummy;
   extract_over_range_b = extract_ch_over_range(extract_ch(CH_B));
endfunction
function extract_over_range_c;
   input integer        dummy;
   extract_over_range_c = extract_ch_over_range(extract_ch(CH_C));
endfunction
function extract_over_range_d;
   input integer        dummy;
   extract_over_range_d = extract_ch_over_range(extract_ch(CH_D));
endfunction

function [RT_SPD_GENERAL_PURPOSE_WIDTH-1:0] extract_ch_general_purpose_vector;
   input [RT_CH_WIDTH-1:0] data;
   extract_ch_general_purpose_vector = data[SPD_PARALLEL_SAMPLES * SPD_DATAWIDTH_BITS + RT_CH_TRIG_VECTOR_1_WIDTH + RT_SPD_OVER_RANGE_1_WIDTH +: RT_SPD_GENERAL_PURPOSE_WIDTH];
endfunction

function [RT_SPD_GENERAL_PURPOSE_WIDTH-1:0] extract_general_purpose_vector_a;
   input integer        dummy;
   extract_general_purpose_vector_a = extract_ch_general_purpose_vector(extract_ch(CH_A));
endfunction
function [RT_SPD_GENERAL_PURPOSE_WIDTH-1:0] extract_general_purpose_vector_b;
   input integer        dummy;
   extract_general_purpose_vector_b = extract_ch_general_purpose_vector(extract_ch(CH_B));
endfunction
function [RT_SPD_GENERAL_PURPOSE_WIDTH-1:0] extract_general_purpose_vector_c;
   input integer        dummy;
   extract_general_purpose_vector_c = extract_ch_general_purpose_vector(extract_ch(CH_C));
endfunction
function [RT_SPD_GENERAL_PURPOSE_WIDTH-1:0] extract_general_purpose_vector_d;
   input integer        dummy;
   extract_general_purpose_vector_d = extract_ch_general_purpose_vector(extract_ch(CH_D));
endfunction

`endif
