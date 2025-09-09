// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.2 (lin64) Build 1266856 Fri Jun 26 16:35:25 MDT 2015
// Date        : Mon Aug  3 21:53:46 2020
// Host        : spd-vilma running 64-bit Ubuntu 16.04 LTS
// Command     : write_verilog -force -mode synth_stub devkit/source/data_clock_generator_stub.v
// Design      : data_clock_generator
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module data_clock_generator(rst_i, glblclk_p_i, glblclk_n_i, clk_data_o, clk_data_div2_o, clk_iserdes_io_o, clk_iserdes_div_o, clk_idelay_o, locked_o)
/* synthesis syn_black_box black_box_pad_pin="rst_i,glblclk_p_i,glblclk_n_i,clk_data_o,clk_data_div2_o,clk_iserdes_io_o,clk_iserdes_div_o,clk_idelay_o,locked_o" */;
  input rst_i;
  input glblclk_p_i;
  input glblclk_n_i;
  output clk_data_o;
  output clk_data_div2_o;
  output clk_iserdes_io_o;
  output clk_iserdes_div_o;
  output clk_idelay_o;
  output locked_o;
endmodule
