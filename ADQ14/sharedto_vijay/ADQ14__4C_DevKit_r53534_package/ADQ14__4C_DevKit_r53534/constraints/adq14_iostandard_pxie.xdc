# -*- coding: us-ascii-dos -*-
# 
# Copyright Signal Processing Devices Sweden AB. All rights reserved.
# See document "08-0175 EULA" for specific license terms regarding this file.
# 
# Description   : ADQ14 I/O constraints file, PXIe specific
# Documentation :
# 
# 

set_property IOSTANDARD LVCMOS33 [get_ports {pxie_ga[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pxie_ga[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pxie_ga[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pxie_ga[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pxie_ga[0]}]
set_property PULLUP TRUE [get_ports {pxie_ga[4]}]
set_property PULLUP TRUE [get_ports {pxie_ga[3]}]
set_property PULLUP TRUE [get_ports {pxie_ga[2]}]
set_property PULLUP TRUE [get_ports {pxie_ga[1]}]
set_property PULLUP TRUE [get_ports {pxie_ga[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports pxie_smbd]
set_property PULLUP TRUE [get_ports pxie_smbd]
set_property DRIVE 4 [get_ports pxie_smbd]
set_property SLEW SLOW [get_ports pxie_smbd]
set_property IOSTANDARD LVCMOS33 [get_ports pxie_smbc]
set_property PULLUP TRUE [get_ports pxie_smbc]
set_property IOSTANDARD LVCMOS33 [get_ports pxie_smbrdy]
set_property PULLUP TRUE [get_ports pxie_smbrdy]
set_property IOSTANDARD LVCMOS33 [get_ports pxie_alert]
set_property IOSTANDARD LVCMOS33 [get_ports pxi_trig0]
set_property PULLUP TRUE [get_ports pxi_trig0]
set_property IOSTANDARD LVCMOS33 [get_ports pxi_trig1]
set_property PULLUP TRUE [get_ports pxi_trig1]
set_property IOSTANDARD LVCMOS33 [get_ports pxi_trig0_dir]
set_property DRIVE 4 [get_ports pxi_trig0_dir]
set_property SLEW SLOW [get_ports pxi_trig0_dir]
set_property IOSTANDARD LVCMOS33 [get_ports pxi_trig1_dir]
set_property DRIVE 4 [get_ports pxi_trig1_dir]
set_property SLEW SLOW [get_ports pxi_trig1_dir]
set_property IOSTANDARD LVCMOS33 [get_ports pxie_stara]
set_property PULLUP TRUE [get_ports pxie_stara]
set_property IOSTANDARD LVDS_25 [get_ports pxie_starc_p]
set_property IOSTANDARD LVDS_25 [get_ports pxie_starc_n]

set_property IOSTANDARD LVCMOS33 [get_ports pxie_100m_en]
set_property IOSTANDARD LVCMOS33 [get_ports pxie_10m_en]
set_property IOSTANDARD LVCMOS33 [get_ports pxie_sync_en]
