# -*- coding: us-ascii-dos -*-
#
# Copyright Signal Processing Devices Sweden AB. All rights reserved.
# See document "08-0175 EULA" for specific license terms regarding this file.
#
# Description   : ADQ14 Ethernet specific constraints
# Documentation :
#

# JESD204 clocks
create_clock -period 4.0 [get_ports fpga_gtxref_ac_p]
create_clock -period 4.0 [get_ports fpga_glblclk_p]

# XADC to DRAM
set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clock_generator] -group [get_clocks clk_pll_i]
set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clock_generator] -group [get_clocks clk_pll_i_1]

# These were necessary to avoid inter-clock errors
set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clock_generator] -group [get_clocks pll_idelay_unbuf]

# These were necessary to avoid inter-clock errors
set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clock_generator] -group [get_clocks clk_out3_system_clock_generator]
set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clock_generator] -group [get_clocks clk_ref_mmcm_400]
set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clock_generator] -group [get_clocks mmcm_ps_clk_bufg_in]
set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clock_generator] -group [get_clocks mmcm_ps_clk_bufg_in_1]


# DDR3
set_clock_groups -asynchronous -group [get_clocks c0_ddr3_sys_clk_p] -group [get_clocks clk_out1_system_clock_generator]
set_clock_groups -asynchronous -group [get_clocks c0_ddr3_sys_clk_p] -group [get_clocks clk_out2_system_clock_generator]

# JESD204 to/from MCU
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks fbclk_unbuf] -group [get_clocks clk_out1_system_clock_generator]
set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clock_generator] -group [get_clocks -include_generated_clocks fbclk_unbuf]

# JESD204 div2 clock to/from MCU
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks clkdiv2_unbuf] -group [get_clocks clk_out1_system_clock_generator]
set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clock_generator] -group [get_clocks -include_generated_clocks clkdiv2_unbuf]

# Packet Gen data clock to/from memory clock
set_clock_groups -asynchronous -group [get_clocks clk_out2_system_clock_generator] -group [get_clocks -include_generated_clocks fbclk_unbuf]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks fbclk_unbuf] -group [get_clocks clk_out2_system_clock_generator]

# DataTrig from MCU
set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clock_generator] -group [get_clocks -include_generated_clocks clk_iserdes_div]

# DRAM from Reset (TODO, resync to DRAM clocks)
set_clock_groups -asynchronous -group [get_clocks clk_pll_i]                       -group [get_clocks clk_pll_i_1]
set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clock_generator] -group [get_clocks clk_out2_system_clock_generator]
set_clock_groups -asynchronous -group [get_clocks clk_out2_system_clock_generator] -group [get_clocks clk_pll_i]
set_clock_groups -asynchronous -group [get_clocks clk_out2_system_clock_generator] -group [get_clocks clk_pll_i_1]
set_clock_groups -asynchronous -group [get_clocks clk_out2_system_clock_generator] -group [get_clocks mmcm_ps_clk_bufg_in]
set_clock_groups -asynchronous -group [get_clocks clk_out2_system_clock_generator] -group [get_clocks mmcm_ps_clk_bufg_in_1]
set_clock_groups -asynchronous -group [get_clocks clk_out2_system_clock_generator] -group [get_clocks clk_out3_system_clock_generator]
set_clock_groups -asynchronous -group [get_clocks clk_out2_system_clock_generator] -group [get_clocks clk_ref_mmcm_400]

# Set DRAM/datapath clocks as asynchronous
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks fbclk_unbuf] -group [get_clocks clk_pll_i]
set_clock_groups -asynchronous -group [get_clocks clk_pll_i_1] -group [get_clocks -include_generated_clocks fbclk_unbuf]

set_clock_groups -asynchronous -group [get_clocks clk_out1_System_clk_uart_xin_0_0] -group [get_clocks clk_out1_system_clock_generator]

# External trigger - for testing only
#set_input_delay -clock [get_clocks fpga_glblclk_p] 0.0 [get_ports exttrig* -filter {direction==in}]
#set_input_delay -clock [get_clocks fpga_glblclk_p] 0.0 -clock_fall -add_delay [get_ports exttrig* -filter {direction==in}]

# SYSREF (TODO, spec input delay according to PLL delay)
set_property IOB true [all_fanout -only_cells -endpoints_only -flat [get_ports fpga_sysref_p]]
#set_input_delay -clock [get_clocks fpga_glblclk_p] -min -0.2 [get_ports fpga_sysref_p]
#set_input_delay -clock [get_clocks fpga_glblclk_p] -max 0.2 [get_ports fpga_sysref_p]

# SPI
set_property IOB false [get_cells system_inst/System_i/processor/axi_spi_0/U0/IO1_I_REG]
# input timing
set_max_delay -from [get_ports param_so] -to [all_fanout -only_cells -endpoints_only -flat [get_ports param_so]] -datapath_only 10.0
set_max_delay -from [get_ports spi_sdio] -to [all_fanout -only_cells -endpoints_only -flat [get_ports spi_sdio]] -datapath_only 10.0
# output timing
set_max_delay -from [all_fanin -startpoints_only -only_cells -flat [get_ports param_si]] -to [get_ports param_si] -datapath_only 10.0
set_max_delay -from [all_fanin -startpoints_only -only_cells -flat [get_ports spi_sdio]] -to [get_ports spi_sdio] -datapath_only 10.0
set_max_delay -from [all_fanin -startpoints_only -only_cells -flat [get_ports *_cs_n]] -to [get_ports *_cs_n] -datapath_only 10.0

# I2C I/O timing
# input timing
set_max_delay -from [get_ports scl] -to [all_fanout -only_cells -endpoints_only -flat [get_ports scl]] -datapath_only 10.0
set_max_delay -from [get_ports sda] -to [all_fanout -only_cells -endpoints_only -flat [get_ports sda]] -datapath_only 10.0
# output timing
set_max_delay -from [all_fanin -startpoints_only -only_cells -flat [get_ports scl]] -to [get_ports scl] -datapath_only 10.0
set_max_delay -from [all_fanin -startpoints_only -only_cells -flat [get_ports sda]] -to [get_ports sda] -datapath_only 10.0


# Configuration mode parameters
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]
set_property BITSTREAM.CONFIG.PERSIST NO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DIV-1 [current_design]
set_property CONFIG_VOLTAGE 1.5 [current_design]
set_property CFGBVS GND [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.STARTUP.DONEPIPE NO [current_design]



