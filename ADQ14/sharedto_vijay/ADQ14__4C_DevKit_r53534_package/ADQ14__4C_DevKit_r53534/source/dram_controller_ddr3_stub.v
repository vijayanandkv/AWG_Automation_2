// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.2 (lin64) Build 1266856 Fri Jun 26 16:35:25 MDT 2015
// Date        : Mon Aug  3 22:05:17 2020
// Host        : spd-vilma running 64-bit Ubuntu 16.04 LTS
// Command     : write_verilog -force -mode synth_stub devkit/source/dram_controller_ddr3_stub.v
// Design      : dram_controller_ddr3
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module dram_controller_ddr3(clk_iodelay_i, rst_i, device_temp_i, dbg_reg0_o, dbg_reg1_i, dbg_reg2_o, dbg_reg3_o, dbg_reg4_o, clk1_o, app_wdf_wren1, app_wdf_data1, app_wdf_end1, app_cmd1, app_en1, tg_addr1, app_full1, app_wdf_full1, app_rd_data1, app_rd_data_valid1, error1, phy_init_done1, use_tb1_i, clk2_o, app_wdf_wren2, app_wdf_data2, app_wdf_end2, app_cmd2, app_en2, tg_addr2, app_full2, app_wdf_full2, app_rd_data2, app_rd_data_valid2, error2, phy_init_done2, use_tb2_i, c0_ddr3_dq, c0_ddr3_dqs_n, c0_ddr3_dqs_p, c0_ddr3_addr, c0_ddr3_ba, c0_ddr3_ras_n, c0_ddr3_cas_n, c0_ddr3_we_n, c0_ddr3_reset_n, c0_ddr3_ck_p, c0_ddr3_ck_n, c0_ddr3_cke, c0_ddr3_odt, c0_sys_clk_i, c1_ddr3_dq, c1_ddr3_dqs_n, c1_ddr3_dqs_p, c1_ddr3_addr, c1_ddr3_ba, c1_ddr3_ras_n, c1_ddr3_cas_n, c1_ddr3_we_n, c1_ddr3_reset_n, c1_ddr3_ck_p, c1_ddr3_ck_n, c1_ddr3_cke, c1_ddr3_odt, c1_sys_clk_i)
/* synthesis syn_black_box black_box_pad_pin="clk_iodelay_i,rst_i,device_temp_i[11:0],dbg_reg0_o[31:0],dbg_reg1_i[31:0],dbg_reg2_o[31:0],dbg_reg3_o[31:0],dbg_reg4_o[31:0],clk1_o,app_wdf_wren1,app_wdf_data1[511:0],app_wdf_end1,app_cmd1[2:0],app_en1,tg_addr1[27:0],app_full1,app_wdf_full1,app_rd_data1[511:0],app_rd_data_valid1,error1,phy_init_done1,use_tb1_i,clk2_o,app_wdf_wren2,app_wdf_data2[511:0],app_wdf_end2,app_cmd2[2:0],app_en2,tg_addr2[27:0],app_full2,app_wdf_full2,app_rd_data2[511:0],app_rd_data_valid2,error2,phy_init_done2,use_tb2_i,c0_ddr3_dq[63:0],c0_ddr3_dqs_n[7:0],c0_ddr3_dqs_p[7:0],c0_ddr3_addr[13:0],c0_ddr3_ba[2:0],c0_ddr3_ras_n,c0_ddr3_cas_n,c0_ddr3_we_n,c0_ddr3_reset_n,c0_ddr3_ck_p,c0_ddr3_ck_n,c0_ddr3_cke,c0_ddr3_odt,c0_sys_clk_i,c1_ddr3_dq[63:0],c1_ddr3_dqs_n[7:0],c1_ddr3_dqs_p[7:0],c1_ddr3_addr[13:0],c1_ddr3_ba[2:0],c1_ddr3_ras_n,c1_ddr3_cas_n,c1_ddr3_we_n,c1_ddr3_reset_n,c1_ddr3_ck_p,c1_ddr3_ck_n,c1_ddr3_cke,c1_ddr3_odt,c1_sys_clk_i" */;
  input clk_iodelay_i;
  input rst_i;
  input [11:0]device_temp_i;
  output [31:0]dbg_reg0_o;
  input [31:0]dbg_reg1_i;
  output [31:0]dbg_reg2_o;
  output [31:0]dbg_reg3_o;
  output [31:0]dbg_reg4_o;
  output clk1_o;
  input app_wdf_wren1;
  input [511:0]app_wdf_data1;
  input app_wdf_end1;
  input [2:0]app_cmd1;
  input app_en1;
  input [27:0]tg_addr1;
  output app_full1;
  output app_wdf_full1;
  output [511:0]app_rd_data1;
  output app_rd_data_valid1;
  output error1;
  output phy_init_done1;
  input use_tb1_i;
  output clk2_o;
  input app_wdf_wren2;
  input [511:0]app_wdf_data2;
  input app_wdf_end2;
  input [2:0]app_cmd2;
  input app_en2;
  input [27:0]tg_addr2;
  output app_full2;
  output app_wdf_full2;
  output [511:0]app_rd_data2;
  output app_rd_data_valid2;
  output error2;
  output phy_init_done2;
  input use_tb2_i;
  inout [63:0]c0_ddr3_dq;
  inout [7:0]c0_ddr3_dqs_n;
  inout [7:0]c0_ddr3_dqs_p;
  output [13:0]c0_ddr3_addr;
  output [2:0]c0_ddr3_ba;
  output c0_ddr3_ras_n;
  output c0_ddr3_cas_n;
  output c0_ddr3_we_n;
  output c0_ddr3_reset_n;
  output c0_ddr3_ck_p;
  output c0_ddr3_ck_n;
  output c0_ddr3_cke;
  output c0_ddr3_odt;
  input c0_sys_clk_i;
  inout [63:0]c1_ddr3_dq;
  inout [7:0]c1_ddr3_dqs_n;
  inout [7:0]c1_ddr3_dqs_p;
  output [13:0]c1_ddr3_addr;
  output [2:0]c1_ddr3_ba;
  output c1_ddr3_ras_n;
  output c1_ddr3_cas_n;
  output c1_ddr3_we_n;
  output c1_ddr3_reset_n;
  output c1_ddr3_ck_p;
  output c1_ddr3_ck_n;
  output c1_ddr3_cke;
  output c1_ddr3_odt;
  input c1_sys_clk_i;
endmodule
