# -*- coding: us-ascii-dos -*-
# 
# Copyright Signal Processing Devices Sweden AB. All rights reserved.
# See document "08-0175 EULA" for specific license terms regarding this file.
# 
# Description   : ADQ14 pin mapping constraints
# Documentation :
# 
# 

set_property PACKAGE_PIN C21 [get_ports led_rsvd_n]

set_property PACKAGE_PIN A20 [get_ports trig_tcxo_cs_n]

set_property PACKAGE_PIN B19 [get_ports sda]
set_property PACKAGE_PIN C19 [get_ports scl]

set_property PACKAGE_PIN F17 [get_ports pll_cs_n]

set_property PACKAGE_PIN G17 [get_ports dac_ovp_cs_n]

set_property PACKAGE_PIN B20 [get_ports dac_null_ab_cs_n]
set_property PACKAGE_PIN C20 [get_ports dac_null_cd_cs_n]
set_property PACKAGE_PIN A17 [get_ports dac_bias_ab_cs_n]
set_property PACKAGE_PIN A16 [get_ports dac_bias_cd_cs_n]

set_property PACKAGE_PIN B17 [get_ports adc1_cs_n]
set_property PACKAGE_PIN C17 [get_ports adc2_cs_n]

set_property PACKAGE_PIN AJ24 [get_ports pxie_stara]

set_property PACKAGE_PIN D16 [get_ports sync_gpio_in]

set_property PACKAGE_PIN H17 [get_ports pxie_atnled_r]

set_property PACKAGE_PIN B22 [get_ports {sense_sel[1]}]
set_property PACKAGE_PIN A18 [get_ports {sense_sel[0]}]

set_property PACKAGE_PIN F18 [get_ports spi_sdio]

set_property PACKAGE_PIN B18 [get_ports pol_sense]

set_property PACKAGE_PIN A8 [get_ports {adc1_d_p[3]}]
set_property PACKAGE_PIN A7 [get_ports {adc1_d_n[3]}]
set_property PACKAGE_PIN B6 [get_ports {adc1_d_p[2]}]
set_property PACKAGE_PIN B5 [get_ports {adc1_d_n[2]}]
set_property PACKAGE_PIN D6 [get_ports {adc1_d_p[1]}]
set_property PACKAGE_PIN D5 [get_ports {adc1_d_n[1]}]
set_property PACKAGE_PIN E4 [get_ports {adc1_d_p[0]}]
set_property PACKAGE_PIN E3 [get_ports {adc1_d_n[0]}]
set_property PACKAGE_PIN F6 [get_ports {adc2_d_p[3]}]
set_property PACKAGE_PIN F5 [get_ports {adc2_d_n[3]}]
set_property PACKAGE_PIN G4 [get_ports {adc2_d_p[2]}]
set_property PACKAGE_PIN G3 [get_ports {adc2_d_n[2]}]
set_property PACKAGE_PIN H6 [get_ports {adc2_d_p[1]}]
set_property PACKAGE_PIN H5 [get_ports {adc2_d_n[1]}]
set_property PACKAGE_PIN K6 [get_ports {adc2_d_p[0]}]
set_property PACKAGE_PIN K5 [get_ports {adc2_d_n[0]}]

set_property PACKAGE_PIN F21 [get_ports trig_out_en_n]

set_property PACKAGE_PIN G18 [get_ports spi_sclk]
set_property PACKAGE_PIN E21 [get_ports trig_out]

set_property PACKAGE_PIN AD9 [get_ports trigout_od1_io]
set_property PACKAGE_PIN AE9 [get_ports trigout_od2_io]

set_property PACKAGE_PIN J18 [get_ports param_sck]

set_property PACKAGE_PIN K18 [get_ports param_cs_n]

set_property PACKAGE_PIN H20 [get_ports param_si]
set_property PACKAGE_PIN G20 [get_ports param_so]
set_property PACKAGE_PIN D17 [get_ports xo_vcsel]

set_property PACKAGE_PIN D26 [get_ports fpga_sysref_p]
set_property PACKAGE_PIN C26 [get_ports fpga_sysref_n]

set_property PACKAGE_PIN E19 [get_ports pxie_refsel]

set_property PACKAGE_PIN D19 [get_ports pll_sync]

set_property PACKAGE_PIN D18 [get_ports pll2_clksel]

set_property PACKAGE_PIN C24 [get_ports {gpio_p[7]}]
set_property PACKAGE_PIN B24 [get_ports {gpio_n[7]}]
set_property PACKAGE_PIN G23 [get_ports {gpio_p[6]}]
set_property PACKAGE_PIN G24 [get_ports {gpio_n[6]}]
set_property PACKAGE_PIN B30 [get_ports {gpio_p[5]}]
set_property PACKAGE_PIN A30 [get_ports {gpio_n[5]}]
set_property PACKAGE_PIN F26 [get_ports {gpio_p[4]}]
set_property PACKAGE_PIN E26 [get_ports {gpio_n[4]}]
set_property PACKAGE_PIN E24 [get_ports {gpio_p[3]}]
set_property PACKAGE_PIN D24 [get_ports {gpio_n[3]}]
set_property PACKAGE_PIN F25 [get_ports {gpio_p[2]}]
set_property PACKAGE_PIN E25 [get_ports {gpio_n[2]}]
set_property PACKAGE_PIN E28 [get_ports {gpio_p[1]}]
set_property PACKAGE_PIN D28 [get_ports {gpio_n[1]}]
set_property PACKAGE_PIN A25 [get_ports {gpio_p[0]}]
set_property PACKAGE_PIN A26 [get_ports {gpio_n[0]}]

set_property PACKAGE_PIN C25 [get_ports fpga_glblclk_p]
set_property PACKAGE_PIN B25 [get_ports fpga_glblclk_n]

set_property PACKAGE_PIN C29 [get_ports {exttrig_p[2]}]
set_property PACKAGE_PIN D29 [get_ports {exttrig_p[3]}]
set_property PACKAGE_PIN B29 [get_ports {exttrig_n[2]}]
set_property PACKAGE_PIN C30 [get_ports {exttrig_n[3]}]
set_property PACKAGE_PIN A27 [get_ports {exttrig_n[0]}]
set_property PACKAGE_PIN A28 [get_ports {exttrig_n[1]}]
set_property PACKAGE_PIN B27 [get_ports {exttrig_p[0]}]
set_property PACKAGE_PIN B28 [get_ports {exttrig_p[1]}]

set_property PACKAGE_PIN H19 [get_ports clkrefout_en_n]

set_property PACKAGE_PIN T23 [get_ports m2_ddr3_osc_dis]

#set_property PACKAGE_PIN U19 [get_ports conf_cs_n]
#set_property PACKAGE_PIN R21 [get_ports {conf_d[3]}]
#set_property PACKAGE_PIN R20 [get_ports {conf_d[2]}]
#set_property PACKAGE_PIN R25 [get_ports {conf_d[1]}]
#set_property PACKAGE_PIN P24 [get_ports {conf_d[0]}]

set_property PACKAGE_PIN AF21 [get_ports atnsw_fpga_n]

# Moved to adq14_pcie_pinmap.xcd due to ethernet
#set_property PACKAGE_PIN R7 [get_ports mgtrefclk_n]
#set_property PACKAGE_PIN R8 [get_ports mgtrefclk_p]

set_property PACKAGE_PIN AG22 [get_ports pxi_trig0_dir]
set_property PACKAGE_PIN AF22 [get_ports pxi_trig1_dir]

set_property PACKAGE_PIN AG23 [get_ports pxie_alert]
set_property PACKAGE_PIN AE23 [get_ports {pxie_ga[0]}]
set_property PACKAGE_PIN AG24 [get_ports {pxie_ga[1]}]
set_property PACKAGE_PIN AK25 [get_ports {pxie_ga[2]}]
set_property PACKAGE_PIN AH24 [get_ports {pxie_ga[3]}]
set_property PACKAGE_PIN AD21 [get_ports {pxie_ga[4]}]

set_property PACKAGE_PIN AG20 [get_ports pxie_smbrdy]

set_property PACKAGE_PIN F27 [get_ports {pxie_starb_n[0]}]
set_property PACKAGE_PIN F28 [get_ports {pxie_starb_n[1]}]
set_property PACKAGE_PIN G28 [get_ports {pxie_starb_p[1]}]
set_property PACKAGE_PIN G27 [get_ports {pxie_starb_p[0]}]

set_property PACKAGE_PIN H25 [get_ports pxie_starc_n]
set_property PACKAGE_PIN H24 [get_ports pxie_starc_p]

# Since GTX are placed in pcie_x8_gen2-PCIE_X0Y0.xdc we should not place pins.
#set_property PACKAGE_PIN AA3 [get_ports {rx_n[0]}]
#set_property PACKAGE_PIN AA4 [get_ports {rx_p[0]}]
#set_property PACKAGE_PIN Y5 [get_ports {rx_n[1]}]
#set_property PACKAGE_PIN Y6 [get_ports {rx_p[1]}]
#set_property PACKAGE_PIN W3 [get_ports {rx_n[2]}]
#set_property PACKAGE_PIN W4 [get_ports {rx_p[2]}]
#set_property PACKAGE_PIN V5 [get_ports {rx_n[3]}]
#set_property PACKAGE_PIN V6 [get_ports {rx_p[3]}]
#set_property PACKAGE_PIN T5 [get_ports {rx_n[4]}]
#set_property PACKAGE_PIN T6 [get_ports {rx_p[4]}]
#set_property PACKAGE_PIN R3 [get_ports {rx_n[5]}]
#set_property PACKAGE_PIN R4 [get_ports {rx_p[5]}]
#set_property PACKAGE_PIN P5 [get_ports {rx_n[6]}]
#set_property PACKAGE_PIN P6 [get_ports {rx_p[6]}]
#set_property PACKAGE_PIN M5 [get_ports {rx_n[7]}]
#set_property PACKAGE_PIN M6 [get_ports {rx_p[7]}]

#set_property PACKAGE_PIN Y1 [get_ports {tx_n[0]}]
#set_property PACKAGE_PIN Y2 [get_ports {tx_p[0]}]
#set_property PACKAGE_PIN V1 [get_ports {tx_n[1]}]
#set_property PACKAGE_PIN V2 [get_ports {tx_p[1]}]
#set_property PACKAGE_PIN U3 [get_ports {tx_n[2]}]
#set_property PACKAGE_PIN U4 [get_ports {tx_p[2]}]
#set_property PACKAGE_PIN T1 [get_ports {tx_n[3]}]
#set_property PACKAGE_PIN T2 [get_ports {tx_p[3]}]
#set_property PACKAGE_PIN P1 [get_ports {tx_n[4]}]
#set_property PACKAGE_PIN P2 [get_ports {tx_p[4]}]
#set_property PACKAGE_PIN N3 [get_ports {tx_n[5]}]
#set_property PACKAGE_PIN N4 [get_ports {tx_p[5]}]
#set_property PACKAGE_PIN M1 [get_ports {tx_n[6]}]
#set_property PACKAGE_PIN M2 [get_ports {tx_p[6]}]
#set_property PACKAGE_PIN L3 [get_ports {tx_n[7]}]
#set_property PACKAGE_PIN L4 [get_ports {tx_p[7]}]

set_property PACKAGE_PIN AJ12 [get_ports m1_ddr3_osc_dis]

set_property PACKAGE_PIN AK23 [get_ports f2u_rxd]

set_property PACKAGE_PIN E13 [get_ports gpio_scl]
set_property PACKAGE_PIN C12 [get_ports gpio_sda]

set_property PACKAGE_PIN AH22 [get_ports pxi_trig0]
set_property PACKAGE_PIN AJ22 [get_ports pxi_trig1]
set_property PACKAGE_PIN AE21 [get_ports pxie_smbc]
set_property PACKAGE_PIN AF20 [get_ports pxie_smbd]

set_property PACKAGE_PIN AK24 [get_ports u2f_txd]

set_property PACKAGE_PIN K19 [get_ports adc2_pdwn]

set_property PACKAGE_PIN B23 [get_ports adc2_sync_n]
set_property PACKAGE_PIN A23 [get_ports adc2_sync_p]

set_property PACKAGE_PIN K20 [get_ports adc1_pdwn]

set_property PACKAGE_PIN E30 [get_ports adc1_sync_n]
set_property PACKAGE_PIN E29 [get_ports adc1_sync_p]
set_property PACKAGE_PIN E18 [get_ports fan_fault_n]

set_property PACKAGE_PIN E20 [get_ports sync_out]

set_property PACKAGE_PIN F20 [get_ports sync_out_en_n]

set_property PACKAGE_PIN C8 [get_ports fpga_gtxref_ac_p]
set_property PACKAGE_PIN C7 [get_ports fpga_gtxref_ac_n]

set_property PACKAGE_PIN J19 [get_ports clkbufout_en_n]

set_property PACKAGE_PIN D21 [get_ports led_pwr]
set_property PACKAGE_PIN H21 [get_ports led_rdy]

set_property PACKAGE_PIN H22 [get_ports led_stat]

set_property PACKAGE_PIN A11 [get_ports {gpioctrl_r[4]}]
set_property PACKAGE_PIN A12 [get_ports {gpioctrl_r[3]}]
set_property PACKAGE_PIN B13 [get_ports {gpioctrl_r[2]}]
set_property PACKAGE_PIN A13 [get_ports {gpioctrl_r[1]}]
set_property PACKAGE_PIN A15 [get_ports {gpioctrl_r[0]}]

set_property PACKAGE_PIN Y23 [get_ports dcdcsync_ltm4633]
set_property PACKAGE_PIN Y24 [get_ports dcdcsync_ltm4644]

set_property PACKAGE_PIN AC20 [get_ports dcdcsync_sync_neg]

set_property PACKAGE_PIN J17 [get_ports secee_1wire]

set_property PACKAGE_PIN AB24 [get_ports {vsel[0]}]
set_property PACKAGE_PIN AC25 [get_ports {vsel[1]}]
set_property PACKAGE_PIN AC21 [get_ports {vsel[2]}]
set_property PACKAGE_PIN AD22 [get_ports {vsel[3]}]
set_property PACKAGE_PIN AC24 [get_ports {vsel[4]}]
set_property PACKAGE_PIN AD24 [get_ports {vsel[5]}]

set_property PACKAGE_PIN E16 [get_ports clk10m_fpga]

#set_property PACKAGE_PIN R24 [get_ports emcclk]

set_property PACKAGE_PIN A22 [get_ports emcosc_en]

set_property PACKAGE_PIN AH21 [get_ports pxie_perst]

set_property PACKAGE_PIN G22 [get_ports pxie_100m_en]
set_property PACKAGE_PIN F22 [get_ports pxie_10m_en]
set_property PACKAGE_PIN D22 [get_ports pxie_sync_en]
