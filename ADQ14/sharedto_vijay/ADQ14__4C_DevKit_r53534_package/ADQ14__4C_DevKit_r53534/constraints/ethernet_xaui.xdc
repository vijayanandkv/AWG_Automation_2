set_property LOC GTXE2_CHANNEL_X0Y4 [get_cells -hierarchical -filter {NAME =~ */gt_wrapper_i/gt0_ethernet_xaui_gt_wrapper_i/gtxe2_i}]
set_property LOC GTXE2_CHANNEL_X0Y5 [get_cells -hierarchical -filter {NAME =~ */gt_wrapper_i/gt1_ethernet_xaui_gt_wrapper_i/gtxe2_i}]
set_property LOC GTXE2_CHANNEL_X0Y6 [get_cells -hierarchical -filter {NAME =~ */gt_wrapper_i/gt2_ethernet_xaui_gt_wrapper_i/gtxe2_i}]
set_property LOC GTXE2_CHANNEL_X0Y7 [get_cells -hierarchical -filter {NAME =~ */gt_wrapper_i/gt3_ethernet_xaui_gt_wrapper_i/gtxe2_i}]

#set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clock_generator] -group [get_clocks xilinx_10g_eth_mac_xaui_top_inst/ethernet_xaui_inst/inst/xaui_block_i/gt_wrapper_i/gt0_ethernet_xaui_gt_wrapper_i/gtxe2_i/TXOUTCLK]
#set_clock_groups -asynchronous -group [get_clocks xilinx_10g_eth_mac_xaui_top_inst/ethernet_xaui_inst/inst/xaui_block_i/gt_wrapper_i/gt0_ethernet_xaui_gt_wrapper_i/gtxe2_i/TXOUTCLK] -group [get_clocks clk_out1_system_clock_generator]

#set_clock_groups -asynchronous -group [get_clocks clk_out2_system_clock_generator] -group [get_clocks xilinx_10g_eth_mac_xaui_top_inst/ethernet_xaui_inst/inst/xaui_block_i/gt_wrapper_i/gt0_ethernet_xaui_gt_wrapper_i/gtxe2_i/TXOUTCLK]
#set_clock_groups -asynchronous -group [get_clocks xilinx_10g_eth_mac_xaui_top_inst/ethernet_xaui_inst/inst/xaui_block_i/gt_wrapper_i/gt0_ethernet_xaui_gt_wrapper_i/gtxe2_i/TXOUTCLK] -group [get_clocks clk_out2_system_clock_generator]

#set_clock_groups -asynchronous -group [get_clocks c1_ddr3_sys_clk_p] -group [get_clocks xilinx_10g_eth_mac_xaui_top_inst/ethernet_xaui_inst/inst/xaui_block_i/gt_wrapper_i/gt0_ethernet_xaui_gt_wrapper_i/gtxe2_i/TXOUTCLK]

set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clock_generator] -group [get_clocks ethernet_xaui_inst/inst/xaui_block_i/gt_wrapper_i/gt0_ethernet_xaui_gt_wrapper_i/gtxe2_i/TXOUTCLK]
set_clock_groups -asynchronous -group [get_clocks ethernet_xaui_inst/inst/xaui_block_i/gt_wrapper_i/gt0_ethernet_xaui_gt_wrapper_i/gtxe2_i/TXOUTCLK] -group [get_clocks clk_out1_system_clock_generator]

set_clock_groups -asynchronous -group [get_clocks clk_out2_system_clock_generator] -group [get_clocks ethernet_xaui_inst/inst/xaui_block_i/gt_wrapper_i/gt0_ethernet_xaui_gt_wrapper_i/gtxe2_i/TXOUTCLK]
set_clock_groups -asynchronous -group [get_clocks ethernet_xaui_inst/inst/xaui_block_i/gt_wrapper_i/gt0_ethernet_xaui_gt_wrapper_i/gtxe2_i/TXOUTCLK] -group [get_clocks clk_out2_system_clock_generator]

set_clock_groups -asynchronous -group [get_clocks c1_ddr3_sys_clk_p] -group [get_clocks ethernet_xaui_inst/inst/xaui_block_i/gt_wrapper_i/gt0_ethernet_xaui_gt_wrapper_i/gtxe2_i/TXOUTCLK]


