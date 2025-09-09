/* -*- coding: us-ascii-dos -*-
 *
 * Copyright Signal Processing Devices Sweden AB. All rights reserved.
 * See document "08-0175 EULA" for specific license terms regarding this file.
 *
 * Description   : Configuration parameters
 * Documentation :
 *
 */

`timescale 1ns / 1ps

//`define dram_test
`define dram_debug

`define EN_SYSTEM

`define EN_JESD

// DDR3
`define DRAM_BANK_WIDTH             3  // # of memory Bank Address bits.
`define DRAM_DQ_WIDTH              64  // # of Data (DQ) bits.
`define DRAM_DQS_WIDTH              8  // # of DQS/DQS# bits.
`define DRAM_ADDR_WIDTH            28  // # of Address bits.
`define DRAM_ADDR_MASK              3  // # of Address bits used for burst length (8)
`define DRAM_DATA_WIDTH           512  // # of Data bits.
`define DRAM_ROW_WIDTH             14  // # of memory Row Address bits.

//MEMCOMM
`define HOST_READ_WIDTH                128
`define MULTIPORT_READ_AFULL_DEPTH     128 // User logic must accept this much data after afull asserts
`define MULTIPORT_READ_MAX_BURST       128 // 1KW / 8-burst = 128 commands
`define MULTIPORT_HOST_READ_AFULL_DEPTH 128

//PCIE
`define EN_PCIE
//`define PCIE_NO_LANES               8 Note: Now defined in device_param_top.vh instead, since MTCA has 4 lanes only
`define DMA_CHANNELS 1

`ifdef PCIE_128
 `define PCI_EXP_TRN_DATA_WIDTH          128
 `define PCI_EXP_TRN_REM_WIDTH           2
`else
 `define PCI_EXP_TRN_DATA_WIDTH          64
 `define PCI_EXP_TRN_REM_WIDTH           1
`endif

`define PCI_EXP_TRN_ADDR_WIDTH          18
`define PCI_EXP_TRN_BUF_AV_WIDTH        7

`define PCI_EXP_TRN_BAR_HIT_WIDTH       7
`define PCI_EXP_TRN_FC_HDR_WIDTH        8
`define PCI_EXP_TRN_FC_DATA_WIDTH       12

//Leveltrig
`define LEVELTRIG_POSEDGE1_POS        4
`define LEVELTRIG_POSEDGE2_POS        24
`define LEVELTRIG_POSEDGE3_POS        25
`define LEVELTRIG_POSEDGE4_POS        26

`define LEVELTRIG_CHA_EN_POS          7
`define LEVELTRIG_CHB_EN_POS          8
`define LEVELTRIG_CHC_EN_POS          9
`define LEVELTRIG_CHD_EN_POS          10

`define LEVELTRIG_INTERLEAVED2_POS    5
`define LEVELTRIG_INTERLEAVED4_POS    11
