# -*- coding: us-ascii-dos -*-
#
# Copyright Signal Processing Devices Sweden AB. All rights reserved.
# See document "08-0175 EULA" for specific license terms regarding this file.
#
# Description   : Development kit project setup functions
# Documentation :
#
#

proc devkit_set_top_ul {inst} {
  set project_found [llength [get_projects DevKit] ]
  if {$project_found > 0} {
    set_property -quiet is_enabled false [get_files user_logic${inst}.edf]
    set_property constrset constrs_ul_${inst} [get_runs synth_1]

    set_property top user_logic${inst} [current_fileset]
    set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value -no_iobuf -objects [get_runs synth_1]
  } else {
    puts "No Projects Found!"
  }
}

proc devkit_set_top {} {
  set project_found [llength [get_projects DevKit] ]
  if {$project_found > 0} {
    set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {} -objects [get_runs synth_1]
    set_property top top_adq14 [current_fileset]
    set_property constrset constrs_1 [get_runs synth_1]
    set_property constrset constrs_1 [get_runs impl_1]
    add_files -norecurse -quiet user_logic1.edf
    add_files -norecurse -quiet user_logic2.edf
    set_property is_enabled true [get_files user_logic1.edf]
    set_property is_enabled true [get_files user_logic2.edf]
  } else {
    puts "No Projects Found!"
  }
}

proc devkit_synth_ul {inst} {
  set project_found [llength [get_projects DevKit] ]
  if {$project_found > 0} {
    devkit_set_top_ul ${inst}

    reset_run synth_1
    launch_runs synth_1
    wait_on_run synth_1
    open_run -quiet synth_1
    write_edif -force -security_mode all user_logic${inst}
    close_design

    set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {} -objects [get_runs synth_1]
    set_property top top_adq14 [current_fileset]
    set_property constrset constrs_1 [get_runs synth_1]
    set_property constrset constrs_1 [get_runs impl_1]
    add_files -norecurse -quiet user_logic${inst}.edf
    set_property is_enabled true [get_files user_logic${inst}.edf]
  } else {
    puts "No Projects Found!"
  }
}

proc devkit_setup {} {
    set project_part "xc7k325tffg900-2"
    create_project -part $project_part -force DevKit
    create_fileset -constrset constrs_ul_1
    create_fileset -constrset constrs_ul_2

    # Fix for incorect bmm info netlist (2014.4 and 2015.1)
    set_msg_config -id {Memdata 28-84} -new_severity INFO

    # Fix for incorect Hardware Handoff file message (2015.1)
    set_msg_config -id {Pfi 67-14} -new_severity INFO

    #Add source files
    foreach e [glob ../source/*.v] {
      puts $e
      add_files -norecurse $e
    }

    #Add netlists
    foreach e [glob ../edif/*.edf] {
      puts $e
      add_files -norecurse $e
    }

    # Add constraints (ddr3 must be added first)
    add_files -fileset constrs_1 -norecurse ../constraints/ddr3.xdc

    # Import IPs
    import_ip [glob ../ip/*/*.xci]

    if { [file exists ../ip/pcie_x8_gen2/pcie_x8_gen2.xci ] } {
      #Add PCIE IP
      if {[expr {[version -short] >= 2017}]} {
        upgrade_ip -vlnv xilinx.com:ip:pcie_7x:* [get_ips pcie_x8_gen2] -log ipcie_ip_upgrade.log
      }
      generate_target all [get_files pcie_x8_gen2.xci]
      set_property is_enabled false [get_files *ip/pcie_x8_gen2/source/pcie_x8_gen2-PCIE_X0Y0.xdc]

      add_files -fileset constrs_1 -norecurse ../constraints/pcie_x8_gen2-PCIE_X0Y0.xdc
      add_files -fileset constrs_1 -norecurse ../constraints/pcie_x8g2.xdc
      add_files -fileset constrs_1 -norecurse ../constraints/adq14_pcie_pinmap.xdc
      add_files -fileset constrs_1 -norecurse ../constraints/adq14_pcie.xdc
    }

    if { [file exists ../ip/ethernet_xaui/ethernet_xaui.xci] } {
      generate_target all [get_files ethernet_xaui.xci]
      add_files -fileset constrs_1 -norecurse ../constraints/adq14_ethernet.xdc
      add_files -fileset constrs_1 -norecurse ../constraints/adq14_ethernet_pinmap.xdc
      add_files -fileset constrs_1 -norecurse ../constraints/ethernet_xaui.xdc
    }

    if { [file exists ../ip/eth_buffer/fifo_128to64_x512.xci ] } {
      generate_target all [get_files fifo_128to64_x512.xci]
    }

    #Add constraints
    add_files -fileset constrs_1 -norecurse ../constraints/adq14_iostandard.xdc
    add_files -fileset constrs_1 -norecurse ../constraints/adq14_pinmap.xdc
    add_files -fileset constrs_1 -norecurse ../constraints/adq14_iostandard_pxie.xdc
    add_files -fileset constrs_1 -norecurse ../constraints/rook_ul2.xdc

    #build user logic
    devkit_synth_ul 1
    devkit_synth_ul 2

    # Set compile order
    set_property source_mgmt_mode DisplayOnly [current_project]
    reorder_files -before [get_files System_wrapper.edf] [get_files user_logic1.edf]
    reorder_files -before [get_files System_wrapper.edf] [get_files user_logic2.edf]

    # Set Verilog defines
    set_property verilog_define PCIE_128 [current_fileset]

    if { [file exists ../ip/ethernet_xaui/ethernet_xaui.xci] } {
      # Assume ethernet if ethernet_xaui.xci exists
      set_property verilog_define {ENABLE_ETH PCIE_128} [current_fileset]
    }

    # Add write bitstream pre-hook
    set_property STEPS.WRITE_BITSTREAM.TCL.PRE [file normalize "./scripts/devkit_bitstream_pre_hook.tcl"] [get_runs impl_1]

}

proc devkit_mcs {} {
  set project_found [llength [get_projects DevKit] ]
  if {$project_found > 0} {
    puts "Creating mcs file..."
    file copy -force ./DevKit.runs/impl_1/top_adq14.bit ./adq14.bit
    write_cfgmem -force -format MCS -size 32 -interface SPIx4 -loadbit "up 0x00000000 adq14.bit" adq14.mcs
    set CurrentTime [clock format [clock seconds] -format {%Y%m%d_%H%M}]
    set LogDir "logfiles/run_${CurrentTime}_ADQ14_[current_project]"
    file mkdir $LogDir
    set ResultFiles [list\
                         [format adq14.bit] \
                         [format adq14.mcs]]

    puts "Copying files to directory: $LogDir."
    foreach fileItem $ResultFiles {
        if { [ file exists $fileItem ] } {
            file copy -force $fileItem $LogDir
        } else {
            puts [format "** ERROR! ** \
                         Copy failed, ${fileItem} missing"]
        }
    }
    puts "Done!"
  } else {
    puts "No Projects Found!"
  }

}

proc devkit_reverse_lanes {} {
  set project_found [llength [get_projects DevKit] ]
  if {$project_found > 0} {
    update_files -from_files ../constraints/pcie_x8_gen2-PCIE_X0Y0_rev_lane.xdc -to_files ../constraints/pcie_x8_gen2-PCIE_X0Y0.xdc -filesets [get_filesets *]
    puts "Done."
  } else {
    puts "No Project Found!"
  }
}

proc devkit_ul2_example1 {} {
  #Make a list of the files that needs to be in the same directory as the user_logic2.v
  set ParamFiles [list\
                       [format bus_splitter_rr.vh] \
                       [format bus_splitter_rr_param.vh] \
                       [format bus_splitter_rt.vh] \
                       [format bus_splitter_rt_param.vh] \
                       [format device_param.vh] \
                       [format device_param_top.vh] \
                       [format user_logic2_defines.vh]]
  set ul2_example_dir "../ul2_examples/simple_streaming_acqusition/"
  foreach fileItem $ParamFiles {
      if { [ file exists ../source/${fileItem} ] } {
          file copy -force "../source/${fileItem}" $ul2_example_dir
      } else {
          puts [format "** ERROR! ** \
                       Copy failed, ../source/${fileItem} missing"]
      }
  }

  #Remove the standard module from the project and add the example module
  remove_files user_logic2.v
  add_files -norecurse ../ul2_examples/simple_streaming_acqusition/user_logic2.v
}

proc devkit_build {} {
  devkit_synth_ul 1
  devkit_synth_ul 2
  reset_run synth_1
  launch_runs impl_1 -to_step write_bitstream
  wait_on_run impl_1
  open_run impl_1
  devkit_mcs
}


puts "\n\n\n\n\n\n"
puts "*** ADQ14 Development Kit ***";
puts "Usage:";
puts "  devkit_setup         - Create project";
puts "  devkit_build         - Build project";
puts "  devkit_synth_ul 1    - Generate netlist for User_Logic1";
puts "  devkit_synth_ul 2    - Generate netlist for User_Logic2";
puts "  devkit_mcs           - Generate .mcs firmware file";
puts "  devkit_ul2_example1  - Load a User_Logic2 example module";
puts "  devkit_reverse_lanes - Reverse PCIe lane order"

#auto build project
if {[info exists auto_build]} {
  if {$auto_build==1} {
    puts {Building devkit...}
    devkit_setup
    devkit_build
  }
}
