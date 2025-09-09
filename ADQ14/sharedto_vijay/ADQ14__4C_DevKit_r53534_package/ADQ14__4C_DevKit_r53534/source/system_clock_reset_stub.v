// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.2 (lin64) Build 1266856 Fri Jun 26 16:35:25 MDT 2015
// Date        : Mon Aug  3 21:55:35 2020
// Host        : spd-vilma running 64-bit Ubuntu 16.04 LTS
// Command     : write_verilog -force -mode synth_stub devkit/source/system_clock_reset_stub.v
// Design      : system_clock_reset
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module system_clock_reset(pxie_ref_clk_i, clk_cpu_o, clk_mem_o, clk_idelay_o, pci_app_rdy_i, system_clock_locked_o, rst_clk_cpu_o, rst_clk_mem_o, rst_clk_idelay_o)
/* synthesis syn_black_box black_box_pad_pin="pxie_ref_clk_i,clk_cpu_o,clk_mem_o,clk_idelay_o,pci_app_rdy_i,system_clock_locked_o,rst_clk_cpu_o,rst_clk_mem_o,rst_clk_idelay_o" */;
  input pxie_ref_clk_i;
  output clk_cpu_o;
  output clk_mem_o;
  output clk_idelay_o;
  input pci_app_rdy_i;
  output system_clock_locked_o;
  output rst_clk_cpu_o;
  output rst_clk_mem_o;
  output rst_clk_idelay_o;
endmodule
