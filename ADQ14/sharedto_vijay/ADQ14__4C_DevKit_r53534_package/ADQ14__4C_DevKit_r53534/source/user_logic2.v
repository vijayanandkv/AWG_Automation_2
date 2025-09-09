/* -*- coding: us-ascii-dos -*-
 *
 * Copyright Signal Processing Devices Sweden AB. All rights reserved.
 * See document "08-0175 EULA" for specific license terms regarding this file.
 *
 * Description: User logic 2 module
 *
 */

`timescale 1 ns / 1 ps

`default_nettype none
`include "user_logic2_defines.vh"

module user_logic2 # (
   // Do not modify the parameters beyond this line
   parameter integer CH_TRIG_DATA_WIDTH = `UL2_SPD_ANALOG_CHANNELS * `UL2_SPD_DATAWIDTH_BITS * `UL2_SPD_PARALLEL_SAMPLES,
   parameter integer CH_TRIG_VECTOR_WIDTH = `UL2_SPD_ANALOG_CHANNELS * (`UL2_SPD_NUM_CH_TRIG_BITS+`UL2_SPD_NUM_TRIG_ADDBITS+`UL2_SPD_NUM_TRIG_DATARD_ADDFRACBITS),
   parameter integer ADDR_WIDTH = 19
) (
   input wire                             clk,
   input wire                             rst_i,
   input wire                             wr_i,
   output wire                            wr_ack_o,
   input wire [ADDR_WIDTH-1:0]            addr_i,
   input wire [31:0]                      wr_data_i,
   input wire                             rd_i,
   output wire                            rd_ack_o,
   output wire [31:0]                     rd_data_o,

   // Ports of AXI-S Slave Bus Interface s_axis
   input wire                             s_axis_aclk,
   input wire                             s_axis_aresetn,
   input wire [`UL2_DATA_BUS_WIDTH-1 : 0] s_axis_tdata,
   input wire                             s_axis_tvalid,

   // Ports of AXI-S Master Bus Interface m_axis
   input wire                             m_axis_aclk,
   input wire                             m_axis_aresetn,
   output reg                             m_axis_tvalid,
   output reg [`UL2_DATA_BUS_WIDTH-1 : 0] m_axis_tdata,

   // GPIO
   // To board
   input wire [15:0]                      gpio_in_i,
   output wire [15:0]                     gpio_out_o,
   output wire [15:0]                     gpio_dir_o,

   input wire [4:0]                       gpio_ctrl_in_i,
   output wire [4:0]                      gpio_ctrl_out_o,
   output wire [4:0]                      gpio_ctrl_dir_o,

   input wire                             gpio_trig_in_i,
   output wire                            gpio_trig_out_o,
   output wire                            gpio_trig_dir_o,

   input wire                             gpio_sync_in_i,
   output wire                            gpio_sync_out_o,
   output wire                            gpio_sync_dir_o,


   // From CPU
   output wire [15:0]                     gpio_in_o,
   input wire [15:0]                      gpio_out_i,
   input wire [15:0]                      gpio_dir_i,

   output wire [4:0]                      gpio_ctrl_in_o,
   input wire [4:0]                       gpio_ctrl_out_i,
   input wire [4:0]                       gpio_ctrl_dir_i,

   output wire                            gpio_trig_in_o,
   input wire                             gpio_trig_out_i,
   input wire                             gpio_trig_dir_i,

   output wire                            gpio_sync_in_o,
   input wire                             gpio_sync_out_i,
   input wire                             gpio_sync_dir_i,

   // DRAM ports
   input wire                             clk_mem_i,

   output wire [511:0]                    write1_data_o,
   input wire                             write1_done_i,
   output wire                            write1_empty_o,
   output wire [31:0]                     write1_first_addr_o,
   output wire [31:0]                     write1_last_addr_o,
   output wire                            write1_last_o,
   input wire                             write1_read_i,
   output wire                            write1_reset_o,
   output wire                            write1_strobe_o,

   output wire [511:0]                    write2_data_o,
   input wire                             write2_done_i,
   output wire                            write2_empty_o,
   output wire [31:0]                     write2_first_addr_o,
   output wire [31:0]                     write2_last_addr_o,
   output wire                            write2_last_o,
   input wire                             write2_read_i,
   output wire                            write2_reset_o,
   output wire                            write2_strobe_o,

   output wire                            read1_abort_o,
   output wire                            read1_afull_o,
   input wire [511:0]                     read1_data_i,
   input wire                             read1_done_i,
   output wire [31:0]                     read1_first_addr_o,
   input wire                             read1_firstdata_i,
   output wire [31:0]                     read1_high_addr_o,
   output wire [31:0]                     read1_last_addr_o,
   input wire                             read1_lastdata_i,
   output wire [31:0]                     read1_low_addr_o,
   output wire                            read1_reset_o,
   input wire                             read1_sent_i,
   output wire                            read1_strobe_o,
   input wire                             read1_wr_i,

   output wire                            read2_abort_o,
   output wire                            read2_afull_o,
   input wire [511:0]                     read2_data_i,
   input wire                             read2_done_i,
   output wire [31:0]                     read2_first_addr_o,
   input wire                             read2_firstdata_i,
   output wire [31:0]                     read2_high_addr_o,
   output wire [31:0]                     read2_last_addr_o,
   input wire                             read2_lastdata_i,
   output wire [31:0]                     read2_low_addr_o,
   output wire                            read2_reset_o,
   input wire                             read2_sent_i,
   output wire                            read2_strobe_o,
   input wire                             read2_wr_i
);
   // Users to add localparam here

   // The BUS_PIPELINE value must always be set equal to the latency of your
   // data processing in this module in order to synchronize unused bus signals.
   localparam BUS_PIPELINE = 2;

   // These includes are need to extract data from the AXIS bus
   `include "device_param.vh"
   `include "bus_splitter_rr.vh"

   // User application code
   wire [31:0] reg_0x10_in;
   wire [31:0] reg_0x11_in;
   wire [31:0] reg_0x12_in;
   wire [31:0] reg_0x13_in;

   wire [31:0] reg_0x10_out;
   wire [31:0] reg_0x11_out;
   wire [31:0] reg_0x12_out;
   wire [31:0] reg_0x13_out;

   reg record_stop_a;
   reg record_start_a;
   reg record_stop_b;
   reg record_start_b;
   reg record_stop_c;
   reg record_start_c;
   reg record_stop_d;
   reg record_start_d;

   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_a_in;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_b_in;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_c_in;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_d_in;

   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_a_out;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_b_out;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_c_out;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_d_out;

   reg data_valid_a_in;
   reg data_valid_a_out;
   reg data_valid_b_in;
   reg data_valid_b_out;
   reg data_valid_c_in;
   reg data_valid_c_out;
   reg data_valid_d_in;
   reg data_valid_d_out;
   reg en_data_valid_a_out;
   reg en_data_valid_b_out;
   reg en_data_valid_c_out;
   reg en_data_valid_d_out;
   reg data_valid_a_out_gated;
   reg data_valid_b_out_gated;
   reg data_valid_c_out_gated;
   reg data_valid_d_out_gated;
   reg data_valid_testpattern;

   reg [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] ch_trig_vector_a;
   reg [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] ch_trig_vector_b;
   reg [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] ch_trig_vector_c;
   reg [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] ch_trig_vector_d;

   assign reg_0x10_in = reg_0x10_out;
   assign reg_0x11_in = reg_0x11_out;
   assign reg_0x12_in = 32'haabbccdd;
   assign reg_0x13_in = 32'h12345678;

   // Note: This register file is an example. The source code is included so
   // that it can be modified by the user.
   regfile #(
       .ADDR_WIDTH(ADDR_WIDTH)
   ) regfile_inst (
      .clk(clk),
      .rst_i(rst_i),
      .addr_i(addr_i),

      .wr_i(wr_i),
      .wr_ack_o(wr_ack_o),
      .wr_data_i(wr_data_i),

      .rd_i(rd_i),
      .rd_ack_o(rd_ack_o),
      .rd_data_o(rd_data_o),

      .reg_0x10_i(reg_0x10_in),
      .reg_0x11_i(reg_0x11_in),
      .reg_0x12_i(reg_0x12_in),
      .reg_0x13_i(reg_0x13_in),

      .reg_0x10_o(reg_0x10_out),
      .reg_0x11_o(reg_0x11_out),
      .reg_0x12_o(reg_0x12_out),
      .reg_0x13_o(reg_0x13_out)
   );


   //NOTE: Vivado requires two registers with ASYNC_REG="TRUE" constraint for
   //clock domain crossing.
   (* ASYNC_REG="TRUE" *) reg [1:0] clear_cnt;
   (* ASYNC_REG="TRUE" *) reg [1:0] mode;
   (* ASYNC_REG="TRUE" *) reg [1:0] enable_data_valid;
   (* ASYNC_REG="TRUE" *) reg [1:0] reset_data_valid;
   (* ASYNC_REG="TRUE" *) reg [1:0] always_data_valid;
   (* ASYNC_REG="TRUE" *) reg [1:0] enable_8b_mode;
   always @ (posedge s_axis_aclk) begin
      clear_cnt         <= {clear_cnt[0],         reg_0x10_out[0]};
      mode              <= {mode[0],              reg_0x10_out[1]};
      enable_data_valid <= {enable_data_valid[0], reg_0x11_out[0]};
      reset_data_valid  <= {reset_data_valid[0],  reg_0x11_out[1]};
      always_data_valid <= {always_data_valid[0], ~reg_0x11_out[2]};
      enable_8b_mode    <= {enable_8b_mode[0],    reg_0x11_out[3]};
   end

   // 8 Bits mode data
   wire [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_ab_8b;

   // Test pattern example code
   reg [15:0] cnt;
   wire [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_a_x;
   wire [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_b_x;


   always @ (posedge s_axis_aclk) begin
      if(clear_cnt[1])
         cnt <= 0;
      if(data_valid_testpattern)
         cnt = cnt + SPD_PARALLEL_SAMPLES;
   end

   if (SPD_PARALLEL_SAMPLES  == 8) begin
      //Sample order:     Last                                                                          First
      assign  data_a_x = {cnt+16'd7, cnt+16'd6, cnt+16'd5, cnt+16'd4,  cnt+16'd3, cnt+16'd2, cnt+16'd1, cnt  };
      assign  data_b_x = {16'hf,     16'he,     16'hd,     16'hc,      16'hb,     16'ha,     16'h9,     16'h8};
   end
   else begin
      // 4 Parallel samples
      //Sample order:     Last                             First
      assign  data_a_x = {cnt+16'd3, cnt+16'd2, cnt+16'd1, cnt  };
      assign  data_b_x = {16'hd,     16'hc,     16'hb,     16'ha};
   end

   // Data valid gating for testpattern
   always @ (posedge s_axis_aclk) begin
      if(enable_data_valid[1]) begin
         // NOTE: "data_valid_testpattern" will most likely be a user
         // generated signal in an real use-case. Using "data_valid_a_in"
         // is just a convenient way of generating pulses in this example.
         data_valid_testpattern <= data_valid_a_in;
      end
   end


   // Truncate Ch A and Ch B to 8 bits and combine to 16 bits
   genvar  k;
   for (k = 0; k < SPD_PARALLEL_SAMPLES; k = k + 1) begin
      assign data_ab_8b[(k+1)*16-1:k*16] = {data_a_in[(k+1)*16-1:k*16+8], data_b_in[(k+1)*16-1:k*16+8]};
   end


   // Mux to select data or testpattern
   // BUS_PIPELINE = 2
   always @ (posedge s_axis_aclk) begin
      if (!s_axis_aresetn) begin
         en_data_valid_a_out <= 1'b0;
         en_data_valid_b_out <= 1'b0;
         en_data_valid_c_out <= 1'b0;
         en_data_valid_d_out <= 1'b0;
      end else begin
         if(mode[1]) begin // Test pattern
            data_a_out <= data_a_x;
            data_b_out <= data_b_x;

            //NOTE: Data valid must be asserted in all channes simultaneously
            //when running raw streaming (e.g. without headers) It is possible
            //to set a channel mask via the ADQAPI to read out a subset of the
            //channels, so even if data valid is asserted data can still be
            //discarded.
            data_valid_a_out <= data_valid_testpattern;
            data_valid_b_out <= data_valid_testpattern;
            data_valid_c_out <= data_valid_testpattern;
            data_valid_d_out <= data_valid_testpattern;
         end
         else begin // Normal
            if (enable_8b_mode[1]) begin
               data_a_out <= data_ab_8b;
               data_b_out <= 0;
               data_c_out <= 0;
               data_d_out <= 0;
            end else begin
               data_a_out <= data_a_in;
               data_b_out <= data_b_in;
               data_c_out <= data_c_in;
               data_d_out <= data_d_in;
            end

            data_valid_a_out <= data_valid_a_in;
            data_valid_b_out <= data_valid_b_in;
            data_valid_c_out <= data_valid_c_in;
            data_valid_d_out <= data_valid_d_in;

            en_data_valid_a_out <= always_data_valid[1] | ((record_start_a | en_data_valid_a_out) & ~record_stop_a & ~reset_data_valid[1]);
            en_data_valid_b_out <= always_data_valid[1] | ((record_start_b | en_data_valid_b_out) & ~record_stop_b & ~reset_data_valid[1]);
            en_data_valid_c_out <= always_data_valid[1] | ((record_start_c | en_data_valid_c_out) & ~record_stop_c & ~reset_data_valid[1]);
            en_data_valid_d_out <= always_data_valid[1] | ((record_start_d | en_data_valid_d_out) & ~record_stop_d & ~reset_data_valid[1]);
         end
      end
   end

   //BUS_PIPELINE = 1
   always @ (posedge s_axis_aclk) begin
      // Extract all parallel samples for each channel
      data_a_in <= extract_ch_a_all(DONT_CARE);
      if (SPD_ANALOG_CHANNELS > 1)
         data_b_in <= extract_ch_b_all(DONT_CARE);
      if (SPD_ANALOG_CHANNELS > 2)
         data_c_in <= extract_ch_c_all(DONT_CARE);
      if (SPD_ANALOG_CHANNELS > 3)
         data_d_in <= extract_ch_d_all(DONT_CARE);

      // Extract record bits
      {record_stop_a, record_start_a} <= extract_record_bits_a(DONT_CARE);
      if (SPD_ANALOG_CHANNELS > 1)
         {record_stop_b, record_start_b} <= extract_record_bits_b(DONT_CARE);
      if (SPD_ANALOG_CHANNELS > 2)
         {record_stop_c, record_start_c} <= extract_record_bits_c(DONT_CARE);
      if (SPD_ANALOG_CHANNELS > 3)
         {record_stop_d, record_start_d} <= extract_record_bits_d(DONT_CARE);

      //Individual parallel sampals can be extracted using:
      /*
      data_a0 <= extract_ch_a(0);
      data_a1 <= extract_ch_a(1);
      data_a2 <= extract_ch_a(2);
      data_a3 <= extract_ch_a(3);

      data_b0 <= extract_ch_b(0);
      data_b1 <= extract_ch_b(1);
      data_b2 <= extract_ch_b(2);
      data_b3 <= extract_ch_b(3);

      data_c0 <= extract_ch_c(0);
      data_c1 <= extract_ch_c(1);
      data_c2 <= extract_ch_c(2);
      data_c3 <= extract_ch_c(3);

      data_d0 <= extract_ch_d(0);
      data_d1 <= extract_ch_d(1);
      data_d2 <= extract_ch_d(2);
      data_d3 <= extract_ch_d(3);
      */

      data_valid_a_in <= extract_data_valid_a(DONT_CARE);
      if (SPD_ANALOG_CHANNELS > 1)
         data_valid_b_in <= extract_data_valid_b(DONT_CARE);
      if (SPD_ANALOG_CHANNELS > 2)
         data_valid_c_in <= extract_data_valid_c(DONT_CARE);
      if (SPD_ANALOG_CHANNELS > 3)
         data_valid_d_in <= extract_data_valid_d(DONT_CARE);
   end

   // User inserting into bus output
   // BUS_PIPELINE = 2
   always@(*) begin
      data_valid_a_out_gated <= (record_start_a | en_data_valid_a_out) & data_valid_a_out;
      data_valid_b_out_gated <= (record_start_b | en_data_valid_b_out) & data_valid_b_out;
      data_valid_c_out_gated <= (record_start_c | en_data_valid_c_out) & data_valid_c_out;
      data_valid_d_out_gated <= (record_start_d | en_data_valid_d_out) & data_valid_d_out;

      init_bus_output();

      // Note: Non-inserted signals will automatically be addded by a macro.
      //       They will be delayed by the value defined by BUS_PIPELINE.

      insert_ch_a_all(data_a_out);
      if (SPD_ANALOG_CHANNELS > 1)
         insert_ch_b_all(data_b_out);
      if (SPD_ANALOG_CHANNELS > 2)
         insert_ch_c_all(data_c_out);
      if (SPD_ANALOG_CHANNELS > 3)
         insert_ch_d_all(data_d_out);

      insert_data_valid_a(data_valid_a_out_gated);
      if (SPD_ANALOG_CHANNELS > 1)
         insert_data_valid_b(data_valid_b_out_gated);
      if (SPD_ANALOG_CHANNELS > 2)
         insert_data_valid_c(data_valid_c_out_gated);
      if (SPD_ANALOG_CHANNELS > 3)
         insert_data_valid_d(data_valid_d_out_gated);

      finish_bus_output();
   end

   // GPIO
   assign gpio_in_o = gpio_in_i;
   assign gpio_out_o = gpio_out_i;
   assign gpio_dir_o = gpio_dir_i;

   assign gpio_ctrl_in_o = gpio_ctrl_in_i;
   assign gpio_ctrl_out_o = gpio_ctrl_out_i;
   assign gpio_ctrl_dir_o = gpio_ctrl_dir_i;

   assign gpio_trig_in_o = gpio_trig_in_i;
   assign gpio_trig_out_o = gpio_trig_out_i;
   assign gpio_trig_dir_o = gpio_trig_dir_i;

   assign gpio_sync_in_o = gpio_sync_in_i;
   assign gpio_sync_out_o = gpio_sync_out_i;
   assign gpio_sync_dir_o = gpio_sync_dir_i;


   // DRAM port outputs must be set to zero if unused
   assign write1_data_o = 0;
   assign write1_empty_o = 0;
   assign write1_first_addr_o = 0;
   assign write1_last_addr_o = 0;
   assign write1_last_o = 0;
   assign write1_reset_o = 0;
   assign write1_strobe_o = 0;

   assign write2_data_o = 0;
   assign write2_empty_o = 0;
   assign write2_first_addr_o = 0;
   assign write2_last_addr_o = 0;
   assign write2_last_o = 0;
   assign write2_reset_o = 0;
   assign write2_strobe_o = 0;

   assign read1_abort_o = 0;
   assign read1_afull_o = 0;
   assign read1_first_addr_o = 0;
   assign read1_high_addr_o = 0;
   assign read1_last_addr_o = 0;
   assign read1_low_addr_o = 0;
   assign read1_reset_o = 0;
   assign read1_strobe_o = 0;

   assign read2_abort_o = 0;
   assign read2_afull_o = 0;
   assign read2_first_addr_o = 0;
   assign read2_high_addr_o = 0;
   assign read2_last_addr_o = 0;
   assign read2_low_addr_o = 0;
   assign read2_reset_o = 0;
   assign read2_strobe_o = 0;

endmodule

`default_nettype wire
