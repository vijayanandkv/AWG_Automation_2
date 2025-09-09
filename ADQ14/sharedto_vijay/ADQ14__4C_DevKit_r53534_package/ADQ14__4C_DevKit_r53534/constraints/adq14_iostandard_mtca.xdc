# -*- coding: us-ascii-dos -*-
# 
# Copyright Signal Processing Devices Sweden AB. All rights reserved.
# See document "08-0175 EULA" for specific license terms regarding this file.
# 
# Description   : ADQ14 I/O constraints file, MTCA specific
# Documentation :
# 
# 

set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_rx_i[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_rx_i[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_rx_i[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_rx_i[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_tx_i[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_tx_i[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_tx_i[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_tx_i[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_rx_o[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_rx_o[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_rx_o[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_rx_o[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_tx_o[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_tx_o[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_tx_o[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_tx_o[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports pp_10m_en]
set_property IOSTANDARD LVCMOS33 [get_ports pp_pll_cs_n]

set_property IOSTANDARD LVCMOS33 [get_ports mmc_rst]
set_property IOSTANDARD LVCMOS33 [get_ports mmc_progen_n]
set_property IOSTANDARD LVCMOS33 [get_ports mmc_uart_o]
set_property IOSTANDARD LVCMOS33 [get_ports mmc_uart_i]
set_property IOSTANDARD LVCMOS33 [get_ports mmc_sck]
set_property IOSTANDARD LVCMOS33 [get_ports mmc_sdat]
set_property IOSTANDARD LVCMOS33 [get_ports mmc_sclk]
