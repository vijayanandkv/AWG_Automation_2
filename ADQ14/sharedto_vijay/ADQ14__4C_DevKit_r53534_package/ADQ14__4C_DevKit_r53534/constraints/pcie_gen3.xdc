set_property LOC IBUFDS_GTE2_X0Y1 [get_cells refclk_ibuf]
create_clock -name sys_clk  -period 10 [get_ports mgtrefclk_p]
create_clock -name txoutclk -period 10 [get_pins * -hier -filter {NAME  =~ */txoutclk_i.txoutclk_i/O}]

#set_false_path -to   [get_pins system_clock_reset_inst/system_clock_reset_input_inst/D]

current_instance system_inst/System_i/dma_pcie_gen3/SPD_PCIE_GEN3_0/inst/pcie_gen3_inst/phy/pipe_wrapper_i
                 
# GTX
set_property LOC GTXE2_CHANNEL_X0Y0 [get_cells {pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property LOC GTXE2_CHANNEL_X0Y1 [get_cells {pipe_lane[1].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property LOC GTXE2_CHANNEL_X0Y2 [get_cells {pipe_lane[2].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property LOC GTXE2_CHANNEL_X0Y3 [get_cells {pipe_lane[3].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property LOC GTXE2_CHANNEL_X0Y4 [get_cells {pipe_lane[4].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property LOC GTXE2_CHANNEL_X0Y5 [get_cells {pipe_lane[5].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property LOC GTXE2_CHANNEL_X0Y6 [get_cells {pipe_lane[6].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property LOC GTXE2_CHANNEL_X0Y7 [get_cells {pipe_lane[7].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]

current_instance

###############################################################################
# Timing Constraints
###############################################################################


# Exclude paths between unrelated clock domains
set_clock_groups -physically_exclusive -group clk_125mhz -group clk_250mhz
set_clock_groups -asynchronous         -group userclk1   -group clk_125mhz
set_clock_groups -asynchronous         -group userclk1   -group clk_250mhz

# Exclude paths from asynchronous reset
set_false_path -through [get_ports pxie_perst]
set_false_path -through [get_cells system_inst/System_i/dma_pcie_gen3/SPD_PCIE_GEN3_0/inst/pcie_gen3_inst/pl_rst_reg]
set_false_path -through [get_cells system_inst/System_i/dma_pcie_gen3/SPD_PCIE_GEN3_0/inst/pcie_gen3_inst/areset_reg]
set_false_path -through [get_cells system_inst/System_i/dma_pcie_gen3/SPD_PCIE_GEN3_0/inst/pcie_gen3_inst/phy/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_sel_reg*]

#Exclude BUFGCTL select pins
set_false_path -to [get_pins system_inst/System_i/dma_pcie_gen3/SPD_PCIE_GEN3_0/inst/pcie_gen3_inst/phy/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S*]

#CDC on idelay reset
set_false_path -to  [get_pins system_clock_reset_inst/sync_rst_clk_idelay_inst/cdc_sync_reg[1][0]/D]

### Clocks
#
# CPU:  clk_out1_system_clock_generator
# MEM:  clk_out2_system_clock_generator
# IDELAY: clk_out3_system_clock_generator
# DATA: fbclk_unbuf
# DATA/2: clkdiv2_unbuf
# PCIE app: userclk1
# Iserdes: clk_iserdes_div
# DATA?: pll_idelay_unbuf


set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clock_generator] -group [get_clocks clk_out2_system_clock_generator]
set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clock_generator] -group [get_clocks clk_iserdes_div]
set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clock_generator] -group [get_clocks pll_idelay_unbuf]

set_clock_groups -asynchronous -group [get_clocks  fbclk_unbuf] -group [get_clocks clk_out1_system_clock_generator]
set_clock_groups -asynchronous -group [get_clocks  fbclk_unbuf] -group [get_clocks clk_out2_system_clock_generator]
set_clock_groups -asynchronous -group [get_clocks  clkdiv2_unbuf] -group [get_clocks clk_out1_system_clock_generator]
set_clock_groups -asynchronous -group [get_clocks  clkdiv2_unbuf] -group [get_clocks clk_out2_system_clock_generator]


set_clock_groups -asynchronous -group [get_clocks  userclk1] -group [get_clocks clk_out1_system_clock_generator]
set_clock_groups -asynchronous -group [get_clocks  userclk1] -group [get_clocks clk_out2_system_clock_generator]
#? set_clock_groups -asynchronous -group [get_clocks  userclk1] -group [get_clocks clk_out3_system_clock_generator]



###############################################################################
#Floor plan

#set_property MAX_FANOUT  40 [get_nets system_inst/System_i/dma_pcie_gen3/SPD_PCIE_GEN3_0/inst/pcie_gen3_inst/xr3axi_ipcore_inst/xr3axi_top/pcie_core_inst/phymac_inst/*]
#set_property MAX_FANOUT  40 [get_nets system_inst/System_i/dma_pcie_gen3/SPD_PCIE_GEN3_0/inst/pcie_gen3_inst/xr3axi_ipcore_inst/xr3axi_top/pcie_core_inst/phymac_inst/deskew_inst/*]
#set_property MAX_FANOUT 470 [get_nets system_inst/System_i/dma_pcie_gen3/SPD_PCIE_GEN3_0/inst/pcie_gen3_inst/xr3axi_ipcore_inst/xr3axi_top/pcie_core_inst/phymac_inst/txalign_inst/txblk_cnt_reg*]
#set_property MAX_FANOUT 100 [get_nets  system_inst/System_i/dma_pcie_gen3/SPD_PCIE_GEN3_0/inst/pcie_gen3_inst/xr3axi_ipcore_inst/xr3axi_top/pcie_core_inst/phymac_inst/ltssm_inst/lksts_link_width_reg*]

#set_property BLOCK_SYNTH.RETIMING 1 [get_cells system_inst/System_i/dma_pcie_gen3/SPD_PCIE_GEN3_0/inst/pcie_gen3_inst/xr3axi_ipcore_inst/xr3axi_top/pcie_core_inst/phymac_inst]

#create_pblock pblock_ram_block_reg
#resize_pblock pblock_ram_block_reg -add {RAMB36_X2Y11:RAMB36_X2Y14}
#add_cells_to_pblock pblock_ram_block_reg [get_cells [list system_inst/System_i/dma_pcie_gen3/SPD_PCIE_GEN3_0/inst/pcie_gen3_inst/scram_a2p_inst/ram_block_reg_?]]


# Bitgen
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]
#set_property BITSTREAM.CONFIG.PERSIST YES [current_design]
#set_property BITSTREAM.CONFIG.TANDEM_DEASSERT_PERSIST YES [current_design]
#set_property BITSTREAM.GENERAL.COMPRESS FALSE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DIV-1 [current_design]
set_property CONFIG_VOLTAGE 1.5 [current_design]
set_property CFGBVS GND [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
#set_property BITSTREAM.STARTUP.DONEPIPE NO [current_design]
