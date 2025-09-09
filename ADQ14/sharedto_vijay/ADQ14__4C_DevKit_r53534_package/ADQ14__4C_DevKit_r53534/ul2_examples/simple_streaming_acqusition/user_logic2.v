/* -*- coding: us-ascii-dos -*-
 *
 * Copyright Signal Processing Devices Sweden AB. All rights reserved.
 * See document "08-0175 EULA" for specific license terms regarding this file.
 *
 * Description   : User logic 2 module
 * Documentation : This custom module demonstrates how to implement a simple
 *                 streaming acquisition engine with very little effort. Only 
 *                 3 user registers are needed to control the acqusition parameters.
 *                 If further data processing is required, it can be inserted 
 *                 Between the extract and insert step.
 *
 *                 The resulting firmware file built with this module can be used
 *                 together with the accomodating software built with ADQAPI library.
 *                 The software project should be found under the same directory as 
 *                 this source file.
 */

`timescale 1 ns / 1 ps

`default_nettype none
`include "user_logic2_defines.vh"

	module user_logic2 #
	  (
		 // Users to add parameters here

	   // User parameters ends

     // Do not modify the parameters beyond this line
     parameter integer CH_TRIG_DATA_WIDTH = `UL2_SPD_ANALOG_CHANNELS * `UL2_SPD_DATAWIDTH_BITS * `UL2_SPD_PARALLEL_SAMPLES,
     parameter integer CH_TRIG_VECTOR_WIDTH = `UL2_SPD_ANALOG_CHANNELS * (`UL2_SPD_NUM_CH_TRIG_BITS+`UL2_SPD_NUM_TRIG_ADDBITS+`UL2_SPD_NUM_TRIG_DATARD_ADDFRACBITS),
     parameter integer ADDR_WIDTH = 19
     )
   (
    input wire                             clk,
    input wire                             rst_i,
    input wire                             wr_i,
    output wire                            wr_ack_o,
    input wire [ADDR_WIDTH-1:0]            addr_i,
    input wire [31:0]                      wr_data_i,
    input wire                             rd_i,
    output wire                            rd_ack_o,
    output wire [31:0]                     rd_data_o,

		// Ports of Axi Slave Bus Interface s_axis
	  input wire                             s_axis_aclk,
	  input wire                             s_axis_aresetn,
	  input wire [`UL2_DATA_BUS_WIDTH-1 : 0] s_axis_tdata,
	  input wire                             s_axis_tvalid,

		// Ports of Axi Master Bus Interface m_axis
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

    // Dram ports
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

   //This value must always be set to the delay of your data from in to out in this module to get correct trigger syncronization.
   localparam BUS_PIPELINE = 2;

   // User localparam ends

   // This include is need to extract data from the AXIS bus
`include "device_param.vh"
`include "bus_splitter_rr.vh"


   // User application code
   wire [31:0]                             reg_0x10_in;
   wire [31:0]                             reg_0x11_in;
   wire [31:0]                             reg_0x12_in;
   wire [31:0]                             reg_0x13_in;

   wire [31:0]                             reg_0x10_out;
   wire [31:0]                             reg_0x11_out;
   wire [31:0]                             reg_0x12_out;
   wire [31:0]                             reg_0x13_out;


   (* mark_debug = "true" *) reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_a_in;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_b_in;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_c_in;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_d_in;

   (* mark_debug = "true" *) reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_a_out;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_b_out;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_c_out;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_d_out;

   (* mark_debug = "true" *) reg                                               data_valid_a_in;
   (* mark_debug = "true" *) reg                                               data_valid_a_out;
   reg                                               data_valid_b_in;
   reg                                               data_valid_b_out;
   reg                                               data_valid_c_in;
   reg                                               data_valid_c_out;   
   reg                                               data_valid_d_in;
   reg                                               data_valid_d_out;     
   reg                                               data_valid_stream;

   (* mark_debug = "true" *)  reg [RR_CH_TRIG_VECTOR_1_WIDTH-1:0]               ch_trig_vector_a_in;
   reg [RR_CH_TRIG_VECTOR_1_WIDTH-1:0]               ch_trig_vector_b_in;
   reg [RR_CH_TRIG_VECTOR_1_WIDTH-1:0]               ch_trig_vector_c_in;
   reg [RR_CH_TRIG_VECTOR_1_WIDTH-1:0]               ch_trig_vector_d_in;

   assign reg_0x10_in = reg_0x10_out;
   assign reg_0x11_in = reg_0x11_out;
   assign reg_0x12_in = reg_0x12_out;
   assign reg_0x13_in = 32'h12345678;               //This value is provided to demonstrate that it can be read from the ADQAPI using ADQ_ReadUserRegister()

   // Note: This register file is an example it is provided with source code so that it can be modified by the user
   regfile
     #(
       .ADDR_WIDTH(ADDR_WIDTH)
       )
   regfile_inst
     (
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


//===========================================DATA AND TRIGGER EXTRACTION START==========================================================

   //BUS_PIPELINE = 1
   always @ (posedge s_axis_aclk)
     begin

        // Extract all pralell samples for each channel
        data_a_in <= extract_ch_a_all(DONT_CARE);
        
        if (SPD_ANALOG_CHANNELS > 1)
          data_b_in <= extract_ch_b_all(DONT_CARE);

        if (SPD_ANALOG_CHANNELS > 2)
          data_c_in <= extract_ch_c_all(DONT_CARE);
          
        if (SPD_ANALOG_CHANNELS > 3)
          data_d_in <= extract_ch_d_all(DONT_CARE);

        //Individual parallel sampales are extracted with:
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
        //Extract data valid for all channels
        data_valid_a_in <= extract_data_valid_a(DONT_CARE);
        
        if (SPD_ANALOG_CHANNELS > 1)
          data_valid_b_in <= extract_data_valid_b(DONT_CARE);
        if (SPD_ANALOG_CHANNELS > 2)
          data_valid_c_in <= extract_data_valid_c(DONT_CARE);
        if (SPD_ANALOG_CHANNELS > 3)
          data_valid_d_in <= extract_data_valid_d(DONT_CARE);
          
        //Extract trigger vectors for all channels.
        //In fact the trigger vectors for all channels are the same so there is really no need to extract all of them
        ch_trig_vector_a_in <= extract_ch_trig_a(DONT_CARE);
        
        if (SPD_ANALOG_CHANNELS > 1)
          ch_trig_vector_b_in <= extract_ch_trig_b(DONT_CARE);
        if (SPD_ANALOG_CHANNELS > 2)
          ch_trig_vector_c_in <= extract_ch_trig_c(DONT_CARE);
        if (SPD_ANALOG_CHANNELS > 3)
          ch_trig_vector_d_in <= extract_ch_trig_d(DONT_CARE);
          
     end

 //===========================================DATA AND TRIGGER EXTRACTION END==========================================================
 
 

 //===========================================SIMPLE ACQUISITION LOGIC START=========================================================== 
  (* mark_debug = "true" *) wire        trigger_event_a;
  (* mark_debug = "true" *) wire        trigger_edge_a;
  (* mark_debug = "true" *) wire [1:0]  trigger_position_a;

  //wire        trigger_event_b;
  //wire        trigger_edge_b;
  //wire [1:0]  trigger_position_b;
  
  //wire        trigger_event_c;
  //wire        trigger_edge_c;
  //wire [1:0]  trigger_position_c;
  
  //wire        trigger_event_d;
  //wire        trigger_edge_d;
  //wire [1:0]  trigger_position_d;
  
  assign trigger_event_a = ch_trig_vector_a_in[22];
  assign trigger_edge_a = ch_trig_vector_a_in[21];
  assign trigger_position_a = ch_trig_vector_a_in[20:19];     //Use this sample position to implement a barrelshift if trigger precision is important
     
  //assign trigger_event_b = ch_trig_vector_b_in[22];
  //assign trigger_edge_b = ch_trig_vector_b_in[21];
  //assign trigger_position_b = ch_trig_vector_b_in[20:19];
  
  //assign trigger_event_c = ch_trig_vector_c_in[22];
  //assign trigger_edge_c = ch_trig_vector_c_in[21];
  //assign trigger_position_c = ch_trig_vector_c_in[20:19];
  
  //assign trigger_event_d = ch_trig_vector_d_in[22];
  //assign trigger_edge_d = ch_trig_vector_d_in[21];
  //assign trigger_position_d = ch_trig_vector_d_in[20:19];
  
  (* mark_debug = "true" *) reg enable_devkit_code;
  (* mark_debug = "true" *) reg enable_devkit_code_d1;
  (* mark_debug = "true" *) wire enable_pulse;
  (* mark_debug = "true" *) reg acquisition_armed;
  (* mark_debug = "true" *) wire cycle_counter_at_max;
  (* mark_debug = "true" *) wire repetition_counter_at_max;
  (* mark_debug = "true" *) reg [31:0] cycle_counter;
  (* mark_debug = "true" *) reg [31:0] repetition_counter;
  (* mark_debug = "true" *) reg [31:0] sample_cycle_limit;
  (* mark_debug = "true" *) reg [31:0] repetition_limit;


  always @ (posedge s_axis_aclk)
    begin
      enable_devkit_code <= reg_0x10_out[0];          //Control signal from host PC
      enable_devkit_code_d1 <= enable_devkit_code;
      sample_cycle_limit <= reg_0x11_out;             //Control signal from host PC
      repetition_limit <= reg_0x12_out;               //Control signal from host PC
    end
    
  assign enable_pulse = enable_devkit_code && ~enable_devkit_code_d1;

  always @ (posedge s_axis_aclk)
    begin
      if (enable_devkit_code)
        begin
          if (data_valid_a_in)                                                       //data_valid_a_in will not go high until StartStreaming is called
            acquisition_armed <= 1'b1;                                               //Raise the armed signal on the first data_valid_a_in pulse only
        end
      else
        begin
          acquisition_armed <= 1'b0;
        end
    end

  always @(posedge s_axis_aclk)
    begin
      if (enable_pulse)
        begin
          repetition_counter <= 0;
          cycle_counter <= sample_cycle_limit;                                      //Keep at max to at the begining to synchorize with trigger event
        end
      else
        begin
          if (cycle_counter_at_max)
            begin
              if(trigger_event_a && acquisition_armed && ~repetition_counter_at_max)                     //There is no need to check trigger event for other channels because they are the same
                begin
                  cycle_counter <= 0;
                  repetition_counter <= repetition_counter + 1;
                end
            end
          else
            begin
              if (data_valid_a_in)
                begin
                  cycle_counter <= cycle_counter + 1;
                end
            end
        end        
    end
    
  assign cycle_counter_at_max = (cycle_counter >= sample_cycle_limit) ? 1'b1: 1'b0;
  assign repetition_counter_at_max = (repetition_counter >= repetition_limit) ? 1'b1: 1'b0;
    
  always @(posedge s_axis_aclk)
    begin
      if(enable_devkit_code_d1)                       
        begin
          if (cycle_counter_at_max)                    
            begin
              data_valid_a_out <= 1'b0;
              data_valid_b_out <= 1'b0;
              data_valid_c_out <= 1'b0;
              data_valid_d_out <= 1'b0;

              data_a_out <= 0;
              data_b_out <= 0;
              data_c_out <= 0;
              data_d_out <= 0;
            end
          else
            begin
              data_valid_a_out  <= data_valid_a_in;
              data_valid_b_out  <= data_valid_b_in;
              data_valid_c_out  <= data_valid_c_in;
              data_valid_d_out  <= data_valid_d_in;

              data_a_out <= data_a_in;
              data_b_out <= data_b_in;
              data_c_out <= data_c_in;
              data_d_out <= data_d_in;
            end
        end
      else
        begin
          data_valid_a_out  <= data_valid_a_in;
          data_valid_b_out  <= data_valid_b_in;
          data_valid_c_out  <= data_valid_c_in;
          data_valid_d_out  <= data_valid_d_in;

          data_a_out <= data_a_in;
          data_b_out <= data_b_in;
          data_c_out <= data_c_in;
          data_d_out <= data_d_in;
        end
    end

 //===========================================SIMPLE ACQUISITION LOGIC END===========================================================     
    
 //===========================================DATA INSERTION START===================================================================        
   // User inserting into bus output
   // BUS_PIPELINE = 2
   always@(*)
     begin
        init_bus_output();

        // Note: Non inserted signals will automatically be connected by a macro.
        //       They will be delay by the value define by BUS_PIPELINE.
        
        insert_ch_a_all(data_a_out);
        if (SPD_ANALOG_CHANNELS > 1)
          insert_ch_b_all(data_b_out);
        if (SPD_ANALOG_CHANNELS > 2)
          insert_ch_c_all(data_c_out);
        if (SPD_ANALOG_CHANNELS > 3)
          insert_ch_d_all(data_d_out);
          
        insert_data_valid_a(data_valid_a_out);
        if (SPD_ANALOG_CHANNELS > 1)
          insert_data_valid_b(data_valid_b_out);
        if (SPD_ANALOG_CHANNELS > 2)
          insert_data_valid_c(data_valid_c_out);
        if (SPD_ANALOG_CHANNELS > 3)
          insert_data_valid_d(data_valid_d_out);

        finish_bus_output();
     end

 //===========================================DATA INSERTION END===================================================================      
     
   // GPIO
   assign gpio_in_o   = gpio_in_i;
   assign gpio_out_o  = gpio_out_i;
   assign gpio_dir_o  = gpio_dir_i;

   assign gpio_ctrl_in_o = gpio_ctrl_in_i;
   assign gpio_ctrl_out_o = gpio_ctrl_out_i;
   assign gpio_ctrl_dir_o = gpio_ctrl_dir_i;

   assign gpio_trig_in_o = gpio_trig_in_i;
   assign gpio_trig_out_o = gpio_trig_out_i;
   assign gpio_trig_dir_o = gpio_trig_dir_i;
 
   assign gpio_sync_in_o = gpio_sync_in_i;
   assign gpio_sync_out_o = gpio_sync_out_i;
   assign gpio_sync_dir_o = gpio_sync_dir_i;


   //Dram outputs must be set to zero if unused
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
