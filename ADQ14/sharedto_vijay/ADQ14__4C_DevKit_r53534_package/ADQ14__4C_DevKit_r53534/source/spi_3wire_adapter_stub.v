// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.2 (lin64) Build 1266856 Fri Jun 26 16:35:25 MDT 2015
// Date        : Mon Aug  3 21:54:10 2020
// Host        : spd-vilma running 64-bit Ubuntu 16.04 LTS
// Command     : write_verilog -force -mode synth_stub devkit/source/spi_3wire_adapter_stub.v
// Design      : spi_3wire_adapter
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module spi_3wire_adapter(mcu_clk_i, rw_flags_i, load_flags_i, spi_sclk_i, sclk_pol_i, spi_sdio_t_o)
/* synthesis syn_black_box black_box_pad_pin="mcu_clk_i,rw_flags_i[3:0],load_flags_i,spi_sclk_i,sclk_pol_i,spi_sdio_t_o" */;
  input mcu_clk_i;
  input [3:0]rw_flags_i;
  input load_flags_i;
  input spi_sclk_i;
  input sclk_pol_i;
  output spi_sdio_t_o;
endmodule
