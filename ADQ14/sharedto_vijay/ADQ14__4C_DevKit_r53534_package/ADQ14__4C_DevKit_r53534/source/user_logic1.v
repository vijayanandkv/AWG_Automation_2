
`timescale 1 ns / 1 ps

`default_nettype none

`include "user_logic1_defines.vh"

  module user_logic1 #
    (
     // Users to add parameters here

     // User parameters ends

     // Do not modify the parameters beyond this line
     parameter integer CH_TRIG_DATA_WIDTH   = `UL1_SPD_ANALOG_CHANNELS * `UL1_SPD_DATAWIDTH_BITS * `UL1_SPD_PARALLEL_SAMPLES,
     parameter integer CH_TRIG_VECTOR_WIDTH = `UL1_SPD_ANALOG_CHANNELS * (`UL1_SPD_NUM_CH_TRIG_BITS+`UL1_SPD_NUM_TRIG_ADDBITS),
     parameter integer ADDR_WIDTH = 14
     )
   (

    // Level trigger
    output wire [CH_TRIG_DATA_WIDTH-1:0]   lvl_trig_data,
    input wire [CH_TRIG_VECTOR_WIDTH-1:0]  lvl_trig_vector,

    // License inputs
    input wire [63:0]                      license_bitfield_i,
    input wire                             license_valid_i,

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
    input wire [`UL1_DATA_BUS_WIDTH-1 : 0] s_axis_tdata,
    input wire                             s_axis_tvalid,

    // Ports of AXI-S Master Bus Interface m_axis
    input wire                             m_axis_aclk,
    input wire                             m_axis_aresetn,
    output reg                             m_axis_tvalid,
    output reg [`UL1_DATA_BUS_WIDTH-1 : 0] m_axis_tdata,

    // MTCA-specific signals (non-connected in PXIe/PCIe/USB)
    input wire [3:0]                       mlvds_rx_i,
    input wire [3:0]                       mlvds_tx_i,
    output wire [3:0]                      mlvds_rx_o,
    output wire [3:0]                      mlvds_tx_o,
    input wire [3:0]                       mlvds_rx_o_from_datatrig_i,
    input wire [3:0]                       mlvds_tx_o_from_datatrig_i
    );

   // Users to add localparam here
   localparam BUS_PIPELINE = 1;

   // User localparam ends

   // These includes are needed to insert/extract data to/from the AXI-S buses
`include "device_param.vh"
`include "bus_splitter_rt.vh"


   // User application code
   wire [31:0]                              reg_0x10_in;
   wire [31:0]                              reg_0x11_in;
   wire [31:0]                              reg_0x12_in;
   wire [31:0]                              reg_0x13_in;

   wire [31:0]                              reg_0x10_out;
   wire [31:0]                              reg_0x11_out;
   wire [31:0]                              reg_0x12_out;
   wire [31:0]                              reg_0x13_out;


   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_a;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_b;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_c;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_d;

   reg [CH_TRIG_DATA_WIDTH-1:0]                      lvl_trig_data_r;

   assign reg_0x10_in = reg_0x10_out;
   assign reg_0x11_in = reg_0x11_out;
   assign reg_0x12_in = 32'haabbccdd;
   assign reg_0x13_in = 32'h12345678;

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

   assign lvl_trig_data = lvl_trig_data_r;

   always @ (posedge s_axis_aclk)
     begin
        lvl_trig_data_r <= extract_all_sample(DONT_CARE); // Do not remove this line unless you want to change the behaviour of the level trigger.


        // Extract all parallel samples for each channel
        data_a <= extract_ch_a_all(DONT_CARE);
        if (`UL1_SPD_ANALOG_CHANNELS > 1)
          data_b <= extract_ch_b_all(DONT_CARE);
        if (`UL1_SPD_ANALOG_CHANNELS > 2)
          data_c <= extract_ch_c_all(DONT_CARE);
        if (`UL1_SPD_ANALOG_CHANNELS > 3)
          data_d <= extract_ch_d_all(DONT_CARE);


        // Individual parallel samples are extracted with:
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
     end


   // User inserting into bus output
   always@(*)
     begin
        init_bus_output();

        insert_ch_a_all(data_a);
        if (`UL1_SPD_ANALOG_CHANNELS > 1)
          insert_ch_b_all(data_b);
        if (`UL1_SPD_ANALOG_CHANNELS > 2)
          insert_ch_c_all(data_c);
        if (`UL1_SPD_ANALOG_CHANNELS > 3)
          insert_ch_d_all(data_d);

        //Individual parallel samples are inserted with:
        /*
        insert_ch_a(data_a0, 0);
        insert_ch_a(data_a1, 1);
        insert_ch_a(data_a2, 2);
        insert_ch_a(data_a3, 3);

        insert_ch_b(data_b0, 0);
        insert_ch_b(data_b1, 1);
        insert_ch_b(data_b2, 2);
        insert_ch_b(data_b3, 3);

        insert_ch_c(data_c0, 0);
        insert_ch_c(data_c1, 1);
        insert_ch_c(data_c2, 2);
        insert_ch_c(data_c3, 3);

        insert_ch_d(data_d0, 0);
        insert_ch_d(data_d1, 1);
        insert_ch_d(data_d2, 2);
        insert_ch_d(data_d3, 3);
        */

        finish_bus_output();
     end

     assign mlvds_rx_o = mlvds_rx_o_from_datatrig_i;
     assign mlvds_tx_o = mlvds_tx_o_from_datatrig_i;

   // User logic ends

endmodule

`default_nettype wire
