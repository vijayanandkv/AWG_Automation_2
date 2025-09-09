// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.2 (lin64) Build 1266856 Fri Jun 26 16:35:25 MDT 2015
// Date        : Mon Aug  3 22:08:10 2020
// Host        : spd-vilma running 64-bit Ubuntu 16.04 LTS
// Command     : write_verilog -force -mode synth_stub devkit/source/pcie_axis_trn_stub.v
// Design      : pcie_axis_trn
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module pcie_axis_trn#
 (parameter DMA_CHANNELS = 1, parameter C_DATA_WIDTH = 64)
(user_clk, user_reset, user_lnk_up, s_axis_tx_tready, s_axis_tx_tdata, s_axis_tx_tkeep, s_axis_tx_tuser, s_axis_tx_tlast, s_axis_tx_tvalid, m_axis_rx_tdata, m_axis_rx_tkeep, m_axis_rx_tlast, m_axis_rx_tvalid, m_axis_rx_tready, m_axis_rx_tuser, cfg_to_turnoff, cfg_bus_number, cfg_device_number, cfg_function_number, tx_cfg_gnt, cfg_pm_halt_aspm_l0s, cfg_pm_halt_aspm_l1, cfg_pm_force_state_en, cfg_pm_force_state, rx_np_ok, rx_np_req, cfg_turnoff_ok, cfg_trn_pending, cfg_pm_wake, cfg_dsn, fc_sel, cfg_err_cor, cfg_err_ur, cfg_err_ecrc, cfg_err_cpl_timeout, cfg_err_cpl_unexpect, cfg_err_cpl_abort, cfg_err_atomic_egress_blocked, cfg_err_internal_cor, cfg_err_malformed, cfg_err_mc_blocked, cfg_err_poisoned, cfg_err_norecovery, cfg_err_acs, cfg_err_internal_uncor, cfg_err_posted, cfg_err_locked, cfg_err_tlp_cpl_header, cfg_err_aer_headerlog, cfg_aer_interrupt_msgnum, pl_directed_link_change, pl_directed_link_width, pl_directed_link_speed, pl_directed_link_auton, pl_upstream_prefer_deemph, cfg_mgmt_di, cfg_mgmt_byte_en, cfg_mgmt_dwaddr, cfg_mgmt_wr_en, cfg_mgmt_rd_en, cfg_mgmt_wr_readonly, cfg_interrupt, cfg_interrupt_assert, cfg_interrupt_di, cfg_interrupt_stat, cfg_pciecap_interrupt_msgnum, cfg_interrupt_msienable, cfg_mgmt_do, cfg_mgmt_rd_wr_done, cfg_interrupt_rdy, cfg_command, cfg_dcommand, cfg_lstatus, cfg_lcommand, usr_dma_clk_i, usr_dma_data_i, usr_dma_wr_i, usr_dma_rst_i, usr_dma_afull_o, usr_dma_empty_o, usr_dma_rd_o, usr_rx_data_o, usr_rx_addr_o, usr_rx_wr_o, usr_reg_vect_o, usr_dry_o, usr_ack_i, usr_reg_vect_i, usr_fifo_reset_o, usr_fifo_in_avail_i, usr_fifo_in_data_o, usr_fifo_in_write_o, usr_fifo_out_avail_i, usr_fifo_out_data_i, usr_fifo_out_read_o)
/* synthesis syn_black_box black_box_pad_pin="user_clk,user_reset,user_lnk_up,s_axis_tx_tready,s_axis_tx_tdata[127:0],s_axis_tx_tkeep[15:0],s_axis_tx_tuser[3:0],s_axis_tx_tlast,s_axis_tx_tvalid,m_axis_rx_tdata[127:0],m_axis_rx_tkeep[15:0],m_axis_rx_tlast,m_axis_rx_tvalid,m_axis_rx_tready,m_axis_rx_tuser[21:0],cfg_to_turnoff,cfg_bus_number[7:0],cfg_device_number[4:0],cfg_function_number[2:0],tx_cfg_gnt,cfg_pm_halt_aspm_l0s,cfg_pm_halt_aspm_l1,cfg_pm_force_state_en,cfg_pm_force_state[1:0],rx_np_ok,rx_np_req,cfg_turnoff_ok,cfg_trn_pending,cfg_pm_wake,cfg_dsn[63:0],fc_sel[2:0],cfg_err_cor,cfg_err_ur,cfg_err_ecrc,cfg_err_cpl_timeout,cfg_err_cpl_unexpect,cfg_err_cpl_abort,cfg_err_atomic_egress_blocked,cfg_err_internal_cor,cfg_err_malformed,cfg_err_mc_blocked,cfg_err_poisoned,cfg_err_norecovery,cfg_err_acs,cfg_err_internal_uncor,cfg_err_posted,cfg_err_locked,cfg_err_tlp_cpl_header[47:0],cfg_err_aer_headerlog[127:0],cfg_aer_interrupt_msgnum[4:0],pl_directed_link_change[1:0],pl_directed_link_width[1:0],pl_directed_link_speed,pl_directed_link_auton,pl_upstream_prefer_deemph,cfg_mgmt_di[31:0],cfg_mgmt_byte_en[3:0],cfg_mgmt_dwaddr[9:0],cfg_mgmt_wr_en,cfg_mgmt_rd_en,cfg_mgmt_wr_readonly,cfg_interrupt,cfg_interrupt_assert,cfg_interrupt_di[7:0],cfg_interrupt_stat,cfg_pciecap_interrupt_msgnum[4:0],cfg_interrupt_msienable,cfg_mgmt_do[31:0],cfg_mgmt_rd_wr_done,cfg_interrupt_rdy,cfg_command[15:0],cfg_dcommand[15:0],cfg_lstatus[15:0],cfg_lcommand[15:0],usr_dma_clk_i[0:0],usr_dma_data_i[127:0],usr_dma_wr_i[0:0],usr_dma_rst_i[0:0],usr_dma_afull_o[0:0],usr_dma_empty_o[0:0],usr_dma_rd_o[0:0],usr_rx_data_o[127:0],usr_rx_addr_o[17:0],usr_rx_wr_o,usr_reg_vect_o[127:0],usr_dry_o,usr_ack_i,usr_reg_vect_i[63:0],usr_fifo_reset_o,usr_fifo_in_avail_i[31:0],usr_fifo_in_data_o[31:0],usr_fifo_in_write_o,usr_fifo_out_avail_i[31:0],usr_fifo_out_data_i[31:0],usr_fifo_out_read_o" */;
  input user_clk;
  input user_reset;
  input user_lnk_up;
  input s_axis_tx_tready;
  output [127:0]s_axis_tx_tdata;
  output [15:0]s_axis_tx_tkeep;
  output [3:0]s_axis_tx_tuser;
  output s_axis_tx_tlast;
  output s_axis_tx_tvalid;
  input [127:0]m_axis_rx_tdata;
  input [15:0]m_axis_rx_tkeep;
  input m_axis_rx_tlast;
  input m_axis_rx_tvalid;
  output m_axis_rx_tready;
  input [21:0]m_axis_rx_tuser;
  input cfg_to_turnoff;
  input [7:0]cfg_bus_number;
  input [4:0]cfg_device_number;
  input [2:0]cfg_function_number;
  output tx_cfg_gnt;
  output cfg_pm_halt_aspm_l0s;
  output cfg_pm_halt_aspm_l1;
  output cfg_pm_force_state_en;
  output [1:0]cfg_pm_force_state;
  output rx_np_ok;
  output rx_np_req;
  output cfg_turnoff_ok;
  output cfg_trn_pending;
  output cfg_pm_wake;
  output [63:0]cfg_dsn;
  output [2:0]fc_sel;
  output cfg_err_cor;
  output cfg_err_ur;
  output cfg_err_ecrc;
  output cfg_err_cpl_timeout;
  output cfg_err_cpl_unexpect;
  output cfg_err_cpl_abort;
  output cfg_err_atomic_egress_blocked;
  output cfg_err_internal_cor;
  output cfg_err_malformed;
  output cfg_err_mc_blocked;
  output cfg_err_poisoned;
  output cfg_err_norecovery;
  output cfg_err_acs;
  output cfg_err_internal_uncor;
  output cfg_err_posted;
  output cfg_err_locked;
  output [47:0]cfg_err_tlp_cpl_header;
  output [127:0]cfg_err_aer_headerlog;
  output [4:0]cfg_aer_interrupt_msgnum;
  output [1:0]pl_directed_link_change;
  output [1:0]pl_directed_link_width;
  output pl_directed_link_speed;
  output pl_directed_link_auton;
  output pl_upstream_prefer_deemph;
  output [31:0]cfg_mgmt_di;
  output [3:0]cfg_mgmt_byte_en;
  output [9:0]cfg_mgmt_dwaddr;
  output cfg_mgmt_wr_en;
  output cfg_mgmt_rd_en;
  output cfg_mgmt_wr_readonly;
  output cfg_interrupt;
  output cfg_interrupt_assert;
  output [7:0]cfg_interrupt_di;
  output cfg_interrupt_stat;
  output [4:0]cfg_pciecap_interrupt_msgnum;
  input cfg_interrupt_msienable;
  input [31:0]cfg_mgmt_do;
  input cfg_mgmt_rd_wr_done;
  input cfg_interrupt_rdy;
  input [15:0]cfg_command;
  input [15:0]cfg_dcommand;
  input [15:0]cfg_lstatus;
  input [15:0]cfg_lcommand;
  input [0:0]usr_dma_clk_i;
  input [127:0]usr_dma_data_i;
  input [0:0]usr_dma_wr_i;
  input [0:0]usr_dma_rst_i;
  output [0:0]usr_dma_afull_o;
  output [0:0]usr_dma_empty_o;
  output [0:0]usr_dma_rd_o;
  output [127:0]usr_rx_data_o;
  output [17:0]usr_rx_addr_o;
  output usr_rx_wr_o;
  output [127:0]usr_reg_vect_o;
  output usr_dry_o;
  input usr_ack_i;
  input [63:0]usr_reg_vect_i;
  output usr_fifo_reset_o;
  input [31:0]usr_fifo_in_avail_i;
  output [31:0]usr_fifo_in_data_o;
  output usr_fifo_in_write_o;
  input [31:0]usr_fifo_out_avail_i;
  input [31:0]usr_fifo_out_data_i;
  output usr_fifo_out_read_o;
endmodule

